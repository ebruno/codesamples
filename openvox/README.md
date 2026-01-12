# OpenVox #
OpenVox is an open-source configuration management platform for IT infrastructure, created as a
community fork of Puppet by the Vox Pupuli collective to keep it fully open-source.

This project demonstrates how to create small local test environment to testing puppet.
It is not intended to be a tutorial on puppet.

This has been tested on the following configurations:

| Host                     | OS        | Provider                   |  Guest OS     | OpenVox |
|:-------------------------|:----------|:---------------------------|:--------------|:--------|
| M4 MacMini               | MacOS 26  | virtualbox, vmware_fusion  | Ubuntu 24.04  | 8.11.0  |
| Shuttle Cube i9-9900 CPU | Debian 13 | libvirt                    | Ubuntu 24.04  | 8.11.0  |
| Shuttle Cube i9-9900 CPU | Fedora 43 | libvirt                    | Ubuntu 24.04  | 8.11.0  |
|   |   |   |   |


## Convenience Script ##
A convenience  script is provided.

 * setup_voxdev.sh

		./setup_voxdev.sh -h
		setup_voxdev.sh [h] [p provider]
		-h - display this message
		-p - provider (virtualbox, vmware_fusion, vmware_desktop, libvirt).

 The script does the following:

  * Creates the VM's
  * Installs openvox
  * Configures the server and client to communicate.
  * Registers the client
  * Runs a puppet agent test to verify the manifest that installs emacs-nox works.

## Install vagrant and required plugins
It is recommended you install vagrant from the Hashicorp repositories.

Current instructions are here:

 * [HashiCorp](https://developer.hashicorp.com/vagrant/install)


The following vagrant plugins are needed:

  * vagrant-scp
  * vagrant-group
  * vagrant-vmware-desktop (M4 MacMini or Mac's)
  * vagrant-libvirt (Systems running libvirt/qemu)

Note for vagrant-libvirt you may need to install additional packages.
make and a compiler may be record.

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



## Create client and server using vagrant, virtual-box, vmware fusion ##

Synced folders are not needed and are disabled.

### Network setup ###

Open VirtualBox or VMware Fusion and create a host only network called OpenVox.  This will be used for the
client and server to communicate with each other.

The first example will use Ubuntu at the time this was developed the most current version
available from vagrant cloud is jammy

## Create client and server using vagrant and libvirt ##
The Vagrant file is located in libvirt.  The setup_vox.sh script will automatically use this
if the provider is libvirt.

Synced folders are not needed and are disabled.

Required networks will be automatically created by Vagrant file.

On the host machines the user account that created
the environment was a member of the following groups:

  * kvm docker libvirt

Messages that start with following can be ignored.

	 [fog][WARNING]


## Sample Run ##

	./setup_voxdev.sh -p libvirt

	... vox_server and vox_client are created.
	Both server and client are now configured and running.

	[INFO] Wait 30 seconds for client system to contact server.
	[INFO] Checking Server for cert siging request.
	Requested Certificates:
		vox-client       (SHA256)  9D:BD:CD:8B:F7:7F:47:DB:E1:66:47:27:39:4F:7C:8D:8F:2C:FB:0B:2B:72:8B:8B:E4:C1:40:7D:C7:DF:18:CA
	Signed Certificates:
		vox-server       (SHA256)  11:E5:D2:1F:2C:15:C8:FC:AC:AD:8A:A6:F4:C5:41:9D:A1:08:4A:B8:6A:3C:CB:98:73:22:24:9E:B7:88:6D:00	alt names: ["DNS:puppet", "DNS:vox-server"]	authorization extensions: [pp_cli_auth: true]
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


## References ##

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
