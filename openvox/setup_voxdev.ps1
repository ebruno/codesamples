# setup_voxdev.ps1
# OpenVox dev environment (PowerShell version)
#
# Usage:
#   ./setup_voxdev.ps1 -p virtualbox          # Full setup
#   ./setup_voxdev.ps1 -s                      # Show VM status
#   ./setup_voxdev.ps1 -d -p virtualbox        # Destroy VMs
#   ./setup_voxdev.ps1 -q -p virtualbox        # Quick run (skip provisioning)
#
# Windows workarounds preserved:
#   - Strip drive letter from temp path for vagrant scp
#   - Longer wait times on Windows

$ErrorActionPreference = "Continue"

# ── Helpers ───────────────────────────────────────────────────────────────

$TMP_FILES = @()

function Write-Info  { Write-Host "[INFO]  $args" -ForegroundColor Yellow }
function Write-Warn  { Write-Host "[WARN]  $args" -ForegroundColor Yellow }
function Write-ErrorMsg { Write-Host "[ERROR] $args" -ForegroundColor Red }

function New-TempFile {
    $f = [System.IO.Path]::GetTempFileName()
    $script:TMP_FILES += $f
    return $f
}

function Remove-TempFiles {
    foreach ($f in $script:TMP_FILES) {
        if (Test-Path $f) { Remove-Item -Force $f -ErrorAction SilentlyContinue }
    }
}

# ── Configuration ─────────────────────────────────────────────────────────

$VOX_SERVER_NAME = "vox_server"
$VOX_SERVER_HOST_NAME = "vox-server"
$VOX_CLIENT_NAME = "vox_client"
$VOX_CLIENT_HOST_NAME = "vox-client"

# Longer wait times on Windows (VirtualBox is slower)
if ($IsWindows) {
    $WAIT_TIME = 45
    $WAIT_TIME_CLIENT = 45
} else {
    $WAIT_TIME = 30
    $WAIT_TIME_CLIENT = 30
}

$VALID_PROVIDERS = @("virtualbox", "vmware_fusion", "vmware_desktop", "libvirt")

# ── Argument parsing ──────────────────────────────────────────────────────

$PROVIDER = "virtualbox"
$DO_STATUS = $false
$DO_DESTROY = $false
$DO_QUICK = $false

function Show-Help {
    Write-Host "Usage: setup_voxdev.ps1 [options]"
    Write-Host ""
    Write-Host "  -h            Display this message"
    Write-Host "  -p provider   Provider: virtualbox, vmware_fusion, vmware_desktop, libvirt"
    Write-Host "  -s            Show VM status and exit"
    Write-Host "  -d            Destroy all VMs and exit"
    Write-Host "  -q            Quick run — skip provisioning (VMs must already be up)"
    exit 0
}

for ($i = 0; $i -lt $args.Count; $i++) {
    switch ($args[$i]) {
        "-h" { Show-Help }
        "-p" {
            if ($i + 1 -lt $args.Count -and -not ($args[$i + 1] -match "^-")) {
                $PROVIDER = $args[$i + 1]
                $i++
            } else {
                Write-ErrorMsg "Option -p requires an argument."
                exit 1
            }
        }
        "-s" { $DO_STATUS = $true }
        "-d" { $DO_DESTROY = $true }
        "-q" { $DO_QUICK = $true }
        default {
            if ($args[$i] -match "^-") {
                Write-ErrorMsg "Invalid option: $($args[$i])"
                exit 1
            }
        }
    }
}

# ── Validate prerequisites ─────────────────────────────────────────────────

$vagrantCmd = Get-Command vagrant -ErrorAction SilentlyContinue
if (-not $vagrantCmd) {
    Write-ErrorMsg "vagrant command not found."
    exit 1
}
$VAGRANT = $vagrantCmd.Source

if ($VALID_PROVIDERS -notcontains $PROVIDER) {
    Write-ErrorMsg "Provider '$PROVIDER' is not valid/supported."
    exit 1
}

$env:VAGRANT_DEFAULT_PROVIDER = $PROVIDER

# ── Change to correct Vagrantfile directory ───────────────────────────────

