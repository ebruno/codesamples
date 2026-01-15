# setup_voxdev.ps1

$ErrorActionPreference = "Continue"

# Initialize exit status
[int]$exit_status = 0

# Detect OS type
$OS_TYPE = ""
$OS_VERSION = ""
$NAME_STRING = ""
# Note $IsMacOS and $IsLinux are availble for basic testing.
if (Test-Path "/usr/bin/sw_vers") {
    $OS_TYPE = & /usr/bin/sw_vers -productName
    $OS_VERSION = & /usr/bin/sw_vers -productVersion
    $NAME_STRING = "${OS_TYPE} ${OS_VERSION}"
}
elseif (Test-Path "/etc/os-release") {
    # Parse /etc/os-release file
    $osReleaseContent = Get-Content "/etc/os-release"
    $osRelease = @{}
    foreach ($line in $osReleaseContent) {
        if ($line -match '^([^=]+)=(.*)$') {
            $name = $matches[1]
            $value = $matches[2] -replace '^"|"$', ''
            $osRelease[$name] = $value
        }
    }
    $OS_TYPE = $osRelease["ID"]
    $NAME_STRING = $osRelease["PRETTY_NAME"]
}

# Use the provider environment variable
# group does not support the provider switch.
$env:VAGRANT_DEFAULT_PROVIDER = "virtualbox"

$VOX_SERVER_IP = ""
$VOX_SERVER_NAME = "vox_server"
$VOX_SERVER_HOST_NAME = "vox-server"
$VOX_CLIENT_NAME = "vox_client"
$VOX_CLIENT_HOST_NAME = "vox-client"

# These values may need to adjusted depending on the environment.
if ($IsWindows) {
  $WAIT_TIME = 45
  $WAIT_TIME_CLIENT=45
}
else {
  $WAIT_TIME = 30
  $WAIT_TIME_CLIENT=30
}
$valid_providers = @("virtualbox", "vmware_fusion", "vmware_desktop", "libvirt")

$vagrantCmd = Get-Command vagrant -ErrorAction SilentlyContinue
$VAGRANT = if ($vagrantCmd) { $vagrantCmd.Source } else { $null }

function Display-Help {
    Write-Host "setup_voxdev.ps1 [-h] [-p provider]"
    Write-Host "-h - display this message"
    Write-Host "-p - provider (virtualbox, vmware_fusion, vmware_desktop, libvirt)."
}

# Parse command line arguments
$VAGRANT_DEFAULT_PROVIDER = $env:VAGRANT_DEFAULT_PROVIDER

for ($i = 0; $i -lt $args.Count; $i++) {
    switch ($args[$i]) {
        "-h" {
            Display-Help
            $exit_status = 2
            break
        }
        "-p" {
            if ($i + 1 -lt $args.Count -and -not ($args[$i + 1] -match "^-")) {
                $VAGRANT_DEFAULT_PROVIDER = $args[$i + 1]
                $i++
            }
            else {
                Write-Error "Option -p requires an argument."
                $exit_status = 1
            }
            break
        }
        default {
            if ($args[$i] -match "^-") {
                Write-Error "Invalid option: $($args[$i])"
                $exit_status = 1
            }
        }
    }
}

