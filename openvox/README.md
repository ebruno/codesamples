# OpenVox #
OpenVox is an open-source configuration management platform for IT infrastructure, created as a
community fork of Puppet by the Vox Pupuli collective to keep it fully open-source.

This project demonstrates how to create small local test environment to testing puppet.
It is not intended to be a tutorial on puppet.

This has been tested on the following configurations:

| Host                     | OS         | Provider                   |  Guest OS     | OpenVox |
|:-------------------------|:-----------|:---------------------------|:--------------|:--------|
| M4 MacMini               | MacOS 26   | virtualbox, vmware\_desktop | Ubuntu 24.04  | 8.11.0  |
| Shuttle Cube i9-9900 CPU | Debian 13  | libvirt                    | Ubuntu 24.04  | 8.11.0  |
| Shuttle Cube i9-9900 CPU | Fedora 43  | libvirt                    | Ubuntu 24.04  | 8.11.0  |
| MSI icore i7 laptop      | Windows 11 | virtualbox                 | Ubuntu 24.04  | 8.11.0  |
|   |   |   |   |

Note: When running under Windows 11 the file Vagrantfile needs to edited.
VirtualBox cannot create a host only network with a specific name under Windows 11.
The second network interface definition must have the name removed.

Look for the following lines:

    ...
    # When running on windows uncomment the following line and comment out the line with OpenVox1.
    #client_config.vm.network "private_network",type: "dhcp" ,adapter:2
    client_config.vm.network "private_network",type: "dhcp" ,name: "OpenVox0",adapter:2
    
    ...
    
    # When running on windows uncomment the following line and comment out the line with OpenVox1.
    #client_config.vm.network "private_network",type: "dhcp" ,adapter:2
    client_config.vm.network "private_network",type: "dhcp" ,name: "OpenVox0",adapter:2

Not have a network name defined will also work on MacOS 26 if desired.

## Convenience Scripts

Three scripts are provided — Bash, Zsh, and PowerShell — with identical behavior:

| Script | Platform |
|--------|----------|
| `setup_voxdev.sh` | Linux, macOS (Bash) |
| `setup_voxdev.zsh` | macOS (Zsh) |
| `setup_voxdev.ps1` | Windows, macOS, Linux (PowerShell) |

### Usage

```bash
./setup_voxdev.sh -h
```
```text
Usage: setup_voxdev.sh [options]

  -h            Display this message
  -p provider   Provider: virtualbox, vmware_desktop, libvirt
  -s            Show VM status and exit
  -d            Destroy all VMs and exit
  -q            Quick run — skip provisioning (VMs must already be up)
  -g            Show VMware VM GUI windows (vmware_desktop only)
```

### What the script does

  * **Pre-flight checks** — validates Vagrant plugins, provider, and host-only network before starting
  * **Creates VMs** — two Ubuntu 24.04 nodes (vox-server + vox-client)
  * **Installs OpenVox** — server on vox-server, agent on vox-client
  * **Dynamic IP detection** — finds the private network interface (no hardcoded eth1)
  * **Configures networking** — /etc/hosts entries for server↔client communication
  * **Registers the client** — restarts puppet agent, polls for cert request, signs certificate
  * **Applies manifest** — installs emacs-nox, enables systemd-timesyncd (NTP), writes /etc/motd
  * **Verifies** — confirms emacs is installed, systemd-timesyncd is active, motd is correct
  * **Reports elapsed time** — total runtime shown at the end

### Run time comparison

| Mode | Command | What it does | Time |
|------|---------|-------------|------|
| Full setup | `./setup_voxdev.sh -p virtualbox` | Create VMs, install, configure, apply, verify | ~8 min |
| Quick mode | `./setup_voxdev.sh -q -p virtualbox` | Re-configure and re-apply on running VMs | ~50 sec |
| Status | `./setup_voxdev.sh -s` | Show VM state | < 1 sec |
| Destroy | `./setup_voxdev.sh -d -p virtualbox` | Tear down VMs | ~5 sec |