$origLocation = Get-Location
if ($PROVIDER -eq "libvirt") {
    if (Test-Path libvirt) {
        Write-Info "Switching to libvirt Vagrantfile directory..."
        Set-Location libvirt
    } else {
        Write-ErrorMsg "libvirt/ directory not found."
        exit 1
    }
}

# ── --status: show VM state and exit ──────────────────────────────────────

if ($DO_STATUS) {
    Write-Info "VM status:"
    & $VAGRANT status
    Set-Location $origLocation
    Remove-TempFiles
    exit 0
}

# ── --destroy: tear down VMs and exit ─────────────────────────────────────

if ($DO_DESTROY) {
    Write-Info "Destroying all VMs..."
    & $VAGRANT destroy -f
    if ($LASTEXITCODE -ne 0) { Write-ErrorMsg "Destroy failed."; exit 1 }
    Write-Info "VMs destroyed."
    Set-Location $origLocation
    Remove-TempFiles
    exit 0
}

# ── Pre-flight checks ─────────────────────────────────────────────────────

Write-Info "Using provider: $PROVIDER"
Write-Info "Running pre-flight checks..."

function Check-Plugin {
    param([string]$plugin)
    $plist = & $VAGRANT plugin list 2>&1
    if ($plist -notmatch $plugin) {
        Write-ErrorMsg "Required Vagrant plugin not installed: $plugin"
        Write-ErrorMsg "Install with: vagrant plugin install $plugin"
        exit 1
    }
}

Check-Plugin vagrant-scp
Check-Plugin vagrant-group

switch ($PROVIDER) {
    "virtualbox" {
        if (-not (Get-Command VBoxManage -ErrorAction SilentlyContinue)) {
            Write-ErrorMsg "VirtualBox not found. Install from https://www.virtualbox.org/"
            exit 1
        }
        $nets = VBoxManage list hostonlynets 2>&1
        if ($nets -match "OpenVox0") {
            Write-Info "  Host-only network 'OpenVox0' found."
        } else {
            Write-Warn "  Host-only network 'OpenVox0' not found in VirtualBox."
            Write-Warn "  Create it: VirtualBox -> File -> Host Network Manager -> Create"
            Write-Warn "  Name it 'OpenVox0' with DHCP enabled."
        }
    }
    { $_ -in @("vmware_fusion", "vmware_desktop") } {
        Check-Plugin vagrant-vmware-desktop
        if (-not (Get-Command vmrun -ErrorAction SilentlyContinue)) {
            Write-ErrorMsg "VMware Fusion not found."
            exit 1
        }
    }
    "libvirt" {
        Check-Plugin vagrant-libvirt
        if (-not (Get-Command virsh -ErrorAction SilentlyContinue)) {
            Write-ErrorMsg "libvirt not found."
            exit 1
        }
    }
}

Write-Info "Pre-flight checks passed."

# ── Track elapsed time ────────────────────────────────────────────────────

$startTime = Get-Date

# ── Bring up VMs (skip if --quick) ────────────────────────────────────────

if ($DO_QUICK) {
    Write-Info "Quick mode — skipping provisioning. VMs must already be running."
} else {
    Write-Info "Bringing up VMs via 'vagrant group up voxdevelopment'..."
    $result = & $VAGRANT group up voxdevelopment 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-ErrorMsg "Failed to bring up VMs. Check 'vagrant status' for details."
        Set-Location $origLocation
        Remove-TempFiles
        exit 1
    }
}

# ── Discover private network IPs dynamically ───────────────────────────────

