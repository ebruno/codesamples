# AGENTS.md — OpenVox Dev Environment

## Project Overview

This is a Vagrant-based local test environment for [OpenVox](https://voxpupuli.org/),
the community fork of Puppet. It provisions two Ubuntu 24.04 VMs — an OpenVox
server and an agent client — connected via a private host-only network.

**Goal:** Demonstrate OpenVox server↔client configuration management in a
reproducible local environment. Used as a teaching tool for a Udemy class.

## Tech Stack

| Layer | Technology |
|---|---|
| VM orchestration | Vagrant + Ruby DSL |
| Providers | VirtualBox, VMware Desktop (Fusion), Libvirt |
| Guest OS | Ubuntu 24.04 (bento/ubuntu-24.04) |
| Config management | OpenVox 8 (Puppet-compatible) |
| Provisioning | Shell inline + file provisioners |
| Scripting | Bash, Zsh, PowerShell |
| Manifest | Puppet DSL (`install.pp`) |

## File Layout

```
openvox/
├── Vagrantfile              # Main Vagrant config (VirtualBox/VMware)
├── osbox.yml                # Box name + version
├── README.md                # Full documentation
├── setup_voxdev.sh          # Bash setup/destroy script
├── setup_voxdev.zsh         # Zsh setup/destroy script
├── setup_voxdev.ps1         # PowerShell setup/destroy script
├── libvirt/
│   ├── Vagrantfile          # Libvirt-specific Vagrant config
│   └── osbox.yml            # Same box spec
├── puppet/
│   └── manifests/
│       └── vox-client/
│           └── manifests/
│               └── install.pp  # Demo Puppet manifest
└── .vagrant/                # Vagrant state (gitignored)
```

## The Three Setup Scripts

All three scripts (`setup_voxdev.sh`, `.zsh`, `.ps1`) have identical behavior:

```
-h            Help
-p provider   virtualbox | vmware_desktop | libvirt
-s            Show VM status
-d            Destroy all VMs
-q            Quick run (skip provisioning)
-g            VMware GUI mode (vmware_desktop only)
```

### Script workflow
1. Parse arguments, set `$PROVIDER`
2. Pre-flight checks (plugins, provider binaries, network)
3. `vagrant up` — provisions VMs, installs OpenVox server/agent
4. Copy puppet manifest to server, reboot
5. Detect client cert request, sign via `puppetserver ca sign --all`
6. Run `puppet agent --test` on client
7. Verify manifest: emacs-nox installed, systemd-timesyncd active, /etc/motd updated

### Destroy cleanup
1. `vagrant destroy -f`
2. Remove `.vagrant/machines/`
3. `vagrant global-status --prune`
4. **macOS + vmware_desktop only:** Clean `vmInventory` and Fusion plist (`PLInventory Selection`)

## Key Design Decisions

### VMware `.localdomain` workaround
VMware Fusion's DHCP appends `.localdomain` to hostnames. The Puppet server
cert is generated as `vox-server.localdomain`. The scripts add `.localdomain`
entries to the client's `/etc/hosts` and configure `puppet config set server`
to use the FQDN. This only applies to `vmware_desktop` provider.

### VMware GUI cleanup issue
There is a known Vagrant/VMware Fusion issue where destroyed VMs may persist
in the Fusion GUI. The scripts clean `vmInventory` and `com.vmware.fusion.plist`,
but a Fusion restart may be needed. See `README.md` → "VMware Provider Known Issues".

### zsh word splitting
Zsh does not word-split unquoted variables by default (unlike bash). Any
`for item in $variable` loops must use `${=variable}` in zsh scripts to
enable word splitting.

### Network names on Windows
VirtualBox can't create host-only networks with custom names on Windows.
The Vagrantfile has commented-out lines for Windows users.

### VMware GUI flag
`provider.gui` is controlled by the `VOX_VMWARE_GUI` environment variable,
set by the `-g` flag in the setup scripts. Default: headless (no GUI).

## The Puppet Manifest

`puppet/manifests/vox-client/manifests/install.pp` configures three resources:

1. **Package** `emacs-nox` — cross-platform install (Debian/RedHat)
2. **File** `/etc/motd` — Facter variable interpolation (`$facts['fqdn']`)
3. **Service** `systemd-timesyncd` — ensures NTP sync (critical for TLS cert validity)

## When Making Changes

### Check all three scripts
Bash, Zsh, and PowerShell scripts must stay in sync. Any logic change to one
must be mirrored in the other two.

### Bash vs Zsh gotchas
- Word splitting: `${=var}` in zsh, `$var` in bash
- `echo` vs `print` for help text
- `[` vs `[[` — always use `[[` in both bash and zsh
- `local` is function-scoped only
- `set -euo pipefail` is at the top of both

### PowerShell gotchas
- `$ErrorActionPreference = "Continue"` (not Stop)
- `$IsWindows`, `$IsMacOS` for platform checks
- `& $VAGRANT` to invoke external commands
- `$LASTEXITCODE` for exit code checks

### Vagrantfile changes
- Main `Vagrantfile` covers VirtualBox + VMware
- `libvirt/Vagrantfile` is separate (different networking)
- Provider blocks must stay consistent between server and client
- `Vagrantfile.local` is auto-loaded for user overrides

### README updates
Document any new flags, behaviors, or known issues in README.md.
Keep the CLI usage section in sync with actual getopts strings.

## Testing

```bash
# Full cycle test
./setup_voxdev.zsh -p vmware_desktop -g   # Create
./setup_voxdev.zsh -d -p vmware_desktop    # Destroy
```
