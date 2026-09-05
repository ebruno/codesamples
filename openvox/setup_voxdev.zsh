#!/usr/bin/env zsh
set -euo pipefail

# Track elapsed time for reporting at the end.
start_time=$SECONDS

# =========================================================================
# setup_voxdev.zsh — OpenVox dev environment (zsh version)
#
# Usage:
#   ./setup_voxdev.zsh -p virtualbox          # Full setup
#   ./setup_voxdev.zsh -s                      # Show VM status
#   ./setup_voxdev.zsh -d -p virtualbox        # Destroy VMs
#   ./setup_voxdev.zsh -q -p virtualbox        # Quick run (skip provisioning)
# =========================================================================

# ── Helpers ───────────────────────────────────────────────────────────────

ZSH_VERSION_MIN="5.0"
autoload is-at-least
is-at-least "$ZSH_VERSION_MIN" || {
    print -u2 "[ERROR] zsh >= ${ZSH_VERSION_MIN} required (running $ZSH_VERSION)"
    exit 1
}

typeset -a TMP_FILES=()

info()  { print -u2 "[INFO]  $*"; }
warn()  { print -u2 "[WARN]  $*"; }
error() { print -u2 "[ERROR] $*"; }

cleanup() {
    for f in "${TMP_FILES[@]}"; do
        rm -f "$f"
    done
}
trap cleanup EXIT

# Create a temp file that gets auto-cleaned on exit
mktempfile() {
    local f
    f=$(mktemp) || { error "mktemp failed"; exit 1; }
    TMP_FILES+=("$f")
    print "$f"
}

# ── Configuration ─────────────────────────────────────────────────────────

VOX_SERVER_NAME="vox_server"
VOX_SERVER_HOST_NAME="vox-server"
VOX_CLIENT_NAME="vox_client"
VOX_CLIENT_HOST_NAME="vox-client"
WAIT_TIME=30
WAIT_TIME_CLIENT=30
VALID_PROVIDERS=(virtualbox vmware_fusion vmware_desktop libvirt)

# ── Argument parsing ──────────────────────────────────────────────────────

PROVIDER="virtualbox"
DO_STATUS=0
DO_DESTROY=0
DO_QUICK=0

usage() {
    print "Usage: setup_voxdev.zsh [options]"
    print ""
    print "  -h            Display this message"
    print "  -p provider   Provider: virtualbox, vmware_fusion, vmware_desktop, libvirt"
    print "  -s            Show VM status and exit"
    print "  -d            Destroy all VMs and exit"
    print "  -q            Quick run — skip provisioning (VMs must already be up)"
    exit 0
}

while getopts ":hp:sdq" opt; do
    case $opt in
        h) usage ;;
        p) PROVIDER="$OPTARG" ;;
        s) DO_STATUS=1 ;;
        d) DO_DESTROY=1 ;;
        q) DO_QUICK=1 ;;
        :) error "Option -$OPTARG requires an argument."; exit 1 ;;
        \?) error "Invalid option: -$OPTARG"; exit 1 ;;
    esac
done

# ── Validate prerequisites ─────────────────────────────────────────────────

VAGRANT=$(command -v vagrant) || { error "vagrant command not found."; exit 1; }

if (( ${VALID_PROVIDERS[(Ie)$PROVIDER]} == 0 )); then
    error "Provider '$PROVIDER' is not valid/supported."
    exit 1
fi

export VAGRANT_DEFAULT_PROVIDER=$PROVIDER

# ── Change to correct Vagrantfile directory ───────────────────────────────

if [[ "$PROVIDER" == "libvirt" ]]; then
    if [[ -d libvirt ]]; then
        pushd libvirt > /dev/null
    else
        error "libvirt/ directory not found."
        exit 1
    fi
fi

restore_dir() {
    if [[ "$PROVIDER" == "libvirt" ]]; then
        popd > /dev/null 2>&1 || true
    fi
}
trap 'cleanup; restore_dir' EXIT

# ── --status: show VM state and exit ──────────────────────────────────────

if (( DO_STATUS )); then
    info "VM status:"
    $VAGRANT status
    exit 0
fi

# ── --destroy: tear down VMs and exit ─────────────────────────────────────