function Get-PrivateIp {
    param([string]$vmName)

    $tmp = New-TempFile
    @'
#!/usr/bin/env bash
# Find the default-route interface (the one after "dev")
default_iface=""
while read -r _ _ _ _ iface _; do default_iface="$iface"; break; done < <(ip -4 route show default)
echo "DEFAULT:$default_iface"
# Find first non-lo, non-default interface with an IPv4 address
ip -4 -o addr show | while read -r _ iface _ addr _; do
  [[ "$iface" == "lo" ]] && continue
  [[ "$iface" == "$default_iface" ]] && continue
  echo "IP:${addr%/*}"
  break
done
'@ | Out-File -FilePath $tmp -Encoding ASCII -NoNewline

    # Vagrant scp on Windows treats drive letters as machine names
    $scpPath = if ($IsWindows) { $tmp -replace '^\w:', '' } else { $tmp }

    & $VAGRANT scp $scpPath "${vmName}:./_get_ip.sh" 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-ErrorMsg "scp to $vmName failed"
        exit 1
    }

    $output = & $VAGRANT ssh $vmName -c "bash ./_get_ip.sh" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-ErrorMsg "Failed to run IP detection on $vmName"
        exit 1
    }
    & $VAGRANT ssh $vmName -c "rm -f ./_get_ip.sh" 2>&1 | Out-Null

    $outputStr = $output -join "`n"

    if ($outputStr -match 'DEFAULT:([^\s]+)') {
        $default_iface = $matches[1]
    } else {
        Write-ErrorMsg "Failed to determine default-route interface on $vmName"
        exit 1
    }

    Write-Info "  $vmName default-route interface: $default_iface"

    if ($outputStr -match 'IP:([0-9.]+)') {
        $ip = $matches[1]
    } else {
        Write-ErrorMsg "No private-interface IP found on $vmName (only default route and lo detected)"
        exit 1
    }

    return $ip
}

$VOX_SERVER_IP = Get-PrivateIp $VOX_SERVER_NAME
$VOX_CLIENT_IP = Get-PrivateIp $VOX_CLIENT_NAME

Write-Info "vox server private IP: $VOX_SERVER_IP"
Write-Info "vox client private IP: $VOX_CLIENT_IP"

# ── Configure /etc/hosts on both VMs ──────────────────────────────────────

function Write-HostsScript {
    param([string]$outputPath, [string]$content)

    $header = "#!/usr/bin/env bash`ncat >> /etc/hosts <<HOSTS`n"
    $footer = "`nHOSTS`n"
    # Write without PowerShell adding/removing newlines — use .NET directly
    $fullContent = $header + $content + $footer
    [System.IO.File]::WriteAllText($outputPath, $fullContent, [System.Text.Encoding]::ASCII)
}

function Copy-And-Run {
    param([string]$vmName, [string]$scriptPath, [string]$description)

    $scpPath = if ($IsWindows) { $scriptPath -replace '^\w:', '' } else { $scriptPath }

    Write-Info "Uploading $description to ${vmName}..."
    & $VAGRANT scp $scpPath "${vmName}:./configure_hosts.sh" 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-ErrorMsg "scp to $vmName failed."
        exit 1
    }
    & $VAGRANT ssh $vmName -c "chmod a+x ./configure_hosts.sh" 2>&1 | Out-Null
    & $VAGRANT ssh $vmName -c "sudo ./configure_hosts.sh"
    if ($LASTEXITCODE -ne 0) {
        Write-ErrorMsg "Failed to configure $description on $vmName."
        exit 1
    }
}

# Server hosts
$serverTmp = New-TempFile
switch ($PROVIDER) {
    { $_ -in @("virtualbox", "libvirt") } {
        Write-HostsScript $serverTmp "$VOX_SERVER_IP puppet`n$VOX_CLIENT_IP $VOX_CLIENT_HOST_NAME"
    }
    "vmware_fusion" {
        Write-HostsScript $serverTmp "$VOX_SERVER_IP puppet`n$VOX_CLIENT_IP $VOX_CLIENT_HOST_NAME"
    }
    "vmware_desktop" {
        Write-HostsScript $serverTmp "$VOX_SERVER_IP puppet`n$VOX_CLIENT_IP $VOX_CLIENT_HOST_NAME"
    }
    default {
        Write-HostsScript $serverTmp "$VOX_SERVER_IP puppet`n$VOX_CLIENT_IP $VOX_CLIENT_HOST_NAME"
    }
}
Copy-And-Run $VOX_SERVER_NAME $serverTmp "hosts script"

# Client hosts
$clientTmp = New-TempFile
$VOX_SERVER_DOMAIN_NAME = $VOX_SERVER_HOST_NAME