### Manifest verification

After `puppet agent --test` completes, the script verifies all three resources
from the sample manifest:

```bash
$ vagrant ssh vox_client -c "which emacs && systemctl is-active systemd-timesyncd && cat /etc/motd"
/usr/bin/emacs
active
============================================
Welcome to vox-client
Managed by OpenVox server: vox-server
OS: Debian 24.04
============================================
```

The sample manifest (`puppet/manifests/vox-client/manifests/install.pp`)
demonstrates three resource types and key Puppet concepts:

| Resource | Type | Concept demonstrated |
|----------|------|---------------------|
| `emacs-nox` | `package` | Basic package installation |
| `systemd-timesyncd` | `service` | Built-in systemd service management (`ensure => running`, `enable => true`), no extra package needed |
| `/etc/motd` | `file` | File content management, Facter variable interpolation (`${facts['fqdn']}`) |

`systemd-timesyncd` was chosen intentionally — it's Ubuntu's built-in NTP
client, requiring no extra package. OpenVox uses TLS certificates with
time-based validity: if server and agent clocks drift, certificate validation
fails. Ensuring time sync via Puppet demonstrates a real operational requirement.

The scripts have been tested on:

| Host | OS | Provider | Script |
|------|----|----------|--------|
| M4 MacMini | macOS 26 | virtualbox | bash, zsh, ps1 |
| M4 MacMini | macOS 26 | vmware\_desktop | bash, zsh (see VMware note below) |
| Shuttle i9-9900 | Debian 13 | libvirt | bash |
| Shuttle i9-9900 | Fedora 43 | libvirt | bash |
| MSI i7 laptop | Windows 11 | virtualbox | ps1 |

## Install vagrant and required plugins
It is recommended you install vagrant from the Hashicorp repositories.