if (( DO_DESTROY )); then
    info "Destroying all VMs..."
    $VAGRANT destroy -f || { error "Destroy failed."; exit 1; }
    info "VMs destroyed."
    exit 0
fi

# ── Pre-flight checks ─────────────────────────────────────────────────────

info "Using provider: $PROVIDER"
info "Running pre-flight checks..."

# Common plugins
check_plugin() {
    local plugin="$1"
    if ! $VAGRANT plugin list 2>/dev/null | grep -q "$plugin"; then
        error "Required Vagrant plugin not installed: $plugin"
        error "Install with: vagrant plugin install $plugin"
        exit 1
    fi
}
check_plugin vagrant-scp
check_plugin vagrant-group

# Provider-specific checks
case "$PROVIDER" in
    virtualbox)
        if ! command -v VBoxManage &>/dev/null; then
            error "VirtualBox not found. Install from https://www.virtualbox.org/"
            exit 1
        fi
        if VBoxManage list hostonlynets 2>/dev/null | grep -q "OpenVox0"; then
            info "  Host-only network 'OpenVox0' found."
        else
            warn "  Host-only network 'OpenVox0' not found in VirtualBox."
            warn "  Create it: VirtualBox → File → Host Network Manager → Create"
            warn "  Name it 'OpenVox0' with DHCP enabled."
        fi
        ;;
    vmware_fusion|vmware_desktop)
        check_plugin vagrant-vmware-desktop
        if ! command -v vmrun &>/dev/null; then
            error "VMware Fusion not found."
            exit 1
        fi
        ;;
    libvirt)
        check_plugin vagrant-libvirt
        if ! command -v virsh &>/dev/null; then
            error "libvirt not found."
            exit 1
        fi
        ;;
esac

info "Pre-flight checks passed."

# ── Bring up VMs (skip if --quick) ────────────────────────────────────────

if (( DO_QUICK )); then
    info "Quick mode — skipping provisioning. VMs must already be running."
else
    info "Bringing up VMs via 'vagrant group up voxdevelopment'..."
    $VAGRANT group up voxdevelopment || {
        error "Failed to bring up VMs. Check 'vagrant status' for details."
        exit 1
    }
fi

# ── Discover private network IPs dynamically ───────────────────────────────

# Write a small bash script to a temp file, scp it to the VM, and run it.
# This avoids all the quoting/escaping issues with inline commands through
# vagrant ssh + zsh double-quote expansion.
get_private_ip() {
    local vm_name="$1"
    local tmp output default_iface ip

    tmp=$(mktempfile)
    # Write a bash script that uses only built-ins (no awk/grep),
    # avoiding all quoting headaches through vagrant ssh.
    {
        printf '%s\n' '#!/usr/bin/env bash'
        printf '%s\n' '# Find the default-route interface (the one after "dev")'
        printf '%s\n' 'default_iface=""'
        printf '%s\n' 'while read -r _ _ _ _ iface _; do default_iface="$iface"; break; done < <(ip -4 route show default)'
        printf '%s\n' 'echo "DEFAULT:$default_iface"'
        printf '%s\n' '# Find first non-lo, non-default interface with an IPv4 address'
        printf '%s\n' 'ip -4 -o addr show | while read -r _ iface _ addr _; do'
        printf '%s\n' '  [[ "$iface" == "lo" ]] && continue'
        printf '%s\n' '  [[ "$iface" == "$default_iface" ]] && continue'
        printf '%s\n' '  echo "IP:${addr%/*}"'
        printf '%s\n' '  break'
        printf '%s\n' 'done'
    } > "$tmp"

    $VAGRANT scp "$tmp" "${vm_name}:./_get_ip.sh" > /dev/null 2>&1 || {
        error "scp to $vm_name failed. Is the VM running?"
        exit 1
    }

    output=$($VAGRANT ssh "$vm_name" -c "bash ./_get_ip.sh" 2>/dev/null) || {
        error "Failed to run IP detection on $vm_name"
        exit 1
    }
    $VAGRANT ssh "$vm_name" -c "rm -f ./_get_ip.sh" > /dev/null 2>&1 || true

    # Parse the tagged output lines
    default_iface="${output#*DEFAULT:}"
    default_iface="${default_iface%%$'\n'*}"
    ip="${output#*IP:}"
    ip="${ip%%$'\n'*}"

    if [[ -z "$default_iface" ]]; then
        error "Failed to determine default-route interface on $vm_name"
        exit 1
    fi

    info "  $vm_name default-route interface: $default_iface"

    if [[ -z "$ip" ]]; then
        error "No private-interface IP found on $vm_name (only default route and lo detected)"
        exit 1
    fi

    print "$ip"
}