if ($VAGRANT -and $exit_status -eq 0) {
    $provider_valid = 1
    
    if ($valid_providers -contains $VAGRANT_DEFAULT_PROVIDER) {
        Write-Host "[INFO] Using provider: ${VAGRANT_DEFAULT_PROVIDER}" -ForegroundColor Yellow
        $env:VAGRANT_DEFAULT_PROVIDER = $VAGRANT_DEFAULT_PROVIDER
        $provider_valid = 0
    }
    else {
        Write-Error "[ERROR] Provider: '$VAGRANT_DEFAULT_PROVIDER' is not valid/supported."
    }
    
    if ($VAGRANT_DEFAULT_PROVIDER -eq "libvirt") {
        Set-Location libvirt
    }
    
    if ($provider_valid -eq 0) {
        & $VAGRANT group up voxdevelopment
        
        $ipOutput = & $VAGRANT ssh $VOX_SERVER_NAME -- "ip -4 addr show eth1" 2>&1
        $ipLine = $ipOutput | Select-String "inet"
        if ($ipLine) {
            $ipParts = ($ipLine -split '\s+')[2]
            $VOX_SERVER_IP = ($ipParts -split '/')[0]
        }
        
        if ($VOX_SERVER_IP) {
            $clientIpOutput = & $VAGRANT ssh $VOX_CLIENT_NAME -- "ip -4 addr show eth1" 2>&1
            $clientIpLine = $clientIpOutput | Select-String "inet"
            if ($clientIpLine) {
                $clientIpParts = ($clientIpLine -split '\s+')[2]
                $VOX_CLIENT_IP = ($clientIpParts -split '/')[0]
            }
            
            Write-Host "[INFO] vox server host only ip address: ${VOX_SERVER_IP}" -ForegroundColor Yellow
            
            $tmp_file = [System.IO.Path]::GetTempFileName()
            
            switch ($VAGRANT_DEFAULT_PROVIDER) {
                { $_ -in @("virtualbox", "libvirt") } {
                    $bashContent = "#!/usr/bin/env bash`nprintf `"${VOX_SERVER_IP} puppet\n${VOX_CLIENT_IP} ${VOX_CLIENT_HOST_NAME}\n`" >> /etc/hosts`n`n"
                }
                "vmware_fusion" {
                    $bashContent = "#!/usr/bin/env bash`nprintf `"${VOX_SERVER_IP} puppet\n${VOX_CLIENT_IP} ${VOX_CLIENT_HOST_NAME}\n`" >> /etc/hosts`n`n"
                }
                default {
                    $bashContent = "#!/usr/bin/env bash`nprintf `"${VOX_SERVER_IP} puppet\n${VOX_CLIENT_IP} ${VOX_CLIENT_HOST_NAME}\n`" >> /etc/hosts`n`n"
                }
            }
            
            $bashContent | Out-File -FilePath $tmp_file -Encoding ASCII -NoNewline
	    # Strip any drive letters vagrant scp thinks it is a machine name.
	    if ($IsWindows) {
  	      $relativePath = $tmp_file -replace '^\w:',''
	    } else {
	      $relativePath = $tmp_file
	    }
            Write-Host "[INFO] Copy ${relativePath} to $VOX_SERVER_NAME" -ForegroundColor Yellow            
            & $VAGRANT scp "$relativePath" "${VOX_SERVER_NAME}:./configure_hosts.sh"
            Write-Host "[INFO] Add execute permissions $VOX_SERVER_NAME" -ForegroundColor Yellow            
            & $VAGRANT ssh $VOX_SERVER_NAME -c "chmod a+x ./configure_hosts.sh"
            & $VAGRANT ssh $VOX_SERVER_NAME -c "sudo ./configure_hosts.sh"
            Remove-Item -Force $tmp_file
            
            $tmp_file = [System.IO.Path]::GetTempFileName()
            
            # Configure Client
            $VOX_SERVER_DOMAIN_NAME = $VOX_SERVER_HOST_NAME
            
            # VMware Fusion and virtualbox handle internal DNS and hosts names differently.
            switch ($VAGRANT_DEFAULT_PROVIDER) {
                { $_ -in @("virtualbox", "libvirt") } {
                    $bashContent = "#!/usr/bin/env bash`nprintf `"${VOX_SERVER_IP} ${VOX_SERVER_HOST_NAME} puppet\n`" >> /etc/hosts`n`n"
                }
                "vmware_fusion" {
                    $bashContent = "#!/usr/bin/env bash`nprintf `"${VOX_SERVER_IP} ${VOX_SERVER_HOST_NAME} puppet ${VOX_SERVER_HOST_NAME}.localdomain\n`" >> /etc/hosts`n`n"
                    $VOX_SERVER_DOMAIN_NAME = "${VOX_SERVER_HOST_NAME}.localdomain"
                }
                default {
                    $bashContent = "#!/usr/bin/env bash`nprintf `"${VOX_SERVER_IP} ${VOX_SERVER_HOST_NAME} puppet\n`" >> /etc/hosts`n`n"
                }
            }
            
            $bashContent | Out-File -FilePath $tmp_file -Encoding ASCII -NoNewline
            
	    # Strip any drive letters vagrant scp thinks it is a machine name.
	    if ($IsWindows) {
  	      $relativePath = $tmp_file -replace '^\w:',''
	    } else {
	      $relativePath = $tmp_file
	    }
            Write-Host "[INFO] Copy ${relativePath} to $VOX_CLIENT_NAME" -ForegroundColor Yellow            
            & $VAGRANT scp "$relativePath" "${VOX_CLIENT_NAME}:./configure_hosts.sh"
            Write-Host "[INFO] Add execute permissions $VOX_SERVER_NAME" -ForegroundColor Yellow            
            & $VAGRANT ssh $VOX_CLIENT_NAME -c "chmod a+x ./configure_hosts.sh"
            & $VAGRANT ssh $VOX_CLIENT_NAME -c "sudo ./configure_hosts.sh"
            Remove-Item -Force $tmp_file
            
            & $VAGRANT ssh $VOX_CLIENT_NAME -c "sudo puppet config set server ${VOX_SERVER_DOMAIN_NAME} --section agent"
            
            # Restart the puppet agent service so that it requests a certificate.
            & $VAGRANT ssh $VOX_CLIENT_NAME -c "sudo systemctl restart puppet;"
            
            Write-Host "[INFO] Wait ${WAIT_TIME} seconds for client system to contact server." -ForegroundColor Yellow
            Start-Sleep -Seconds $WAIT_TIME
            
            Write-Host "[INFO] Checking Server for cert signing request." -ForegroundColor Yellow
            & $VAGRANT ssh $VOX_SERVER_NAME -c "sudo puppetserver ca list --all"
            & $VAGRANT ssh $VOX_SERVER_NAME -c "sudo puppetserver ca sign --all"
            
            Write-Host "[INFO] Wait ${WAIT_TIME_CLIENT} seconds for client system to sync with server." -ForegroundColor Yellow
            Start-Sleep -Seconds $WAIT_TIME_CLIENT
            
            & $VAGRANT ssh $VOX_CLIENT_NAME -c "sudo puppet agent --test"
            
            Write-Host "[INFO] Checking that emacs is installed." -ForegroundColor Yellow
            & $VAGRANT ssh $VOX_CLIENT_NAME -c "which emacs"
            
            Write-Host "[INFO] The development environment is now ready to use." -ForegroundColor Yellow
            $exit_status = 0
        }
        else {
            Write-Error "[ERROR] Unable to locate vox server host only ip address."
        }
    }
}
else {
    if ($exit_status -ne 2) {
        Write-Error "[ERROR] vagrant command not found."
    }
}

if ($exit_status -eq 2) {
    $exit_status = 0
}

exit $exit_status