Current instructions are here:

 * [HashiCorp](https://developer.hashicorp.com/vagrant/install)


The following vagrant plugins are needed:

  * vagrant-scp
  * vagrant-group
  * vagrant-vmware-desktop (M4 MacMini or Mac's)

On macOS, the VMware provider also requires the Vagrant VMware utility:

```bash
brew install --cask vagrant-vmware-utility
```
  * vagrant-libvirt (Systems running libvirt/qemu)

Note for vagrant-libvirt you may need to install additional packages.
`make` and a compiler may be required.

     Vagrant failed to install the requested plugin because it depends
     on development files for a library which is not currently installed
     on this system. The following library is required by the 'vagrant-libvirt'
     plugin:

       libvirt

     If a package manager is used on this system, please install the development
     package for the library. The name of the package will be similar to:

       libvirt-dev or libvirt-devel

     After the library and development files have been installed, please
     run the command again.



## HCP Vagrant Deprecation Notice

HashiCorp is deprecating **HCP Vagrant** (the hosted box registry at `vagrantcloud.com`)
with end of operations on **December 31, 2026**. After this date, Vagrant boxes such as
`bento/ubuntu-24.04` will no longer be downloadable from the public registry.

See: [Deprecation of HCP Vagrant](https://developer.hashicorp.com/hcp/docs/vagrant/hcp-vagrant-eol)

**Impact on this project:** The `osbox.yml` file references `bento/ubuntu-24.04` from the
public registry. After the shutdown, new users (or clean setups) will need an alternative
box source.

**Mitigation options:**

1. **Pre-download the box** before Dec 31, 2026:
   ```bash
   vagrant box add bento/ubuntu-24.04 --box-version 202508.03.0
   ```
   Once downloaded, Vagrant uses the local cached copy and will not need the registry.

2. **Watch the Bento project** for their new hosting location:
   [github.com/chef/bento](https://github.com/chef/bento) — the Bento maintainers will likely
   announce an alternative registry before the shutdown.

3. **Use a local box file** by updating `osbox.yml` to point to a local `.box` file or a
   self-hosted URL.

## Create Client and Server (VirtualBox / VMware Fusion)

Synced folders are not needed and are disabled.

### Network setup ###

Open VirtualBox or VMware Fusion and create a host only network called OpenVox.  This will be used for the
client and server to communicate with each other.

The first example will use Ubuntu at the time this was developed the most current version
available from vagrant cloud is jammy

## Create Client and Server (libvirt)
The Vagrant file is located in libvirt.  The setup_vox.sh script will automatically use this
if the provider is libvirt.

Synced folders are not needed and are disabled.

Required networks will be automatically created by Vagrant file.

On the host machines the user account that created
the environment was a member of the following groups:

  * kvm libvirt

Messages that start with following can be ignored.

     [fog][WARNING]


## Sample Run

    ./setup_voxdev.sh -p libvirt

    ... vox_server and vox_client are created.
    Both server and client are now configured and running.

    [INFO] Wait 30 seconds for client system to contact server.
    [INFO] Checking Server for cert siging request.
    Requested Certificates:
        vox-client       (SHA256)  9D:BD:CD:8B:F7:7F:47:DB:E1:66:47:27:39:4F:7C:8D:8F:2C:FB:0B:2B:72:8B:8B:E4:C1:40:7D:C7:DF:18:CA
    Signed Certificates:
        vox-server       (SHA256)  11:E5:D2:1F:2C:15:C8:FC:AC:AD:8A:A6:F4:C5:41:9D:A1:08:4A:B8:6A:3C:CB:98:73:22:24:9E:B7:88:6D:00  alt names: ["DNS:puppet", "DNS:vox-server"] authorization extensions: [pp_cli_auth: true]
    Successfully signed the following certificate requests:
      vox-client
    [INFO] Wait 30 seconds for client system to sync with server.
    Info: csr_attributes file loading from /etc/puppetlabs/puppet/csr_attributes.yaml
    Info: Creating a new SSL certificate request for vox-client
    Info: Certificate Request fingerprint (SHA256): 9D:BD:CD:8B:F7:7F:47:DB:E1:66:47:27:39:4F:7C:8D:8F:2C:FB:0B:2B:72:8B:8B:E4:C1:40:7D:C7:DF:18:CA
    Info: Downloaded certificate for vox-client from https://vox-server:8140/puppet-ca/v1
    Info: Using environment 'production'
    Info: Retrieving pluginfacts
    Info: Retrieving plugin
    Notice: Requesting catalog from vox-server:8140 (192.168.100.142)
    Notice: Catalog compiled by vox-server
    Info: Caching catalog for vox-client
    Info: Applying configuration version '1768255205'
    Notice: /Stage[main]/Main/Package[emacs-nox]/ensure: created
    Info: Creating state file /opt/puppetlabs/puppet/cache/state/state.yaml
    Notice: Applied catalog in 26.38 seconds
    [INFO] Checking that emacs is installed.
    /usr/bin/emacs
    [INFO] The development environment is now ready to use.


## References

 * [vagrant-group ](https://github.com/vagrant-group/vagrant-group)
   You can associate a VM to multiple groups, e.g. based on role (web server, database) or project they belong to.
   Then with one simple command you can run basic commands on entire group.

 * [vagrant-scp](https://github.com/invernizzi/vagrant-scp)
   Copy files to a Vagrant guest via SCP.

 * [vagrant-vmware-desktop](https://github.com/hashicorp/vagrant-vmware-desktop)
   This is the common codebase for the official providers for VMware desktop products: Fusion, Player, and Workstation.
   This therefore works on Windows, Mac, and Linux.

 * [vagrant-libvirt](https://voxpupuli.org/openvox/install)
   Vagrant-libvirt is a Vagrant plugin that adds a Libvirt provider to Vagrant,
   allowing Vagrant to control and provision machines via Libvirt toolkit.

 * [OpenVox Installation](https://voxpupuli.org/openvox/install/)
   Links to Debian, RedHat, Windows and MacOS families can be found here.

 * [HCP Vagrant Deprecation](https://developer.hashicorp.com/hcp/docs/vagrant/hcp-vagrant-eol)
   HashiCorp is shutting down the hosted Vagrant box registry. End of operations: December 31, 2026.

## Appendix: Building a Vagrant Box from an ISO

If the `bento/ubuntu-24.04` box becomes unavailable (see HCP Deprecation above),
you can build your own Vagrant box from an Ubuntu ISO.

### Option A: Use Packer (recommended)

[Packer](https://www.packer.io/) automates the full build. The Bento project's
Packer templates produce the exact same box this project uses:

```bash
# Clone the Bento repository
git clone https://github.com/chef/bento.git
cd bento

# Build the Ubuntu 24.04 box for VirtualBox
packer build -only=virtualbox-iso.default ubuntu-24.04-amd64.pkr.hcl
```

This produces a `.box` file you can use:
```bash
vagrant box add ubuntu-24.04 ./builds/ubuntu-24.04.virtualbox.box
```

Then update `osbox.yml`:
```yaml
box_name: ubuntu-24.04
box_version: "0"
```

### Option B: Manual build

1. **Create a VM in VirtualBox** from the
   [Ubuntu 24.04 Server ISO](https://releases.ubuntu.com/24.04/) and complete the installation.

2. **Configure the VM for Vagrant** (run inside the VM after install):
   ```bash
   # Create the vagrant user with passwordless sudo
   sudo useradd -m -s /bin/bash vagrant
   sudo usermod -aG sudo vagrant
   echo 'vagrant ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/vagrant
   sudo chmod 440 /etc/sudoers.d/vagrant

   # Add Vagrant's insecure public key for SSH
   sudo mkdir -p /home/vagrant/.ssh
   sudo curl -o /home/vagrant/.ssh/authorized_keys \
     https://raw.githubusercontent.com/hashicorp/vagrant/main/keys/vagrant.pub
   sudo chmod 700 /home/vagrant/.ssh
   sudo chmod 600 /home/vagrant/.ssh/authorized_keys
   sudo chown -R vagrant:vagrant /home/vagrant/.ssh

   # Install OpenSSH server and VirtualBox Guest Additions
   sudo apt-get update
   sudo apt-get install -y openssh-server virtualbox-guest-additions-iso
   ```

3. **Shut down the VM**, then package it:
   ```bash
   vagrant package --base "<VirtualBox-VM-Name>" --output ubuntu-24.04.box
   vagrant box add ubuntu-24.04 ./ubuntu-24.04.box
   ```

The resulting box works identically to `bento/ubuntu-24.04` — the setup scripts
in this project will provision it with OpenVox as usual.

## Customizing the Vagrant Environment

Drop a `Vagrantfile.local` (or `libvirt/Vagrantfile.local` for libvirt) in the
project directory to override settings without modifying the main Vagrantfile:

```ruby
# Vagrantfile.local — example: increase memory for VMware
Vagrant.configure("2") do |config|
  config.vm.provider "vmware_desktop" do |provider|
    provider.memory = 8192
  end
end
```

The file is loaded automatically if it exists. Use this for provider-specific
tweaks (memory, CPUs, network settings) or adding custom provisioners.

## VMware Provider Known Issues

There is a known Vagrant/VMware Fusion issue where VMs may remain visible
in the VMware Fusion GUI after running `vagrant destroy`. This is a
Vagrant-VMware integration limitation -- the `.vmx` files and Vagrant state
are properly removed, but Fusion's inventory may retain stale entries.

The setup scripts will clean Fusion's `vmInventory` and preferences files
on destroy, but a VMware Fusion restart may be needed to refresh the GUI.

**Recommendations:**
- Use headless mode (the default -- omit `-g`) to avoid the GUI issue entirely.
  VMs run as background processes without appearing in the Fusion library.
- If you use GUI mode (`-g`), manually remove any leftover VMs from the
  VMware Fusion Virtual Machine Library after running `-d`.

## Class Curriculum

A complete 16-slide, ~35-minute class curriculum is available in
[CLASS.md](CLASS.md) — covering OpenVox concepts, live demos, and
hands-on exercises using this project.