VOX_SERVER_IP=$(get_private_ip "$VOX_SERVER_NAME")
VOX_CLIENT_IP=$(get_private_ip "$VOX_CLIENT_NAME")

info "vox server private IP: $VOX_SERVER_IP"
info "vox client private IP: $VOX_CLIENT_IP"

# ── Configure /etc/hosts on both VMs ──────────────────────────────────────

configure_server_hosts() {
    local tmp
    tmp=$(mktempfile)

    # Build the generated bash script using printf for precise control.
    # Each provider branch exists for flexibility.
    case "$PROVIDER" in
        virtualbox|libvirt)
            printf '#!/usr/bin/env bash\ncat >> /etc/hosts <<HOSTS\n%s puppet\n%s %s\nHOSTS\n' \
                "$VOX_SERVER_IP" "$VOX_CLIENT_IP" "$VOX_CLIENT_HOST_NAME" > "$tmp"
            ;;
        vmware_fusion)
            printf '#!/usr/bin/env bash\ncat >> /etc/hosts <<HOSTS\n%s puppet\n%s %s\nHOSTS\n' \
                "$VOX_SERVER_IP" "$VOX_CLIENT_IP" "$VOX_CLIENT_HOST_NAME" > "$tmp"
            ;;
        vmware_desktop)
            printf '#!/usr/bin/env bash\ncat >> /etc/hosts <<HOSTS\n%s puppet\n%s %s\nHOSTS\n' \
                "$VOX_SERVER_IP" "$VOX_CLIENT_IP" "$VOX_CLIENT_HOST_NAME" > "$tmp"
            ;;
        *)
            printf '#!/usr/bin/env bash\ncat >> /etc/hosts <<HOSTS\n%s puppet\n%s %s\nHOSTS\n' \
                "$VOX_SERVER_IP" "$VOX_CLIENT_IP" "$VOX_CLIENT_HOST_NAME" > "$tmp"
            ;;
    esac

    info "Uploading hosts script to ${VOX_SERVER_NAME}..."
    $VAGRANT scp "$tmp" "${VOX_SERVER_NAME}:./configure_hosts.sh" || {
        error "scp to server failed."
        exit 1
    }
    $VAGRANT ssh "$VOX_SERVER_NAME" -c "chmod a+x ./configure_hosts.sh" || true
    $VAGRANT ssh "$VOX_SERVER_NAME" -c "sudo ./configure_hosts.sh" || {
        error "Failed to configure /etc/hosts on server."
        exit 1
    }
}

configure_client_hosts() {
    local tmp domain
    tmp=$(mktempfile)
    domain="$VOX_SERVER_HOST_NAME"   # default; vmware_fusion overrides below

    # Build the generated bash script using printf for precise control.
    case "$PROVIDER" in
        virtualbox|libvirt)
            printf '#!/usr/bin/env bash\ncat >> /etc/hosts <<HOSTS\n%s %s puppet\nHOSTS\n' \
                "$VOX_SERVER_IP" "$VOX_SERVER_HOST_NAME" > "$tmp"
            ;;
        vmware_fusion)
            printf '#!/usr/bin/env bash\ncat >> /etc/hosts <<HOSTS\n%s %s puppet %s.localdomain\nHOSTS\n' \
                "$VOX_SERVER_IP" "$VOX_SERVER_HOST_NAME" "$VOX_SERVER_HOST_NAME" > "$tmp"
            domain="${VOX_SERVER_HOST_NAME}.localdomain"
            ;;
        vmware_desktop)
            printf '#!/usr/bin/env bash\ncat >> /etc/hosts <<HOSTS\n%s %s puppet\nHOSTS\n' \
                "$VOX_SERVER_IP" "$VOX_SERVER_HOST_NAME" > "$tmp"
            ;;
        *)
            printf '#!/usr/bin/env bash\ncat >> /etc/hosts <<HOSTS\n%s %s puppet\nHOSTS\n' \
                "$VOX_SERVER_IP" "$VOX_SERVER_HOST_NAME" > "$tmp"
            ;;
    esac

    info "Uploading hosts script to ${VOX_CLIENT_NAME}..."
    $VAGRANT scp "$tmp" "${VOX_CLIENT_NAME}:./configure_hosts.sh" || {
        error "scp to client failed."
        exit 1
    }
    $VAGRANT ssh "$VOX_CLIENT_NAME" -c "chmod a+x ./configure_hosts.sh" || true
    $VAGRANT ssh "$VOX_CLIENT_NAME" -c "sudo ./configure_hosts.sh" || {
        error "Failed to configure /etc/hosts on client."
        exit 1
    }

    print "$domain"
}