switch ($PROVIDER) {
    { $_ -in @("virtualbox", "libvirt") } {
        Write-HostsScript $clientTmp "$VOX_SERVER_IP $VOX_SERVER_HOST_NAME puppet"
    }
    "vmware_fusion" {
        Write-HostsScript $clientTmp "$VOX_SERVER_IP $VOX_SERVER_HOST_NAME puppet ${VOX_SERVER_HOST_NAME}.localdomain"
        $VOX_SERVER_DOMAIN_NAME = "${VOX_SERVER_HOST_NAME}.localdomain"
    }
    "vmware_desktop" {
        Write-HostsScript $clientTmp "$VOX_SERVER_IP $VOX_SERVER_HOST_NAME puppet"
    }
    default {
        Write-HostsScript $clientTmp "$VOX_SERVER_IP $VOX_SERVER_HOST_NAME puppet"
    }
}
Copy-And-Run $VOX_CLIENT_NAME $clientTmp "hosts script"

Write-Info "Server domain name used by client: $VOX_SERVER_DOMAIN_NAME"

# ── Configure puppet agent ─────────────────────────────────────────────────

Write-Info "Configuring puppet agent to use server: ${VOX_SERVER_DOMAIN_NAME}..."
& $VAGRANT ssh $VOX_CLIENT_NAME -c "sudo puppet config set server ${VOX_SERVER_DOMAIN_NAME} --section agent"
if ($LASTEXITCODE -ne 0) {
    Write-ErrorMsg "Failed to configure puppet agent server setting."
    exit 1
}

Write-Info "Restarting puppet agent to trigger certificate request..."
& $VAGRANT ssh $VOX_CLIENT_NAME -c "sudo systemctl restart puppet"
if ($LASTEXITCODE -ne 0) {
    Write-ErrorMsg "Failed to restart puppet agent service."
    exit 1
}

# ── Wait for certificate request (polling, not fixed sleep) ────────────────

Write-Info "Waiting for client certificate request to appear on server..."
$waited = 0
$maxWait = $WAIT_TIME
$pollInterval = 5

while ($waited -lt $maxWait) {
    $certOutput = & $VAGRANT ssh $VOX_SERVER_NAME -c "sudo puppetserver ca list --all" 2>&1
    $certStr = $certOutput -join " "
    if ($certStr -match $VOX_CLIENT_HOST_NAME) {
        Write-Info "Certificate request detected after ${waited}s."
        break
    }
    Start-Sleep -Seconds $pollInterval
    $waited += $pollInterval
}

if ($waited -ge $maxWait) {
    Write-Warn "No certificate request from $VOX_CLIENT_HOST_NAME detected within ${maxWait}s."
    Write-Warn "Continuing anyway — you may need to sign manually."
}

Write-Info "Current certificate status:"
& $VAGRANT ssh $VOX_SERVER_NAME -c "sudo puppetserver ca list --all"

Write-Info "Signing all pending certificate requests..."
& $VAGRANT ssh $VOX_SERVER_NAME -c "sudo puppetserver ca sign --all"
if ($LASTEXITCODE -ne 0) {
    Write-Warn "Certificate signing returned non-zero (may have nothing to sign)."
}

# ── Wait for client to sync ────────────────────────────────────────────────

Write-Info "Waiting ${WAIT_TIME_CLIENT}s for client to sync with server..."
Start-Sleep -Seconds $WAIT_TIME_CLIENT

# ── Test puppet agent ─────────────────────────────────────────────────────

Write-Info "Running 'puppet agent --test' on client..."
# puppet agent exit codes: 0=no changes, 2=changes applied (both are success)
& $VAGRANT ssh $VOX_CLIENT_NAME -c "sudo puppet agent --test"
$agentRc = $LASTEXITCODE
if ($agentRc -ne 0 -and $agentRc -ne 2) {
    Write-ErrorMsg "Puppet agent test failed (exit code: $agentRc)."
    exit 1
}

# ── Verify manifest applied ───────────────────────────────────────────────

Write-Info "Verifying manifest was applied..."
& $VAGRANT ssh $VOX_CLIENT_NAME -c "which emacs && systemctl is-active systemd-timesyncd && cat /etc/motd"
if ($LASTEXITCODE -ne 0) {
    Write-ErrorMsg "Manifest verification failed."
    exit 1
}

# ── Done ──────────────────────────────────────────────────────────────────

$elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds)
$mins = [math]::Floor($elapsed / 60)
$secs = $elapsed % 60
Write-Info "The development environment is now ready to use. (elapsed: ${mins}m ${secs}s)"

# ── Cleanup ───────────────────────────────────────────────────────────────

Set-Location $origLocation
Remove-TempFiles

exit 0