configure_server_hosts
VOX_SERVER_DOMAIN_NAME=$(configure_client_hosts)
info "Server domain name used by client: $VOX_SERVER_DOMAIN_NAME"

# ── Configure puppet agent ─────────────────────────────────────────────────

info "Configuring puppet agent to use server: ${VOX_SERVER_DOMAIN_NAME}..."
$VAGRANT ssh "$VOX_CLIENT_NAME" -c \
    "sudo puppet config set server ${VOX_SERVER_DOMAIN_NAME} --section agent" || {
    error "Failed to configure puppet agent server setting."
    exit 1
}

info "Restarting puppet agent to trigger certificate request..."
$VAGRANT ssh "$VOX_CLIENT_NAME" -c "sudo systemctl restart puppet" || {
    error "Failed to restart puppet agent service."
    exit 1
}

# ── Wait for certificate request (polling, not fixed sleep) ────────────────

info "Waiting for client certificate request to appear on server..."
integer waited=0
integer max_wait=$WAIT_TIME
integer poll_interval=5
cert_output=""

while (( waited < max_wait )); do
    cert_output=$($VAGRANT ssh "$VOX_SERVER_NAME" -c \
        "sudo puppetserver ca list --all" 2>&1) || true
    if [[ "$cert_output" == *"$VOX_CLIENT_HOST_NAME"* ]]; then
        info "Certificate request detected after ${waited}s."
        break
    fi
    sleep "$poll_interval"
    (( waited += poll_interval ))
done

if (( waited >= max_wait )); then
    warn "No certificate request from $VOX_CLIENT_HOST_NAME detected within ${max_wait}s."
    warn "Continuing anyway — you may need to sign manually."
fi

info "Current certificate status:"
$VAGRANT ssh "$VOX_SERVER_NAME" -c "sudo puppetserver ca list --all" || true

info "Signing all pending certificate requests..."
$VAGRANT ssh "$VOX_SERVER_NAME" -c "sudo puppetserver ca sign --all" || {
    warn "Certificate signing returned non-zero (may have nothing to sign)."
}

# ── Wait for client to sync ────────────────────────────────────────────────

info "Waiting ${WAIT_TIME_CLIENT}s for client to sync with server..."
sleep "$WAIT_TIME_CLIENT"

# ── Test puppet agent ─────────────────────────────────────────────────────

info "Running 'puppet agent --test' on client..."
# puppet agent exit codes: 0=no changes, 2=changes applied (both are success)
set +e
$VAGRANT ssh "$VOX_CLIENT_NAME" -c "sudo puppet agent --test"
agent_rc=$?
set -e
if (( agent_rc != 0 && agent_rc != 2 )); then
    error "Puppet agent test failed (exit code: $agent_rc)."
    exit 1
fi

# ── Verify manifest applied ───────────────────────────────────────────────

info "Verifying manifest was applied..."
$VAGRANT ssh "$VOX_CLIENT_NAME" -c "which emacs && systemctl is-active systemd-timesyncd && cat /etc/motd" || {
    error "Manifest verification failed."
    exit 1
}

elapsed=$(( SECONDS - start_time ))
printf -v elapsed_fmt '%dm %ds' $(( elapsed / 60 )) $(( elapsed % 60 ))
info "The development environment is now ready to use. (elapsed: ${elapsed_fmt})"
