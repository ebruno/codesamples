# Example builds for VMware using Packer #

Examples builds for VMware and VSphere
The templates were tested on:

  * Fedora 42 Server
  * MacOS X Tahoe 26.0.1

  VMware ESXi server 8.03
  VMware vCenter 8.03

Packer documentation:

The VNware builder creates a virtual machine, installs an operating system from an ISO,
provisions software within the operating system, and then exports the virtual machine as an image.
This is best for those who want to start by creating an image for use with VMware desktop hypervisors:

  * VMware Fusion Pro
  * VMware Workstation Pro
  * VMware Workstation Player
  * VMware vSphere Hypervisor

Documentation:

  * [VMware ISO](https://developer.hashicorp.com/packer/integrations/hashicorp/vmware/latest/components/builder/iso)

The vSphere builder starts from a guest operating system ISO file and builds a virtual machine image on a
vSphere cluster or an ESXi host using the vSphere API.

Documentation:

  * [vSphere ISO](https://developer.hashicorp.com/packer/integrations/hashicorp/vsphere/latest/components/builder/vsphere-iso)

## Environment ##

It is required that packer and Broadcom VMware ovtool are installed on the system.

 * fedora42srv\_vmware.pkr.hcl  requires access to an ESXI Server
 * fedora42srv\_vsphere.pkr.hcl requires access to a vCenter instance.
 * freebsd14srv\_vsphere.pkr.hcl requires access to a vCenter instance.

It is also recommended to install Microsoft Powershell and VMware Powershell Extensions.

### MacOS ###

Instructions for installing packer, powershell, ovftool, VMWARE Powershell extensions can be found here:

 * [PACKER](https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli)
 * [POWERSHELL](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-macos?view=powershell-7.5)
 * [OVFTOOL](https://developer.broadcom.com/tools/open-virtualization-format-ovf-tool/latest)
 * [VMWARE_POWERSHELL](https://developer.broadcom.com/powercli/installation-guide)


You may need to issue the following powershell commands to complete the setup.

	Register-PSRepository -Default
	Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
	Install-Module -Name VMware.PowerCLI -Scope CurrentUser
	
### Linux ###

Instructions for installing packer, powershell, ovftool, VMWARE Powershell extensions can be found here:

 * [PACKER](https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli)
 * [POWERSHELL](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-macos?view=powershell-7.5)
 * [OVFTOOL](https://developer.broadcom.com/tools/open-virtualization-format-ovf-tool/latest)
 * [VMWARE_POWERSHELL](https://developer.broadcom.com/powercli/installation-guide)

Depending on your Linux distribution the following package(s) may need to be installed ovftool to function:

  * sudo dnf install libnsl
  * sudo dnf install libxcrypt-compat


You may need to issue the following powershell commands to complete the setup.

	Register-PSRepository -Default
	Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
	Install-Module -Name VMware.PowerCLI -Scope CurrentUser

It is suggested mkpasswd be installed to generate encrypted passwords.
mkpasswd may be in it's own package.

### How to get list of supported guestId's ###
Using powershell:

     # if you are using self signed certs execute this command
	 # Set-PowerCLIConfiguration -InvalidCertificateAction Ignore
	 Connect-VIServer -Server <vcenter server> -User <account>@<domain> -Password <password>
	 $anyEsxiHost = @(Get-VMHost) | Select-Object -First 1
	 $envBrowser = Get-View -Id (Get-View -Id $anyEsxiHost.ExtensionData.Parent).EnvironmentBrowser
	 $vmxVersion = ($envBrowser.QueryConfigOptionDescriptor() | Where-Object {$_.DefaultConfigOption}).Key
	 $envBrowser.QueryConfigOption($vmxVersion, $null).GuestOSDescriptor | Select-Object -Property Id, FullName
	 
	 Id                         FullName
	 --                         --------
	 amazonlinux3_64Guest       Amazon Linux 3 (64-bit)
	 amazonlinux2_64Guest       Amazon Linux 2 (64-bit)
	 almalinux_64Guest          AlmaLinux (64-bit)
	 rockylinux_64Guest         Rocky Linux (64-bit)
	 windows2022srvNext_64Guest Microsoft Windows Server 2025 (64-bit)
	 windows2019srvNext_64Guest Microsoft Windows Server 2022 (64-bit)
	 windows2019srv_64Guest     Microsoft Windows Server 2019 (64-bit)
	 windows9Server64Guest      Microsoft Windows Server 2016 (64-bit)
	 windows8Server64Guest      Microsoft Windows Server 2012 (64-bit)
	 windows7Server64Guest      Microsoft Windows Server 2008 R2 (64-bit)
	 winLonghorn64Guest         Microsoft Windows Server 2008 (64-bit)
	 winLonghornGuest           Microsoft Windows Server 2008 (32-bit)
	 winNetEnterprise64Guest    Microsoft Windows Server 2003 (64-bit)
	 winNetEnterpriseGuest      Microsoft Windows Server 2003 (32-bit)
	 winNetDatacenter64Guest    Microsoft Windows Server 2003 Datacenter (64-bit)
	 winNetDatacenterGuest      Microsoft Windows Server 2003 Datacenter (32-bit)
	 winNetStandard64Guest      Microsoft Windows Server 2003 Standard (64-bit)
	 winNetStandardGuest        Microsoft Windows Server 2003 Standard (32-bit)
	 winNetWebGuest             Microsoft Windows Server 2003 Web Edition (32-bit)
	 winNetBusinessGuest        Microsoft Small Business Server 2003
	 windows12_64Guest          Microsoft Windows (64-bit)
	 windows11_64Guest          Microsoft Windows 11 (64-bit)
	 windows9_64Guest           Microsoft Windows 10 (64-bit)
	 windows9Guest              Microsoft Windows 10 (32-bit)
	 windows8_64Guest           Microsoft Windows 8.x (64-bit)
	 windows8Guest              Microsoft Windows 8.x (32-bit)
	 windows7_64Guest           Microsoft Windows 7 (64-bit)
	 windows7Guest              Microsoft Windows 7 (32-bit)
	 winVista64Guest            Microsoft Windows Vista (64-bit)
	 winVistaGuest              Microsoft Windows Vista (32-bit)
	 winXPPro64Guest            Microsoft Windows XP Professional (64-bit)
	 winXPProGuest              Microsoft Windows XP Professional (32-bit)
	 win2000AdvServGuest        Microsoft Windows 2000
	 win2000ServGuest           Microsoft Windows 2000 Server
	 win2000ProGuest            Microsoft Windows 2000 Professional
	 winNTGuest                 Microsoft Windows NT
	 win98Guest                 Microsoft Windows 98
	 win95Guest                 Microsoft Windows 95
	 win31Guest                 Microsoft Windows 3.1
	 dosGuest                   Microsoft MS-DOS
	 vmwarePhoton64Guest        VMware Photon OS (64-bit)
	 crxPod1Guest               VMware CRX Pod 1 (64-bit)
	 crxSys1Guest               VMware Photon CRX (64-bit)
	 rhel9_64Guest              Red Hat Enterprise Linux 9 (64-bit)
	 rhel8_64Guest              Red Hat Enterprise Linux 8 (64-bit)
	 rhel7_64Guest              Red Hat Enterprise Linux 7 (64-bit)
	 rhel6_64Guest              Red Hat Enterprise Linux 6 (64-bit)
	 rhel6Guest                 Red Hat Enterprise Linux 6 (32-bit)
	 rhel5_64Guest              Red Hat Enterprise Linux 5 (64-bit)
	 rhel5Guest                 Red Hat Enterprise Linux 5 (32-bit)
	 rhel4_64Guest              Red Hat Enterprise Linux 4 (64-bit)
	 rhel4Guest                 Red Hat Enterprise Linux 4 (32-bit)
	 rhel3_64Guest              Red Hat Enterprise Linux 3 (64-bit)
	 rhel3Guest                 Red Hat Enterprise Linux 3 (32-bit)
	 rhel2Guest                 Red Hat Enterprise Linux 2.1
	 sles16_64Guest             SUSE Linux Enterprise 16 (64-bit)
	 sles15_64Guest             SUSE Linux Enterprise 15 (64-bit)
	 sles12_64Guest             SUSE Linux Enterprise 12 (64-bit)
	 sles11_64Guest             SUSE Linux Enterprise 11 (64-bit)
	 sles11Guest                SUSE Linux Enterprise 11 (32-bit)
	 sles10_64Guest             SUSE Linux Enterprise 10 (64-bit)
	 sles10Guest                SUSE Linux Enterprise 10 (32-bit)
	 sles64Guest                SUSE Linux Enterprise 8/9 (64-bit)
	 slesGuest                  SUSE Linux Enterprise 8/9 (32-bit)
	 centos9_64Guest            CentOS 9 (64-bit)
	 centos8_64Guest            CentOS 8 (64-bit)
	 centos7_64Guest            CentOS 7 (64-bit)
	 centos6_64Guest            CentOS 6 (64-bit)
	 centos6Guest               CentOS 6 (32-bit)
	 centos64Guest              CentOS 4/5 (64-bit)
	 centosGuest                CentOS 4/5 (32-bit)
	 debian12_64Guest           Debian GNU/Linux 12 (64-bit)
	 debian12Guest              Debian GNU/Linux 12 (32-bit)
	 debian11_64Guest           Debian GNU/Linux 11 (64-bit)
	 debian11Guest              Debian GNU/Linux 11 (32-bit)
	 debian10_64Guest           Debian GNU/Linux 10 (64-bit)
	 debian10Guest              Debian GNU/Linux 10 (32-bit)
	 debian9_64Guest            Debian GNU/Linux 9 (64-bit)
	 debian9Guest               Debian GNU/Linux 9 (32-bit)
	 debian8_64Guest            Debian GNU/Linux 8 (64-bit)
	 debian8Guest               Debian GNU/Linux 8 (32-bit)
	 debian7_64Guest            Debian GNU/Linux 7 (64-bit)
	 debian7Guest               Debian GNU/Linux 7 (32-bit)
	 debian6_64Guest            Debian GNU/Linux 6 (64-bit)
	 debian6Guest               Debian GNU/Linux 6 (32-bit)
	 debian5_64Guest            Debian GNU/Linux 5 (64-bit)
	 debian5Guest               Debian GNU/Linux 5 (32-bit)
	 debian4_64Guest            Debian GNU/Linux 4 (64-bit)
	 debian4Guest               Debian GNU/Linux 4 (32-bit)
	 opensuse64Guest            SUSE openSUSE (64-bit)
	 opensuseGuest              SUSE openSUSE (32-bit)
	 asianux8_64Guest           MIRACLE LINUX 8 (64-bit)
	 asianux7_64Guest           Asianux 7 (64-bit)
	 asianux4_64Guest           Asianux 4 (64-bit)
	 asianux4Guest              Asianux 4 (32-bit)
	 asianux3_64Guest           Asianux 3 (64-bit)
	 asianux3Guest              Asianux 3 (32-bit)
	 fedora64Guest              Red Hat Fedora (64-bit)
	 fedoraGuest                Red Hat Fedora (32-bit)
	 oesGuest                   Novell Open Enterprise Server
	 oracleLinux9_64Guest       Oracle Linux 9 (64-bit)
	 oracleLinux8_64Guest       Oracle Linux 8 (64-bit)
	 oracleLinux7_64Guest       Oracle Linux 7 (64-bit)
	 oracleLinux6_64Guest       Oracle Linux 6 (64-bit)
	 oracleLinux6Guest          Oracle Linux 6 (32-bit)
	 oracleLinux64Guest         Oracle Linux 4/5 (64-bit)
	 oracleLinuxGuest           Oracle Linux 4/5 (32-bit)
	 ubuntu64Guest              Ubuntu Linux (64-bit)
	 ubuntuGuest                Ubuntu Linux (32-bit)
	 coreos64Guest              CoreOS Linux (64-bit)
	 other6xLinux64Guest        Other 6.x or later Linux (64-bit)
	 other6xLinuxGuest          Other 6.x or later Linux (32-bit)
	 other5xLinux64Guest        Other 5.x Linux (64-bit)
	 other5xLinuxGuest          Other 5.x Linux (32-bit)
	 other4xLinux64Guest        Other 4.x Linux (64-bit)
	 other4xLinuxGuest          Other 4.x Linux (32-bit)
	 other3xLinux64Guest        Other 3.x Linux (64-bit)
	 other3xLinuxGuest          Other 3.x Linux (32-bit)
	 other26xLinux64Guest       Other 2.6.x Linux (64-bit)
	 other26xLinuxGuest         Other 2.6.x Linux (32-bit)
	 other24xLinux64Guest       Other 2.4.x Linux (64-bit)
	 other24xLinuxGuest         Other 2.4.x Linux (32-bit)
	 otherLinux64Guest          Other Linux (64-bit)
	 otherLinuxGuest            Other Linux (32-bit)
	 darwin23_64Guest           Apple macOS 14 (64-bit)
	 darwin22_64Guest           Apple macOS 13 (64-bit)
	 darwin21_64Guest           Apple macOS 12 (64-bit)
	 darwin20_64Guest           Apple macOS 11 (64-bit)
	 darwin19_64Guest           Apple macOS 10.15 (64-bit)
	 darwin18_64Guest           Apple macOS 10.14 (64-bit)
	 darwin17_64Guest           Apple macOS 10.13 (64-bit)
	 darwin16_64Guest           Apple macOS 10.12 (64-bit)
	 darwin15_64Guest           Apple Mac OS X 10.11 (64-bit)
	 darwin14_64Guest           Apple Mac OS X 10.10 (64-bit)
	 darwin13_64Guest           Apple Mac OS X 10.9 (64-bit)
	 darwin12_64Guest           Apple Mac OS X 10.8 (64-bit)
	 darwin11_64Guest           Apple Mac OS X 10.7 (64-bit)
	 darwin11Guest              Apple Mac OS X 10.7 (32-bit)
	 darwin10_64Guest           Apple Mac OS X 10.6 (64-bit)
	 darwin10Guest              Apple Mac OS X 10.6 (32-bit)
	 darwin64Guest              Apple Mac OS X 10.5 (64-bit)
	 darwinGuest                Apple Mac OS X 10.5 (32-bit)
	 freebsd14_64Guest          FreeBSD 14 or later versions (64-bit)
	 freebsd14Guest             FreeBSD 14 or later versions (32-bit)
	 freebsd13_64Guest          FreeBSD 13 (64-bit)
	 freebsd13Guest             FreeBSD 13 (32-bit)
	 freebsd12_64Guest          FreeBSD 12 (64-bit)
	 freebsd12Guest             FreeBSD 12 (32-bit)
	 freebsd11_64Guest          FreeBSD 11 (64-bit)
	 freebsd11Guest             FreeBSD 11 (32-bit)
	 freebsd64Guest             FreeBSD Pre-11 versions (64-bit)
	 freebsdGuest               FreeBSD Pre-11 versions (32-bit)
	 os2Guest                   IBM OS/2
	 netware6Guest              Novell NetWare 6.x
	 netware5Guest              Novell NetWare 5.1
	 solaris11_64Guest          Oracle Solaris 11 (64-bit)
	 solaris10_64Guest          Oracle Solaris 10 (64-bit)
	 solaris10Guest             Oracle Solaris 10 (32-bit)
	 solaris9Guest              Sun Microsystems Solaris 9
	 solaris8Guest              Sun Microsystems Solaris 8
	 openServer6Guest           SCO OpenServer 6
	 openServer5Guest           SCO OpenServer 5
	 unixWare7Guest             SCO UnixWare 7
	 eComStation2Guest          Serenity Systems eComStation 2
	 eComStationGuest           Serenity Systems eComStation 1
	 otherGuest64               Other (64-bit)
	 otherGuest                 Other (32-bit)
	 vmkernel8Guest             VMware ESXi 8.0 or later
	 vmkernel7Guest             VMware ESXi 7.x
	 vmkernel65Guest            VMware ESXi 6.x
	 vmkernel6Guest             VMware ESXi 6.0
	 vmkernel5Guest             VMware ESXi 5.x
	 vmkernelGuest              VMware ESX 4.x


## fedora42srv\_vmware.pkr.hcl ##

Variables:

 | Name                | Description  | Type | Default | Required | Adjust for deployment environment |
 |:--------------------|:-------------|:-----|:--------|:--------:|:--------------------:|
 | remote\_username    | User name for login | string | None | Yes | Yes |
 | remote\_password    | User password for login  | string | None | Yes | Yes |
 | esxi\_server        | esxi server IP/FQDN | string | None | Yes | Yes |
 | output\_directory"  | Output directory for VM artifacts |string | ./output-artifacts | Yes | Yes |
 | vm\_name            | Virtual Machine name to build  | string | Fedorasrv42\_Demo | Yes | Yes |

### Sample Run VMmare iso ###

	./cleanup.sh; packer build -force  fedora42srv_vmware.pkr.hcl >& log.txt
	 on fedora42srv_vmware.pkr.hcl line 10:
	 (source code not available)
	 {Warning: [WARN] 'vnc_over_websocket' enabled; other VNC configurations will be ignored.

	 vmware-iso.fedora42srv: output will be in this color.

	 ==> vmware-iso.fedora42srv: Retrieving ISO
	 ==> vmware-iso.fedora42srv: Trying https://dl.fedoraproject.org/pub/fedora/linux/releases/42/Server/x86_64/iso/Fedora-Server-dvd-x86_64-42-1.1.iso
	 ==> vmware-iso.fedora42srv: Trying https://dl.fedoraproject.org/pub/fedora/linux/releases/42/Server/x86_64/iso/Fedora-Server-dvd-x86_64-42-1.1.iso?checksum=sha256%3A7fee9ac23b932c6a8be36fc1e830e8bba5f83447b0f4c81fe2425620666a7043
		 vmware-iso.fedora42srv: Fedora-Server-dvd-x86_64-42-1.1.iso 93.39 KiB / 2.72 GiB [>-------------------------------------------------------------------------------------------------------]   0.00% 1h42m33s
		 vmware-iso.fedora42srv: Fedora-Server-dvd-x86_64-42-1.1.iso 429.33 KiB / 2.72 GiB [>--------------------------------------------------------------------------------------------------------]   0.02% 44m36s
		 vmware-iso.fedora42srv: Fedora-Server-dvd-x86_64-42-1.1.iso 2.69 GiB / 2.72 GiB [================================================================================================================>-]  98.63%
		 vmware-iso.fedora42srv: Fedora-Server-dvd-x86_64-42-1.1.iso 2.70 GiB / 2.72 GiB [================================================================================================================>-]  98.95%
		 vmware-iso.fedora42srv: Fedora-Server-dvd-x86_64-42-1.1.iso 2.70 GiB / 2.72 GiB [==================================================================================================================]  99.27%
		 vmware-iso.fedora42srv: Fedora-Server-dvd-x86_64-42-1.1.iso 2.71 GiB / 2.72 GiB [==================================================================================================================]  99.57%
		 vmware-iso.fedora42srv: Fedora-Server-dvd-x86_64-42-1.1.iso 2.72 GiB / 2.72 GiB [==================================================================================================================]  99.88%
		 vmware-iso.fedora42srv: Fedora-Server-dvd-x86_64-42-1.1.iso 2.72 GiB / 2.72 GiB [=============================================================================================================] 100.00% 1m4s
	 ==> vmware-iso.fedora42srv: https://dl.fedoraproject.org/pub/fedora/linux/releases/42/Server/x86_64/iso/Fedora-Server-dvd-x86_64-42-1.1.iso?checksum=sha256%3A7fee9ac23b932c6a8be36fc1e830e8bba5f83447b0f4c81fe2425620666a7043 => ./output-artifacts/iso/b9942652230ed0bdd2af7b94bdea1b41b2d3c33a.iso
	 ==> vmware-iso.fedora42srv: Configuring output and export directories...
	 ==> vmware-iso.fedora42srv: Creating temporary RSA SSH key for instance...
	 ==> vmware-iso.fedora42srv: Remote cache verified; skipping remote upload...
	 ==> vmware-iso.fedora42srv: Creating virtual machine disks...
	 ==> vmware-iso.fedora42srv: Generating the .vmx file...
	 ==> vmware-iso.fedora42srv: Starting HTTP server on port 8221
	 ==> vmware-iso.fedora42srv: Registering virtual machine on remote hypervisor...
	 ==> vmware-iso.fedora42srv: Powering on virtual machine...
	 ==> vmware-iso.fedora42srv: Connecting to VNC over websocket...
	 ==> vmware-iso.fedora42srv: Waiting 35s for boot...
	 ==> vmware-iso.fedora42srv: Typing the boot command over VNC...
	 ==> vmware-iso.fedora42srv: Waiting for SSH to become available...
	 ==> vmware-iso.fedora42srv: Connected to SSH!
	 ==> vmware-iso.fedora42srv: Provisioning with shell script: /var/folders/sw/fs5srh7d2g11p6q8bqbh0rnr0000gn/T/packer-shell4087844860
	 ==> vmware-iso.fedora42srv: Updating and loading repositories:
	 ==> vmware-iso.fedora42srv:  Fedora 42 - x86_64 - Updates           100% |   4.6 MiB/s |   9.3 MiB |  00m02s
	 ==> vmware-iso.fedora42srv:  Fedora 42 - x86_64                     100% |  12.5 MiB/s |  35.4 MiB |  00m03s
	 ==> vmware-iso.fedora42srv:  Fedora 42 openh264 (From Cisco) - x86_ 100% |   5.8 KiB/s |   5.8 KiB |  00m01s
	 ==> vmware-iso.fedora42srv: Repositories loaded.
	 ==> vmware-iso.fedora42srv: Package                                     Arch   Version                      Repository      Size
	 ==> vmware-iso.fedora42srv: Upgrading:
	 ==> vmware-iso.fedora42srv:  NetworkManager                             x86_64 1:1.52.1-1.fc42              updates      5.8 MiB
	 ==> vmware-iso.fedora42srv:    replacing NetworkManager                 x86_64 1:1.52.0-1.fc42              anaconda     5.8 MiB
	 ==> vmware-iso.fedora42srv:  NetworkManager-bluetooth                   x86_64 1:1.52.1-1.fc42              updates    101.1 KiB
	 ==> vmware-iso.fedora42srv:    replacing NetworkManager-bluetooth       x86_64 1:1.52.0-1.fc42              anaconda   101.1 KiB
	 ==> vmware-iso.fedora42srv:  NetworkManager-libnm                       x86_64 1:1.52.1-1.fc42              updates      9.9 MiB
	 ==> vmware-iso.fedora42srv:    replacing NetworkManager-libnm           x86_64 1:1.52.0-1.fc42              anaconda     9.9 MiB
	 ==> vmware-iso.fedora42srv:  NetworkManager-team                        x86_64 1:1.52.1-1.fc42              updates     52.1 KiB
	 ==> vmware-iso.fedora42srv:    replacing NetworkManager-team            x86_64 1:1.52.0-1.fc42              anaconda    52.1 KiB
	 ==> vmware-iso.fedora42srv:  NetworkManager-wifi                        x86_64 1:1.52.1-1.fc42              updates    321.1 KiB
	 ==> vmware-iso.fedora42srv:    replacing NetworkManager-wifi            x86_64 1:1.52.0-1.fc42              anaconda   321.1 KiB
	 ==> vmware-iso.fedora42srv:  NetworkManager-wwan                        x86_64 1:1.52.1-1.fc42              updates    137.0 KiB
	 ==> vmware-iso.fedora42srv:    replacing NetworkManager-wwan            x86_64 1:1.52.0-1.fc42              anaconda   141.0 KiB
	 ==> vmware-iso.fedora42srv: Total size of inbound packages is 710 MiB. Need to download 710 MiB.
	 ==> vmware-iso.fedora42srv: After this operation, 352 MiB extra will be used (install 1 GiB, remove 805 MiB).
	 ==> vmware-iso.fedora42srv:  alsa-sof-firmware                          noarch 2025.05.1-1.fc42             updates      9.8 MiB
	 ==> vmware-iso.fedora42srv:    replacing alsa-sof-firmware              noarch 2025.01-1.fc42               anaconda     8.6 MiB
	 ==> vmware-iso.fedora42srv:  alternatives                               x86_64 1.33-1.fc42                  updates     62.2 KiB
	 ==> vmware-iso.fedora42srv:    replacing alternatives                   x86_64 1.32-1.fc42                  anaconda    62.2 KiB
	 ==> vmware-iso.fedora42srv:  amd-gpu-firmware                           noarch 20251021-1.fc42              updates     25.7 MiB
	 ==> vmware-iso.fedora42srv:    replacing amd-gpu-firmware               noarch 20250311-1.fc42              anaconda    24.8 MiB
	 ==> vmware-iso.fedora42srv:  amd-ucode-firmware                         noarch 20251021-1.fc42              updates    419.9 KiB
	 ==> vmware-iso.fedora42srv:    replacing amd-ucode-firmware             noarch 20250311-1.fc42              anaconda   385.0 KiB
	 ==> vmware-iso.fedora42srv:  appstream                                  x86_64 1.1.0-1.fc42                 updates      4.3 MiB
	 ==> vmware-iso.fedora42srv:    replacing appstream                      x86_64 1.0.4-2.fc42                 anaconda     4.2 MiB
	 ==> vmware-iso.fedora42srv:  appstream-data                             noarch 42-8.fc42                    updates     15.2 MiB
	 ==> vmware-iso.fedora42srv:    replacing appstream-data                 noarch 42-7.fc42                    anaconda    15.0 MiB
	 ==> vmware-iso.fedora42srv:  at                                         x86_64 3.2.5-16.fc42                updates    121.7 KiB
	 ==> vmware-iso.fedora42srv:    replacing at                             x86_64 3.2.5-14.fc42                anaconda   121.7 KiB
	 ==> vmware-iso.fedora42srv:  atheros-firmware                           noarch 20251021-1.fc42              updates     40.9 MiB
	 ==> vmware-iso.fedora42srv:    replacing atheros-firmware               noarch 20250311-1.fc42              anaconda    36.5 MiB
	 ==> vmware-iso.fedora42srv:  audit                                      x86_64 4.1.2-2.fc42                 updates    500.5 KiB
	 ==> vmware-iso.fedora42srv:    replacing audit                          x86_64 4.0.3-2.fc42                 anaconda   486.2 KiB
	 ==> vmware-iso.fedora42srv:  audit-libs                                 x86_64 4.1.2-2.fc42                 updates    378.8 KiB
	 ==> vmware-iso.fedora42srv:    replacing audit-libs                     x86_64 4.0.3-2.fc42                 anaconda   351.3 KiB
	 ==> vmware-iso.fedora42srv:  audit-rules                                x86_64 4.1.2-2.fc42                 updates    113.0 KiB
	 ==> vmware-iso.fedora42srv:    replacing audit-rules                    x86_64 4.0.3-2.fc42                 anaconda   113.0 KiB
	 ==> vmware-iso.fedora42srv:  bash-color-prompt                          noarch 0.7.1-1.fc42                 updates     32.3 KiB
	 ==> vmware-iso.fedora42srv:    replacing bash-color-prompt              noarch 0.5-3.fc42                   anaconda    26.3 KiB
	 ==> vmware-iso.fedora42srv:  bind-libs                                  x86_64 32:9.18.41-1.fc42            updates      3.6 MiB
	 ==> vmware-iso.fedora42srv:    replacing bind-libs                      x86_64 32:9.18.33-1.fc42            anaconda     3.6 MiB
	 ==> vmware-iso.fedora42srv:  bind-utils                                 x86_64 32:9.18.41-1.fc42            updates    665.2 KiB
	 ==> vmware-iso.fedora42srv:    replacing bind-utils                     x86_64 32:9.18.33-1.fc42            anaconda   665.2 KiB
	 ==> vmware-iso.fedora42srv:  binutils                                   x86_64 2.44-6.fc42                  updates     25.8 MiB
	 ==> vmware-iso.fedora42srv:    replacing binutils                       x86_64 2.44-3.fc42                  anaconda    25.9 MiB
	 ==> vmware-iso.fedora42srv:  bluez                                      x86_64 5.84-2.fc42                  updates      3.5 MiB
	 ==> vmware-iso.fedora42srv:    replacing bluez                          x86_64 5.80-1.fc42                  anaconda     3.3 MiB
	 ==> vmware-iso.fedora42srv:  bluez-libs                                 x86_64 5.84-2.fc42                  updates    198.3 KiB
	 ==> vmware-iso.fedora42srv:    replacing bluez-libs                     x86_64 5.80-1.fc42                  anaconda   198.3 KiB
	 ==> vmware-iso.fedora42srv:  brcmfmac-firmware                          noarch 20251021-1.fc42              updates      9.5 MiB
	 ==> vmware-iso.fedora42srv:    replacing brcmfmac-firmware              noarch 20250311-1.fc42              anaconda     9.5 MiB
	 ==> vmware-iso.fedora42srv:  btrfs-progs                                x86_64 6.16.1-1.fc42                updates      6.3 MiB
	 ==> vmware-iso.fedora42srv:    replacing btrfs-progs                    x86_64 6.14-1.fc42                  anaconda     6.2 MiB
	 ==> vmware-iso.fedora42srv:  c-ares                                     x86_64 1.34.5-1.fc42                updates    269.1 KiB
	 ==> vmware-iso.fedora42srv:    replacing c-ares                         x86_64 1.34.4-3.fc42                anaconda   269.6 KiB
	 ==> vmware-iso.fedora42srv:  ca-certificates                            noarch 2025.2.80_v9.0.304-1.0.fc42  updates      2.7 MiB
	 ==> vmware-iso.fedora42srv:    replacing ca-certificates                noarch 2024.2.69_v8.0.401-5.fc42    anaconda     2.6 MiB
	 ==> vmware-iso.fedora42srv:  chrony                                     x86_64 4.8-1.fc42                   updates    689.9 KiB
	 ==> vmware-iso.fedora42srv:    replacing chrony                         x86_64 4.6.1-2.fc42                 anaconda   673.5 KiB
	 ==> vmware-iso.fedora42srv:  cirrus-audio-firmware                      noarch 20251021-1.fc42              updates      1.9 MiB
	 ==> vmware-iso.fedora42srv:    replacing cirrus-audio-firmware          noarch 20250311-1.fc42              anaconda     1.5 MiB
	 ==> vmware-iso.fedora42srv:  cockpit                                    x86_64 347-1.fc42                   updates     61.9 KiB
	 ==> vmware-iso.fedora42srv:    replacing cockpit                        x86_64 336.2-1.fc42                 anaconda    59.2 KiB
	 ==> vmware-iso.fedora42srv:  cockpit-bridge                             noarch 347-1.fc42                   updates      1.8 MiB
	 ==> vmware-iso.fedora42srv:    replacing cockpit-bridge                 noarch 336.2-1.fc42                 anaconda     1.8 MiB
	 ==> vmware-iso.fedora42srv:  cockpit-networkmanager                     noarch 347-1.fc42                   updates    798.2 KiB
	 ==> vmware-iso.fedora42srv:    replacing cockpit-networkmanager         noarch 336.2-1.fc42                 anaconda   780.4 KiB
	 ==> vmware-iso.fedora42srv:  cockpit-packagekit                         noarch 347-1.fc42                   updates    851.4 KiB
	 ==> vmware-iso.fedora42srv:    replacing cockpit-packagekit             noarch 336.2-1.fc42                 anaconda   821.6 KiB
	 ==> vmware-iso.fedora42srv:  cockpit-selinux                            noarch 347-1.fc42                   updates    420.4 KiB
	 ==> vmware-iso.fedora42srv:    replacing cockpit-selinux                noarch 336.2-1.fc42                 anaconda   377.5 KiB
	 ==> vmware-iso.fedora42srv:  cockpit-storaged                           noarch 347-1.fc42                   updates    804.9 KiB
	 ==> vmware-iso.fedora42srv:    replacing cockpit-storaged               noarch 336.2-1.fc42                 anaconda   788.6 KiB
	 ==> vmware-iso.fedora42srv:  cockpit-system                             noarch 347-1.fc42                   updates      3.0 MiB
	 ==> vmware-iso.fedora42srv:    replacing cockpit-system                 noarch 336.2-1.fc42                 anaconda     3.1 MiB
	 ==> vmware-iso.fedora42srv:  cockpit-ws                                 x86_64 347-1.fc42                   updates      1.8 MiB
	 ==> vmware-iso.fedora42srv:    replacing cockpit-ws                     x86_64 336.2-1.fc42                 anaconda     1.6 MiB
	 ==> vmware-iso.fedora42srv:  coreutils                                  x86_64 9.6-6.fc42                   updates      5.4 MiB
	 ==> vmware-iso.fedora42srv:    replacing coreutils                      x86_64 9.6-2.fc42                   anaconda     5.5 MiB
	 ==> vmware-iso.fedora42srv:  coreutils-common                           x86_64 9.6-6.fc42                   updates     11.1 MiB
	 ==> vmware-iso.fedora42srv:    replacing coreutils-common               x86_64 9.6-2.fc42                   anaconda    11.1 MiB
	 ==> vmware-iso.fedora42srv:  crypto-policies                            noarch 20250707-1.gitad370a8.fc42   updates    142.9 KiB
	 ==> vmware-iso.fedora42srv:    replacing crypto-policies                noarch 20250214-1.gitff7551b.fc42   anaconda   137.2 KiB
	 ==> vmware-iso.fedora42srv:  crypto-policies-scripts                    noarch 20250707-1.gitad370a8.fc42   updates    370.6 KiB
	 ==> vmware-iso.fedora42srv:    replacing crypto-policies-scripts        noarch 20250214-1.gitff7551b.fc42   anaconda   380.2 KiB
	 ==> vmware-iso.fedora42srv:  cryptsetup                                 x86_64 2.8.1-1.fc42                 updates    755.6 KiB
	 ==> vmware-iso.fedora42srv:    replacing cryptsetup                     x86_64 2.7.5-2.fc42                 anaconda   724.1 KiB
	 ==> vmware-iso.fedora42srv:  cryptsetup-libs                            x86_64 2.8.1-1.fc42                 updates      2.6 MiB
	 ==> vmware-iso.fedora42srv:    replacing cryptsetup-libs                x86_64 2.7.5-2.fc42                 anaconda     2.3 MiB
	 ==> vmware-iso.fedora42srv:  curl                                       x86_64 8.11.1-6.fc42                updates    450.6 KiB
	 ==> vmware-iso.fedora42srv:    replacing curl                           x86_64 8.11.1-4.fc42                anaconda   450.6 KiB
	 ==> vmware-iso.fedora42srv:  dbus-broker                                x86_64 36-6.fc42                    updates    387.1 KiB
	 ==> vmware-iso.fedora42srv:    replacing dbus-broker                    x86_64 36-5.fc42                    anaconda   395.1 KiB
	 ==> vmware-iso.fedora42srv:  diffutils                                  x86_64 3.12-1.fc42                  updates      1.6 MiB
	 ==> vmware-iso.fedora42srv:    replacing diffutils                      x86_64 3.10-9.fc42                  anaconda     1.6 MiB
	 ==> vmware-iso.fedora42srv:  dnf-data                                   noarch 4.24.0-1.fc42                updates     39.8 KiB
	 ==> vmware-iso.fedora42srv:    replacing dnf-data                       noarch 4.23.0-1.fc42                anaconda    39.4 KiB
	 ==> vmware-iso.fedora42srv:  dnf5                                       x86_64 5.2.17.0-1.fc42              updates      2.8 MiB
	 ==> vmware-iso.fedora42srv:    replacing dnf5                           x86_64 5.2.12.0-1.fc42              anaconda     2.3 MiB
	 ==> vmware-iso.fedora42srv:  dnf5-plugins                               x86_64 5.2.17.0-1.fc42              updates      1.3 MiB
	 ==> vmware-iso.fedora42srv:    replacing dnf5-plugins                   x86_64 5.2.12.0-1.fc42              anaconda     1.2 MiB
	 ==> vmware-iso.fedora42srv:  dnsmasq                                    x86_64 2.90-6.fc42                  updates    764.2 KiB
	 ==> vmware-iso.fedora42srv:    replacing dnsmasq                        x86_64 2.90-4.fc42                  anaconda   766.8 KiB
	 ==> vmware-iso.fedora42srv:  dracut                                     x86_64 107-4.fc42                   updates      1.6 MiB
	 ==> vmware-iso.fedora42srv:    replacing dracut                         x86_64 105-2.fc42                   anaconda     1.9 MiB
	 ==> vmware-iso.fedora42srv:  dracut-config-rescue                       x86_64 107-4.fc42                   updates      4.5 KiB
	 ==> vmware-iso.fedora42srv:    replacing dracut-config-rescue           x86_64 105-2.fc42                   anaconda     4.5 KiB
	 ==> vmware-iso.fedora42srv:  elfutils                                   x86_64 0.194-1.fc42                 updates      2.9 MiB
	 ==> vmware-iso.fedora42srv:    replacing elfutils                       x86_64 0.192-9.fc42                 anaconda     2.6 MiB
	 ==> vmware-iso.fedora42srv:  elfutils-debuginfod-client                 x86_64 0.194-1.fc42                 updates     83.9 KiB
	 ==> vmware-iso.fedora42srv:    replacing elfutils-debuginfod-client     x86_64 0.192-9.fc42                 anaconda    79.9 KiB
	 ==> vmware-iso.fedora42srv:  elfutils-default-yama-scope                noarch 0.194-1.fc42                 updates      1.8 KiB
	 ==> vmware-iso.fedora42srv:    replacing elfutils-default-yama-scope    noarch 0.192-9.fc42                 anaconda     1.8 KiB
	 ==> vmware-iso.fedora42srv:  elfutils-libelf                            x86_64 0.194-1.fc42                 updates      1.1 MiB
	 ==> vmware-iso.fedora42srv:    replacing elfutils-libelf                x86_64 0.192-9.fc42                 anaconda     1.2 MiB
	 ==> vmware-iso.fedora42srv:  elfutils-libs                              x86_64 0.194-1.fc42                 updates    687.4 KiB
	 ==> vmware-iso.fedora42srv:    replacing elfutils-libs                  x86_64 0.192-9.fc42                 anaconda   667.0 KiB
	 ==> vmware-iso.fedora42srv:  ethtool                                    x86_64 2:6.15-3.fc42                updates    996.4 KiB
	 ==> vmware-iso.fedora42srv:    replacing ethtool                        x86_64 2:6.11-2.fc42                anaconda   688.4 KiB
	 ==> vmware-iso.fedora42srv:  exfatprogs                                 x86_64 1.3.0-1.fc42                 updates    292.9 KiB
	 ==> vmware-iso.fedora42srv:    replacing exfatprogs                     x86_64 1.2.8-1.fc42                 anaconda   242.8 KiB
	 ==> vmware-iso.fedora42srv:  expat                                      x86_64 2.7.2-1.fc42                 updates    298.6 KiB
	 ==> vmware-iso.fedora42srv:    replacing expat                          x86_64 2.7.1-1.fc42                 anaconda   290.2 KiB
	 ==> vmware-iso.fedora42srv:  fedora-release-common                      noarch 42-30                        updates     20.2 KiB
	 ==> vmware-iso.fedora42srv:    replacing fedora-release-common          noarch 42-25                        anaconda    20.1 KiB
	 ==> vmware-iso.fedora42srv:  fedora-release-identity-server             noarch 42-30                        updates      2.1 KiB
	 ==> vmware-iso.fedora42srv:    replacing fedora-release-identity-server noarch 42-25                        anaconda     2.1 KiB
	 ==> vmware-iso.fedora42srv:  fedora-release-server                      noarch 42-30                        updates      0.0   B
	 ==> vmware-iso.fedora42srv:    replacing fedora-release-server          noarch 42-25                        anaconda     0.0   B
	 ==> vmware-iso.fedora42srv:  file                                       x86_64 5.46-3.fc42                  updates    100.2 KiB
	 ==> vmware-iso.fedora42srv:    replacing file                           x86_64 5.46-1.fc42                  anaconda   100.2 KiB
	 ==> vmware-iso.fedora42srv:  file-libs                                  x86_64 5.46-3.fc42                  updates     11.9 MiB
	 ==> vmware-iso.fedora42srv:    replacing file-libs                      x86_64 5.46-1.fc42                  anaconda    11.9 MiB
	 ==> vmware-iso.fedora42srv:  filesystem                                 x86_64 3.18-47.fc42                 updates    112.0   B
	 ==> vmware-iso.fedora42srv:    replacing filesystem                     x86_64 3.18-36.fc42                 anaconda   112.0   B
	 ==> vmware-iso.fedora42srv:  firewalld                                  noarch 2.3.1-1.fc42                 updates      2.0 MiB
	 ==> vmware-iso.fedora42srv:    replacing firewalld                      noarch 2.3.0-4.fc42                 anaconda     2.0 MiB
	 ==> vmware-iso.fedora42srv:  firewalld-filesystem                       noarch 2.3.1-1.fc42                 updates    239.0   B
	 ==> vmware-iso.fedora42srv:    replacing firewalld-filesystem           noarch 2.3.0-4.fc42                 anaconda   239.0   B
	 ==> vmware-iso.fedora42srv:  fonts-filesystem                           noarch 1:2.0.5-22.fc42              updates      0.0   B
	 ==> vmware-iso.fedora42srv:    replacing fonts-filesystem               noarch 1:2.0.5-21.fc42              anaconda     0.0   B
	 ==> vmware-iso.fedora42srv:  fprintd                                    x86_64 1.94.5-1.fc42                updates    829.9 KiB
	 ==> vmware-iso.fedora42srv:    replacing fprintd                        x86_64 1.94.4-2.fc42                anaconda   845.9 KiB
	 ==> vmware-iso.fedora42srv:  fprintd-pam                                x86_64 1.94.5-1.fc42                updates     30.4 KiB
	 ==> vmware-iso.fedora42srv:    replacing fprintd-pam                    x86_64 1.94.4-2.fc42                anaconda    34.3 KiB
	 ==> vmware-iso.fedora42srv:  fwupd                                      x86_64 2.0.16-1.fc42                updates      9.1 MiB
	 ==> vmware-iso.fedora42srv:    replacing fwupd                          x86_64 2.0.7-2.fc42                 anaconda     8.6 MiB
	 ==> vmware-iso.fedora42srv:  gdb-headless                               x86_64 16.3-1.fc42                  updates     15.7 MiB
	 ==> vmware-iso.fedora42srv:    replacing gdb-headless                   x86_64 16.2-3.fc42                  anaconda    15.7 MiB
	 ==> vmware-iso.fedora42srv:  glib2                                      x86_64 2.84.4-1.fc42                updates     14.7 MiB
	 ==> vmware-iso.fedora42srv:    replacing glib2                          x86_64 2.84.0-1.fc42                anaconda    14.7 MiB
	 ==> vmware-iso.fedora42srv:  glibc                                      x86_64 2.41-11.fc42                 updates      6.6 MiB
	 ==> vmware-iso.fedora42srv:    replacing glibc                          x86_64 2.41-1.fc42                  anaconda     6.6 MiB
	 ==> vmware-iso.fedora42srv:  glibc-common                               x86_64 2.41-11.fc42                 updates      1.0 MiB
	 ==> vmware-iso.fedora42srv:    replacing glibc-common                   x86_64 2.41-1.fc42                  anaconda     1.0 MiB
	 ==> vmware-iso.fedora42srv:  glibc-gconv-extra                          x86_64 2.41-11.fc42                 updates      7.2 MiB
	 ==> vmware-iso.fedora42srv:    replacing glibc-gconv-extra              x86_64 2.41-1.fc42                  anaconda     7.2 MiB
	 ==> vmware-iso.fedora42srv:  glibc-langpack-en                          x86_64 2.41-11.fc42                 updates      5.7 MiB
	 ==> vmware-iso.fedora42srv:    replacing glibc-langpack-en              x86_64 2.41-1.fc42                  anaconda     5.7 MiB
	 ==> vmware-iso.fedora42srv:  gnutls                                     x86_64 3.8.10-1.fc42                updates      3.8 MiB
	 ==> vmware-iso.fedora42srv:    replacing gnutls                         x86_64 3.8.9-3.fc42                 anaconda     3.6 MiB
	 ==> vmware-iso.fedora42srv:  gnutls-dane                                x86_64 3.8.10-1.fc42                updates     60.9 KiB
	 ==> vmware-iso.fedora42srv:    replacing gnutls-dane                    x86_64 3.8.9-3.fc42                 anaconda    69.3 KiB
	 ==> vmware-iso.fedora42srv:  gpgme                                      x86_64 1.24.3-1.fc42                updates    587.9 KiB
	 ==> vmware-iso.fedora42srv:    replacing gpgme                          x86_64 1.24.2-1.fc42                anaconda   591.4 KiB
	 ==> vmware-iso.fedora42srv:  grub2-common                               noarch 1:2.12-32.fc42               updates      6.1 MiB
	 ==> vmware-iso.fedora42srv:    replacing grub2-common                   noarch 1:2.12-28.fc42               anaconda     6.1 MiB
	 ==> vmware-iso.fedora42srv:  grub2-pc                                   x86_64 1:2.12-32.fc42               updates     31.0   B
	 ==> vmware-iso.fedora42srv:    replacing grub2-pc                       x86_64 1:2.12-28.fc42               anaconda    31.0   B
	 ==> vmware-iso.fedora42srv:  grub2-pc-modules                           noarch 1:2.12-32.fc42               updates      3.2 MiB
	 ==> vmware-iso.fedora42srv:    replacing grub2-pc-modules               noarch 1:2.12-28.fc42               anaconda     3.2 MiB
	 ==> vmware-iso.fedora42srv:  grub2-tools                                x86_64 1:2.12-32.fc42               updates      7.7 MiB
	 ==> vmware-iso.fedora42srv:    replacing grub2-tools                    x86_64 1:2.12-28.fc42               anaconda     7.7 MiB
	 ==> vmware-iso.fedora42srv:  grub2-tools-minimal                        x86_64 1:2.12-32.fc42               updates      3.0 MiB
	 ==> vmware-iso.fedora42srv:    replacing grub2-tools-minimal            x86_64 1:2.12-28.fc42               anaconda     3.0 MiB
	 ==> vmware-iso.fedora42srv:  hwdata                                     noarch 0.400-1.fc42                 updates      9.6 MiB
	 ==> vmware-iso.fedora42srv:    replacing hwdata                         noarch 0.393-1.fc42                 anaconda     9.4 MiB
	 ==> vmware-iso.fedora42srv:  inih                                       x86_64 62-1.fc42                    updates     22.4 KiB
	 ==> vmware-iso.fedora42srv:    replacing inih                           x86_64 58-3.fc42                    anaconda    26.4 KiB
	 ==> vmware-iso.fedora42srv:  intel-audio-firmware                       noarch 20251021-1.fc42              updates      3.3 MiB
	 ==> vmware-iso.fedora42srv:    replacing intel-audio-firmware           noarch 20250311-1.fc42              anaconda     3.3 MiB
	 ==> vmware-iso.fedora42srv:  intel-gpu-firmware                         noarch 20251021-1.fc42              updates      8.8 MiB
	 ==> vmware-iso.fedora42srv:    replacing intel-gpu-firmware             noarch 20250311-1.fc42              anaconda     8.7 MiB
	 ==> vmware-iso.fedora42srv:  intel-vsc-firmware                         noarch 20251021-1.fc42              updates      7.7 MiB
	 ==> vmware-iso.fedora42srv:    replacing intel-vsc-firmware             noarch 20250311-1.fc42              anaconda     7.5 MiB
	 ==> vmware-iso.fedora42srv:  iptables-libs                              x86_64 1.8.11-9.fc42                updates      1.5 MiB
	 ==> vmware-iso.fedora42srv:    replacing iptables-libs                  x86_64 1.8.11-4.fc42                anaconda     1.8 MiB
	 ==> vmware-iso.fedora42srv:  iptables-nft                               x86_64 1.8.11-9.fc42                updates    465.6 KiB
	 ==> vmware-iso.fedora42srv:    replacing iptables-nft                   x86_64 1.8.11-4.fc42                anaconda   537.5 KiB
	 ==> vmware-iso.fedora42srv:  iputils                                    x86_64 20250605-1.fc42              updates    828.4 KiB
	 ==> vmware-iso.fedora42srv:    replacing iputils                        x86_64 20240905-3.fc42              anaconda   760.8 KiB
	 ==> vmware-iso.fedora42srv:  iscsi-initiator-utils                      x86_64 6.2.1.11-0.git4b3e853.fc42   updates      1.4 MiB
	 ==> vmware-iso.fedora42srv:    replacing iscsi-initiator-utils          x86_64 6.2.1.10-0.gitd0f04ae.fc41.1 anaconda     1.4 MiB
	 ==> vmware-iso.fedora42srv:  iscsi-initiator-utils-iscsiuio             x86_64 6.2.1.11-0.git4b3e853.fc42   updates    163.4 KiB
	 ==> vmware-iso.fedora42srv:    replacing iscsi-initiator-utils-iscsiuio x86_64 6.2.1.10-0.gitd0f04ae.fc41.1 anaconda   163.7 KiB
	 ==> vmware-iso.fedora42srv:  iwlegacy-firmware                          noarch 20251021-1.fc42              updates    123.2 KiB
	 ==> vmware-iso.fedora42srv:    replacing iwlegacy-firmware              noarch 20250311-1.fc42              anaconda   123.1 KiB
	 ==> vmware-iso.fedora42srv:  iwlwifi-dvm-firmware                       noarch 20251021-1.fc42              updates      1.8 MiB
	 ==> vmware-iso.fedora42srv:    replacing iwlwifi-dvm-firmware           noarch 20250311-1.fc42              anaconda     1.8 MiB
	 ==> vmware-iso.fedora42srv:  iwlwifi-mvm-firmware                       noarch 20251021-1.fc42              updates     62.7 MiB
	 ==> vmware-iso.fedora42srv:    replacing iwlwifi-mvm-firmware           noarch 20250311-1.fc42              anaconda    61.7 MiB
	 ==> vmware-iso.fedora42srv:  json-glib                                  x86_64 1.10.8-1.fc42                updates    592.3 KiB
	 ==> vmware-iso.fedora42srv:    replacing json-glib                      x86_64 1.10.6-2.fc42                anaconda   590.7 KiB
	 ==> vmware-iso.fedora42srv:  kexec-tools                                x86_64 2.0.32-1.fc42                updates    229.4 KiB
	 ==> vmware-iso.fedora42srv:    replacing kexec-tools                    x86_64 2.0.30-3.fc42                anaconda   233.4 KiB
	 ==> vmware-iso.fedora42srv:  krb5-libs                                  x86_64 1.21.3-6.fc42                updates      2.3 MiB
	 ==> vmware-iso.fedora42srv:    replacing krb5-libs                      x86_64 1.21.3-5.fc42                anaconda     2.3 MiB
	 ==> vmware-iso.fedora42srv:  less                                       x86_64 679-1.fc42                   updates    406.1 KiB
	 ==> vmware-iso.fedora42srv:    replacing less                           x86_64 668-2.fc42                   anaconda   405.8 KiB
	 ==> vmware-iso.fedora42srv:  libarchive                                 x86_64 3.8.1-1.fc42                 updates    955.2 KiB
	 ==> vmware-iso.fedora42srv:    replacing libarchive                     x86_64 3.7.7-4.fc42                 anaconda   930.6 KiB
	 ==> vmware-iso.fedora42srv:  libblockdev                                x86_64 3.3.1-2.fc42                 updates    370.7 KiB
	 ==> vmware-iso.fedora42srv:    replacing libblockdev                    x86_64 3.3.0-3.fc42                 anaconda   370.7 KiB
	 ==> vmware-iso.fedora42srv:  libblockdev-crypto                         x86_64 3.3.1-2.fc42                 updates     67.6 KiB
	 ==> vmware-iso.fedora42srv:    replacing libblockdev-crypto             x86_64 3.3.0-3.fc42                 anaconda    67.6 KiB
	 ==> vmware-iso.fedora42srv:  libblockdev-fs                             x86_64 3.3.1-2.fc42                 updates    108.6 KiB
	 ==> vmware-iso.fedora42srv:    replacing libblockdev-fs                 x86_64 3.3.0-3.fc42                 anaconda   108.6 KiB
	 ==> vmware-iso.fedora42srv:  libblockdev-loop                           x86_64 3.3.1-2.fc42                 updates     19.5 KiB
	 ==> vmware-iso.fedora42srv:    replacing libblockdev-loop               x86_64 3.3.0-3.fc42                 anaconda    19.5 KiB
	 ==> vmware-iso.fedora42srv:  libblockdev-lvm                            x86_64 3.3.1-2.fc42                 updates     72.3 KiB
	 ==> vmware-iso.fedora42srv:    replacing libblockdev-lvm                x86_64 3.3.0-3.fc42                 anaconda    72.3 KiB
	 ==> vmware-iso.fedora42srv:  libblockdev-mdraid                         x86_64 3.3.1-2.fc42                 updates     31.7 KiB
	 ==> vmware-iso.fedora42srv:    replacing libblockdev-mdraid             x86_64 3.3.0-3.fc42                 anaconda    31.7 KiB
	 ==> vmware-iso.fedora42srv:  libblockdev-nvme                           x86_64 3.3.1-2.fc42                 updates     47.4 KiB
	 ==> vmware-iso.fedora42srv:    replacing libblockdev-nvme               x86_64 3.3.0-3.fc42                 anaconda    47.4 KiB
	 ==> vmware-iso.fedora42srv:  libblockdev-part                           x86_64 3.3.1-2.fc42                 updates     43.4 KiB
	 ==> vmware-iso.fedora42srv:    replacing libblockdev-part               x86_64 3.3.0-3.fc42                 anaconda    43.4 KiB
	 ==> vmware-iso.fedora42srv:  libblockdev-smart                          x86_64 3.3.1-2.fc42                 updates     39.3 KiB
	 ==> vmware-iso.fedora42srv:    replacing libblockdev-smart              x86_64 3.3.0-3.fc42                 anaconda    39.3 KiB
	 ==> vmware-iso.fedora42srv:  libblockdev-swap                           x86_64 3.3.1-2.fc42                 updates     19.5 KiB
	 ==> vmware-iso.fedora42srv:    replacing libblockdev-swap               x86_64 3.3.0-3.fc42                 anaconda    19.5 KiB
	 ==> vmware-iso.fedora42srv:  libblockdev-utils                          x86_64 3.3.1-2.fc42                 updates     43.6 KiB
	 ==> vmware-iso.fedora42srv:    replacing libblockdev-utils              x86_64 3.3.0-3.fc42                 anaconda    43.6 KiB
	 ==> vmware-iso.fedora42srv:  libcomps                                   x86_64 0.1.22-1.fc42                updates    205.3 KiB
	 ==> vmware-iso.fedora42srv:    replacing libcomps                       x86_64 0.1.21-5.fc42                anaconda   209.3 KiB
	 ==> vmware-iso.fedora42srv:  libcurl                                    x86_64 8.11.1-6.fc42                updates    834.1 KiB
	 ==> vmware-iso.fedora42srv:    replacing libcurl                        x86_64 8.11.1-4.fc42                anaconda   842.1 KiB
	 ==> vmware-iso.fedora42srv:  libdnf                                     x86_64 0.75.0-1.fc42                updates      2.2 MiB
	 ==> vmware-iso.fedora42srv:    replacing libdnf                         x86_64 0.74.0-1.fc42                anaconda     2.2 MiB
	 ==> vmware-iso.fedora42srv:  libdnf5                                    x86_64 5.2.17.0-1.fc42              updates      3.8 MiB
	 ==> vmware-iso.fedora42srv:    replacing libdnf5                        x86_64 5.2.12.0-1.fc42              anaconda     3.6 MiB
	 ==> vmware-iso.fedora42srv:  libdnf5-cli                                x86_64 5.2.17.0-1.fc42              updates    920.8 KiB
	 ==> vmware-iso.fedora42srv:    replacing libdnf5-cli                    x86_64 5.2.12.0-1.fc42              anaconda   867.6 KiB
	 ==> vmware-iso.fedora42srv:  libdrm                                     x86_64 2.4.127-3.fc42               updates    399.8 KiB
	 ==> vmware-iso.fedora42srv:    replacing libdrm                         x86_64 2.4.124-2.fc42               anaconda   407.9 KiB
	 ==> vmware-iso.fedora42srv:  libeconf                                   x86_64 0.7.6-2.fc42                 updates     64.6 KiB
	 ==> vmware-iso.fedora42srv:    replacing libeconf                       x86_64 0.7.6-1.fc42                 anaconda    64.6 KiB
	 ==> vmware-iso.fedora42srv:  libedit                                    x86_64 3.1-56.20251016cvs.fc42      updates    240.2 KiB
	 ==> vmware-iso.fedora42srv:    replacing libedit                        x86_64 3.1-55.20250104cvs.fc42      anaconda   244.1 KiB
	 ==> vmware-iso.fedora42srv:  libertas-firmware                          noarch 20251021-1.fc42              updates      1.3 MiB
	 ==> vmware-iso.fedora42srv:    replacing libertas-firmware              noarch 20250311-1.fc42              anaconda     1.3 MiB
	 ==> vmware-iso.fedora42srv:  libgcc                                     x86_64 15.2.1-3.fc42                updates    266.6 KiB
	 ==> vmware-iso.fedora42srv:    replacing libgcc                         x86_64 15.0.1-0.11.fc42             anaconda   266.6 KiB
	 ==> vmware-iso.fedora42srv:  libgomp                                    x86_64 15.2.1-3.fc42                updates    541.6 KiB
	 ==> vmware-iso.fedora42srv:    replacing libgomp                        x86_64 15.0.1-0.11.fc42             anaconda   537.6 KiB
	 ==> vmware-iso.fedora42srv:  libjcat                                    x86_64 0.2.5-1.fc42                 updates    213.8 KiB
	 ==> vmware-iso.fedora42srv:    replacing libjcat                        x86_64 0.2.3-1.fc42                 anaconda   209.6 KiB
	 ==> vmware-iso.fedora42srv:  libldb                                     x86_64 2:4.22.6-1.fc42              updates    450.8 KiB
	 ==> vmware-iso.fedora42srv:    replacing libldb                         x86_64 2:4.22.0-20.fc42             anaconda   451.7 KiB
	 ==> vmware-iso.fedora42srv:  libmodulemd                                x86_64 2.15.2-1.fc42                updates    717.7 KiB
	 ==> vmware-iso.fedora42srv:    replacing libmodulemd                    x86_64 2.15.0-16.fc42               anaconda   721.0 KiB
	 ==> vmware-iso.fedora42srv:  libnfsidmap                                x86_64 1:2.8.4-0.fc42               updates    168.2 KiB
	 ==> vmware-iso.fedora42srv:    replacing libnfsidmap                    x86_64 1:2.8.2-1.rc8.fc42           anaconda   168.2 KiB
	 ==> vmware-iso.fedora42srv:  libnvme                                    x86_64 1.15-2.fc42                  updates    301.8 KiB
	 ==> vmware-iso.fedora42srv:    replacing libnvme                        x86_64 1.12-1.fc42                  anaconda   293.5 KiB
	 ==> vmware-iso.fedora42srv:  librepo                                    x86_64 1.20.0-1.fc42                updates    249.0 KiB
	 ==> vmware-iso.fedora42srv:    replacing librepo                        x86_64 1.19.0-3.fc42                anaconda   244.9 KiB
	 ==> vmware-iso.fedora42srv:  libselinux                                 x86_64 3.8-3.fc42                   updates    193.1 KiB
	 ==> vmware-iso.fedora42srv:    replacing libselinux                     x86_64 3.8-1.fc42                   anaconda   193.1 KiB
	 ==> vmware-iso.fedora42srv:  libselinux-utils                           x86_64 3.8-3.fc42                   updates    309.1 KiB
	 ==> vmware-iso.fedora42srv:    replacing libselinux-utils               x86_64 3.8-1.fc42                   anaconda   309.1 KiB
	 ==> vmware-iso.fedora42srv:  libsemanage                                x86_64 3.8.1-2.fc42                 updates    304.4 KiB
	 ==> vmware-iso.fedora42srv:    replacing libsemanage                    x86_64 3.8-1.fc42                   anaconda   308.4 KiB
	 ==> vmware-iso.fedora42srv:  libsolv                                    x86_64 0.7.35-1.fc42                updates    971.3 KiB
	 ==> vmware-iso.fedora42srv:    replacing libsolv                        x86_64 0.7.31-5.fc42                anaconda   940.4 KiB
	 ==> vmware-iso.fedora42srv:  libssh                                     x86_64 0.11.3-1.fc42                updates    567.1 KiB
	 ==> vmware-iso.fedora42srv:    replacing libssh                         x86_64 0.11.1-4.fc42                anaconda   565.5 KiB
	 ==> vmware-iso.fedora42srv:  libssh-config                              noarch 0.11.3-1.fc42                updates    277.0   B
	 ==> vmware-iso.fedora42srv:    replacing libssh-config                  noarch 0.11.1-4.fc42                anaconda   277.0   B
	 ==> vmware-iso.fedora42srv:  libsss_certmap                             x86_64 2.11.1-2.fc42                updates    132.8 KiB
	 ==> vmware-iso.fedora42srv:    replacing libsss_certmap                 x86_64 2.10.2-3.fc42                anaconda   140.3 KiB
	 ==> vmware-iso.fedora42srv:  libsss_idmap                               x86_64 2.11.1-2.fc42                updates     73.9 KiB
	 ==> vmware-iso.fedora42srv:    replacing libsss_idmap                   x86_64 2.10.2-3.fc42                anaconda    73.7 KiB
	 ==> vmware-iso.fedora42srv:  libsss_nss_idmap                           x86_64 2.11.1-2.fc42                updates     82.2 KiB
	 ==> vmware-iso.fedora42srv:    replacing libsss_nss_idmap               x86_64 2.10.2-3.fc42                anaconda    82.2 KiB
	 ==> vmware-iso.fedora42srv:  libsss_sudo                                x86_64 2.11.1-2.fc42                updates     53.8 KiB
	 ==> vmware-iso.fedora42srv:    replacing libsss_sudo                    x86_64 2.10.2-3.fc42                anaconda    53.8 KiB
	 ==> vmware-iso.fedora42srv:  libstdc++                                  x86_64 15.2.1-3.fc42                updates      2.8 MiB
	 ==> vmware-iso.fedora42srv:    replacing libstdc++                      x86_64 15.0.1-0.11.fc42             anaconda     2.8 MiB
	 ==> vmware-iso.fedora42srv:  libtirpc                                   x86_64 1.3.7-1.fc42                 updates    200.4 KiB
	 ==> vmware-iso.fedora42srv:    replacing libtirpc                       x86_64 1.3.6-1.rc3.fc42.2           anaconda   199.0 KiB
	 ==> vmware-iso.fedora42srv:  libudisks2                                 x86_64 2.10.91-1.fc42               updates      1.0 MiB
	 ==> vmware-iso.fedora42srv:    replacing libudisks2                     x86_64 2.10.90-2.fc42               anaconda     1.0 MiB
	 ==> vmware-iso.fedora42srv:  libusb1                                    x86_64 1.0.29-4.fc42                updates    171.3 KiB
	 ==> vmware-iso.fedora42srv:    replacing libusb1                        x86_64 1.0.28-2.fc42                anaconda   171.0 KiB
	 ==> vmware-iso.fedora42srv:  libuv                                      x86_64 1:1.51.0-1.fc42              updates    570.2 KiB
	 ==> vmware-iso.fedora42srv:    replacing libuv                          x86_64 1:1.50.0-1.fc42              anaconda   566.8 KiB
	 ==> vmware-iso.fedora42srv:  libwbclient                                x86_64 2:4.22.6-1.fc42              updates     68.6 KiB
	 ==> vmware-iso.fedora42srv:    replacing libwbclient                    x86_64 2:4.22.0-20.fc42             anaconda    69.3 KiB
	 ==> vmware-iso.fedora42srv:  libxcrypt                                  x86_64 4.4.38-7.fc42                updates    284.5 KiB
	 ==> vmware-iso.fedora42srv:    replacing libxcrypt                      x86_64 4.4.38-6.fc42                anaconda   284.5 KiB
	 ==> vmware-iso.fedora42srv:  libxmlb                                    x86_64 0.3.24-1.fc42                updates    280.3 KiB
	 ==> vmware-iso.fedora42srv:    replacing libxmlb                        x86_64 0.3.22-1.fc42                anaconda   280.4 KiB
	 ==> vmware-iso.fedora42srv:  linux-firmware                             noarch 20251021-1.fc42              updates     41.8 MiB
	 ==> vmware-iso.fedora42srv:    replacing linux-firmware                 noarch 20250311-1.fc42              anaconda    39.9 MiB
	 ==> vmware-iso.fedora42srv:  linux-firmware-whence                      noarch 20251021-1.fc42              updates    347.8 KiB
	 ==> vmware-iso.fedora42srv:    replacing linux-firmware-whence          noarch 20250311-1.fc42              anaconda   316.2 KiB
	 ==> vmware-iso.fedora42srv:  lua-libs                                   x86_64 5.4.8-1.fc42                 updates    280.8 KiB
	 ==> vmware-iso.fedora42srv:    replacing lua-libs                       x86_64 5.4.7-3.fc42                 anaconda   280.8 KiB
	 ==> vmware-iso.fedora42srv:  mdadm                                      x86_64 4.3-8.fc42                   updates      1.0 MiB
	 ==> vmware-iso.fedora42srv:    replacing mdadm                          x86_64 4.3-7.fc42                   anaconda     1.0 MiB
	 ==> vmware-iso.fedora42srv:  microcode_ctl                              x86_64 2:2.1-70.fc42                updates     14.4 MiB
	 ==> vmware-iso.fedora42srv:    replacing microcode_ctl                  x86_64 2:2.1-69.fc42                anaconda    11.4 MiB
	 ==> vmware-iso.fedora42srv:  mpdecimal                                  x86_64 4.0.1-1.fc42                 updates    217.2 KiB
	 ==> vmware-iso.fedora42srv:    replacing mpdecimal                      x86_64 4.0.0-2.fc42                 anaconda   216.8 KiB
	 ==> vmware-iso.fedora42srv:  mt7xxx-firmware                            noarch 20251021-1.fc42              updates     18.5 MiB
	 ==> vmware-iso.fedora42srv:    replacing mt7xxx-firmware                noarch 20250311-1.fc42              anaconda    20.2 MiB
	 ==> vmware-iso.fedora42srv:  nfs-utils                                  x86_64 1:2.8.4-0.fc42               updates      1.3 MiB
	 ==> vmware-iso.fedora42srv:    replacing nfs-utils                      x86_64 1:2.8.2-1.rc8.fc42           anaconda     1.2 MiB
	 ==> vmware-iso.fedora42srv:  nspr                                       x86_64 4.37.0-4.fc42                updates    315.5 KiB
	 ==> vmware-iso.fedora42srv:    replacing nspr                           x86_64 4.36.0-5.fc42                anaconda   315.5 KiB
	 ==> vmware-iso.fedora42srv:  nss                                        x86_64 3.117.0-1.fc42               updates      1.9 MiB
	 ==> vmware-iso.fedora42srv:    replacing nss                            x86_64 3.109.0-1.fc42               anaconda     1.9 MiB
	 ==> vmware-iso.fedora42srv:  nss-softokn                                x86_64 3.117.0-1.fc42               updates      2.0 MiB
	 ==> vmware-iso.fedora42srv:    replacing nss-softokn                    x86_64 3.109.0-1.fc42               anaconda     1.9 MiB
	 ==> vmware-iso.fedora42srv:  nss-softokn-freebl                         x86_64 3.117.0-1.fc42               updates    848.4 KiB
	 ==> vmware-iso.fedora42srv:    replacing nss-softokn-freebl             x86_64 3.109.0-1.fc42               anaconda   852.4 KiB
	 ==> vmware-iso.fedora42srv:  nss-sysinit                                x86_64 3.117.0-1.fc42               updates     18.1 KiB
	 ==> vmware-iso.fedora42srv:    replacing nss-sysinit                    x86_64 3.109.0-1.fc42               anaconda    18.1 KiB
	 ==> vmware-iso.fedora42srv:  nss-util                                   x86_64 3.117.0-1.fc42               updates    204.8 KiB
	 ==> vmware-iso.fedora42srv:    replacing nss-util                       x86_64 3.109.0-1.fc42               anaconda   204.8 KiB
	 ==> vmware-iso.fedora42srv:  ntfs-3g                                    x86_64 2:2022.10.3-9.fc42           updates    312.3 KiB
	 ==> vmware-iso.fedora42srv:    replacing ntfs-3g                        x86_64 2:2022.10.3-8.fc42           anaconda   316.3 KiB
	 ==> vmware-iso.fedora42srv:  ntfs-3g-libs                               x86_64 2:2022.10.3-9.fc42           updates    364.8 KiB
	 ==> vmware-iso.fedora42srv:    replacing ntfs-3g-libs                   x86_64 2:2022.10.3-8.fc42           anaconda   364.8 KiB
	 ==> vmware-iso.fedora42srv:  ntfsprogs                                  x86_64 2:2022.10.3-9.fc42           updates    995.4 KiB
	 ==> vmware-iso.fedora42srv:    replacing ntfsprogs                      x86_64 2:2022.10.3-8.fc42           anaconda   995.4 KiB
	 ==> vmware-iso.fedora42srv:  nvidia-gpu-firmware                        noarch 20251021-1.fc42              updates    101.0 MiB
	 ==> vmware-iso.fedora42srv:    replacing nvidia-gpu-firmware            noarch 20250311-1.fc42              anaconda    37.9 MiB
	 ==> vmware-iso.fedora42srv:  nxpwireless-firmware                       noarch 20251021-1.fc42              updates    905.2 KiB
	 ==> vmware-iso.fedora42srv:    replacing nxpwireless-firmware           noarch 20250311-1.fc42              anaconda   905.2 KiB
	 ==> vmware-iso.fedora42srv:  open-vm-tools                              x86_64 13.0.0-1.fc42                updates      3.0 MiB
	 ==> vmware-iso.fedora42srv:    replacing open-vm-tools                  x86_64 12.4.0-4.fc42                anaconda     3.1 MiB
	 ==> vmware-iso.fedora42srv:  openldap                                   x86_64 2.6.10-1.fc42                updates    655.8 KiB
	 ==> vmware-iso.fedora42srv:    replacing openldap                       x86_64 2.6.9-3.fc42                 anaconda   655.1 KiB
	 ==> vmware-iso.fedora42srv:  opensc                                     x86_64 0.26.1-3.fc42                updates      1.2 MiB
	 ==> vmware-iso.fedora42srv:    replacing opensc                         x86_64 0.26.1-2.fc42                anaconda     1.2 MiB
	 ==> vmware-iso.fedora42srv:  opensc-libs                                x86_64 0.26.1-3.fc42                updates      2.3 MiB
	 ==> vmware-iso.fedora42srv:    replacing opensc-libs                    x86_64 0.26.1-2.fc42                anaconda     2.3 MiB
	 ==> vmware-iso.fedora42srv:  openssh                                    x86_64 9.9p1-11.fc42                updates      1.4 MiB
	 ==> vmware-iso.fedora42srv:    replacing openssh                        x86_64 9.9p1-10.fc42                anaconda     1.4 MiB
	 ==> vmware-iso.fedora42srv:  openssh-clients                            x86_64 9.9p1-11.fc42                updates      2.7 MiB
	 ==> vmware-iso.fedora42srv:    replacing openssh-clients                x86_64 9.9p1-10.fc42                anaconda     2.7 MiB
	 ==> vmware-iso.fedora42srv:  openssh-server                             x86_64 9.9p1-11.fc42                updates      1.4 MiB
	 ==> vmware-iso.fedora42srv:    replacing openssh-server                 x86_64 9.9p1-10.fc42                anaconda     1.4 MiB
	 ==> vmware-iso.fedora42srv:  openssl                                    x86_64 1:3.2.6-2.fc42               updates      1.7 MiB
	 ==> vmware-iso.fedora42srv:    replacing openssl                        x86_64 1:3.2.4-3.fc42               anaconda     1.7 MiB
	 ==> vmware-iso.fedora42srv:  openssl-libs                               x86_64 1:3.2.6-2.fc42               updates      7.8 MiB
	 ==> vmware-iso.fedora42srv:    replacing openssl-libs                   x86_64 1:3.2.4-3.fc42               anaconda     7.8 MiB
	 ==> vmware-iso.fedora42srv:  p11-kit                                    x86_64 0.25.8-1.fc42                updates      2.3 MiB
	 ==> vmware-iso.fedora42srv:    replacing p11-kit                        x86_64 0.25.5-5.fc42                anaconda     2.2 MiB
	 ==> vmware-iso.fedora42srv:  p11-kit-trust                              x86_64 0.25.8-1.fc42                updates    446.5 KiB
	 ==> vmware-iso.fedora42srv:    replacing p11-kit-trust                  x86_64 0.25.5-5.fc42                anaconda   395.5 KiB
	 ==> vmware-iso.fedora42srv:  pam                                        x86_64 1.7.0-6.fc42                 updates      1.6 MiB
	 ==> vmware-iso.fedora42srv:    replacing pam                            x86_64 1.7.0-4.fc42                 anaconda     1.6 MiB
	 ==> vmware-iso.fedora42srv:  pam-libs                                   x86_64 1.7.0-6.fc42                 updates    126.7 KiB
	 ==> vmware-iso.fedora42srv:    replacing pam-libs                       x86_64 1.7.0-4.fc42                 anaconda   126.7 KiB
	 ==> vmware-iso.fedora42srv:  passim-libs                                x86_64 0.1.10-1.fc42                updates     70.1 KiB
	 ==> vmware-iso.fedora42srv:    replacing passim-libs                    x86_64 0.1.9-1.fc42                 anaconda    70.1 KiB
	 ==> vmware-iso.fedora42srv:  pciutils                                   x86_64 3.14.0-1.fc42                updates    284.1 KiB
	 ==> vmware-iso.fedora42srv:    replacing pciutils                       x86_64 3.13.0-7.fc42                anaconda   232.2 KiB
	 ==> vmware-iso.fedora42srv:  pciutils-libs                              x86_64 3.14.0-1.fc42                updates     99.4 KiB
	 ==> vmware-iso.fedora42srv:    replacing pciutils-libs                  x86_64 3.13.0-7.fc42                anaconda    99.4 KiB
	 ==> vmware-iso.fedora42srv:  pcre2                                      x86_64 10.46-1.fc42                 updates    697.7 KiB
	 ==> vmware-iso.fedora42srv:    replacing pcre2                          x86_64 10.45-1.fc42                 anaconda   697.7 KiB
	 ==> vmware-iso.fedora42srv:  pcre2-syntax                               noarch 10.46-1.fc42                 updates    275.3 KiB
	 ==> vmware-iso.fedora42srv:    replacing pcre2-syntax                   noarch 10.45-1.fc42                 anaconda   273.9 KiB
	 ==> vmware-iso.fedora42srv:  pixman                                     x86_64 0.46.2-1.fc42                updates    710.3 KiB
	 ==> vmware-iso.fedora42srv:    replacing pixman                         x86_64 0.44.2-2.fc42                anaconda   674.2 KiB
	 ==> vmware-iso.fedora42srv:  plymouth                                   x86_64 24.004.60-19.fc42            updates    331.0 KiB
	 ==> vmware-iso.fedora42srv:    replacing plymouth                       x86_64 24.004.60-18.fc42            anaconda   331.0 KiB
	 ==> vmware-iso.fedora42srv:  plymouth-core-libs                         x86_64 24.004.60-19.fc42            updates    354.8 KiB
	 ==> vmware-iso.fedora42srv:    replacing plymouth-core-libs             x86_64 24.004.60-18.fc42            anaconda   354.7 KiB
	 ==> vmware-iso.fedora42srv:  plymouth-scripts                           x86_64 24.004.60-19.fc42            updates     30.5 KiB
	 ==> vmware-iso.fedora42srv:    replacing plymouth-scripts               x86_64 24.004.60-18.fc42            anaconda    30.5 KiB
	 ==> vmware-iso.fedora42srv:  polkit                                     x86_64 126-3.fc42.1                 updates    460.0 KiB
	 ==> vmware-iso.fedora42srv:    replacing polkit                         x86_64 126-2.fc42                   anaconda   460.0 KiB
	 ==> vmware-iso.fedora42srv:  polkit-libs                                x86_64 126-3.fc42.1                 updates    199.8 KiB
	 ==> vmware-iso.fedora42srv:    replacing polkit-libs                    x86_64 126-2.fc42                   anaconda   199.8 KiB
	 ==> vmware-iso.fedora42srv:  procps-ng                                  x86_64 4.0.4-6.fc42.1               updates      1.0 MiB
	 ==> vmware-iso.fedora42srv:    replacing procps-ng                      x86_64 4.0.4-6.fc42                 anaconda     1.0 MiB
	 ==> vmware-iso.fedora42srv:  protobuf-c                                 x86_64 1.5.1-1.fc42                 updates     49.8 KiB
	 ==> vmware-iso.fedora42srv:    replacing protobuf-c                     x86_64 1.5.0-4.fc41                 anaconda    54.0 KiB
	 ==> vmware-iso.fedora42srv:  publicsuffix-list-dafsa                    noarch 20250616-1.fc42              updates     69.1 KiB
	 ==> vmware-iso.fedora42srv:    replacing publicsuffix-list-dafsa        noarch 20250116-1.fc42              anaconda    68.5 KiB
	 ==> vmware-iso.fedora42srv:  python-pip-wheel                           noarch 24.3.1-5.fc42                updates      1.2 MiB
	 ==> vmware-iso.fedora42srv:    replacing python-pip-wheel               noarch 24.3.1-2.fc42                anaconda     1.2 MiB
	 ==> vmware-iso.fedora42srv:  python3                                    x86_64 3.13.9-1.fc42                updates     28.7 KiB
	 ==> vmware-iso.fedora42srv:    replacing python3                        x86_64 3.13.2-2.fc42                anaconda    27.6 KiB
	 ==> vmware-iso.fedora42srv:  python3-argcomplete                        noarch 3.6.2-2.fc42                 updates    316.8 KiB
	 ==> vmware-iso.fedora42srv:    replacing python3-argcomplete            noarch 3.6.0-1.fc42                 anaconda   314.5 KiB
	 ==> vmware-iso.fedora42srv:  python3-audit                              x86_64 4.1.2-2.fc42                 updates    286.2 KiB
	 ==> vmware-iso.fedora42srv:    replacing python3-audit                  x86_64 4.0.3-2.fc42                 anaconda   290.7 KiB
	 ==> vmware-iso.fedora42srv:  python3-augeas                             x86_64 1.2.0-1.fc42                 updates    171.8 KiB
	 ==> vmware-iso.fedora42srv:    replacing python3-augeas                 noarch 1.1.0-15.fc42                anaconda    94.4 KiB
	 ==> vmware-iso.fedora42srv:  python3-dnf                                noarch 4.24.0-1.fc42                updates      2.7 MiB
	 ==> vmware-iso.fedora42srv:    replacing python3-dnf                    noarch 4.23.0-1.fc42                anaconda     2.7 MiB
	 ==> vmware-iso.fedora42srv:  python3-firewall                           noarch 2.3.1-1.fc42                 updates      2.8 MiB
	 ==> vmware-iso.fedora42srv:    replacing python3-firewall               noarch 2.3.0-4.fc42                 anaconda     2.8 MiB
	 ==> vmware-iso.fedora42srv:  python3-hawkey                             x86_64 0.75.0-1.fc42                updates    294.2 KiB
	 ==> vmware-iso.fedora42srv:    replacing python3-hawkey                 x86_64 0.74.0-1.fc42                anaconda   294.0 KiB
	 ==> vmware-iso.fedora42srv:  python3-libcomps                           x86_64 0.1.22-1.fc42                updates    139.3 KiB
	 ==> vmware-iso.fedora42srv:    replacing python3-libcomps               x86_64 0.1.21-5.fc42                anaconda   143.3 KiB
	 ==> vmware-iso.fedora42srv:  python3-libdnf                             x86_64 0.75.0-1.fc42                updates      3.7 MiB
	 ==> vmware-iso.fedora42srv:    replacing python3-libdnf                 x86_64 0.74.0-1.fc42                anaconda     3.7 MiB
	 ==> vmware-iso.fedora42srv:  python3-libs                               x86_64 3.13.9-1.fc42                updates     40.1 MiB
	 ==> vmware-iso.fedora42srv:    replacing python3-libs                   x86_64 3.13.2-2.fc42                anaconda    39.9 MiB
	 ==> vmware-iso.fedora42srv:  python3-libselinux                         x86_64 3.8-3.fc42                   updates    606.8 KiB
	 ==> vmware-iso.fedora42srv:    replacing python3-libselinux             x86_64 3.8-1.fc42                   anaconda   606.9 KiB
	 ==> vmware-iso.fedora42srv:  python3-libsemanage                        x86_64 3.8.1-2.fc42                 updates    382.2 KiB
	 ==> vmware-iso.fedora42srv:    replacing python3-libsemanage            x86_64 3.8-1.fc42                   anaconda   382.2 KiB
	 ==> vmware-iso.fedora42srv:  python3-requests                           noarch 2.32.4-1.fc42                updates    473.8 KiB
	 ==> vmware-iso.fedora42srv:    replacing python3-requests               noarch 2.32.3-4.fc42                anaconda   483.1 KiB
	 ==> vmware-iso.fedora42srv:  python3-setools                            x86_64 4.5.1-6.fc42                 updates      2.9 MiB
	 ==> vmware-iso.fedora42srv:    replacing python3-setools                x86_64 4.5.1-5.fc42                 anaconda     2.9 MiB
	 ==> vmware-iso.fedora42srv:  python3-setuptools                         noarch 74.1.3-7.fc42                updates      8.4 MiB
	 ==> vmware-iso.fedora42srv:    replacing python3-setuptools             noarch 74.1.3-5.fc42                anaconda     8.4 MiB
	 ==> vmware-iso.fedora42srv:  realmd                                     x86_64 0.17.1-17.fc42               updates    833.7 KiB
	 ==> vmware-iso.fedora42srv:    replacing realmd                         x86_64 0.17.1-15.fc42               anaconda   825.1 KiB
	 ==> vmware-iso.fedora42srv:  realtek-firmware                           noarch 20251021-1.fc42              updates      5.2 MiB
	 ==> vmware-iso.fedora42srv:    replacing realtek-firmware               noarch 20250311-1.fc42              anaconda     4.6 MiB
	 ==> vmware-iso.fedora42srv:  rpcbind                                    x86_64 1.2.8-0.fc42                 updates    108.0 KiB
	 ==> vmware-iso.fedora42srv:    replacing rpcbind                        x86_64 1.2.7-1.rc1.fc42.4           anaconda   108.0 KiB
	 ==> vmware-iso.fedora42srv:  rsyslog                                    x86_64 8.2508.0-1.fc42              updates      2.7 MiB
	 ==> vmware-iso.fedora42srv:    replacing rsyslog                        x86_64 8.2412.0-3.fc42              anaconda     2.7 MiB
	 ==> vmware-iso.fedora42srv:  samba-client-libs                          x86_64 2:4.22.6-1.fc42              updates     19.5 MiB
	 ==> vmware-iso.fedora42srv:    replacing samba-client-libs              x86_64 2:4.22.0-20.fc42             anaconda    19.5 MiB
	 ==> vmware-iso.fedora42srv:  samba-common                               noarch 2:4.22.6-1.fc42              updates    208.5 KiB
	 ==> vmware-iso.fedora42srv:    replacing samba-common                   noarch 2:4.22.0-20.fc42             anaconda   193.0 KiB
	 ==> vmware-iso.fedora42srv:  samba-common-libs                          x86_64 2:4.22.6-1.fc42              updates    259.4 KiB
	 ==> vmware-iso.fedora42srv:    replacing samba-common-libs              x86_64 2:4.22.0-20.fc42             anaconda   260.1 KiB
	 ==> vmware-iso.fedora42srv:  selinux-policy                             noarch 42.13-1.fc42                 updates     31.6 KiB
	 ==> vmware-iso.fedora42srv:    replacing selinux-policy                 noarch 41.34-1.fc42                 anaconda    31.4 KiB
	 ==> vmware-iso.fedora42srv:  selinux-policy-targeted                    noarch 42.13-1.fc42                 updates     18.7 MiB
	 ==> vmware-iso.fedora42srv:    replacing selinux-policy-targeted        noarch 41.34-1.fc42                 anaconda    18.5 MiB
	 ==> vmware-iso.fedora42srv:  smartmontools                              x86_64 1:7.5-3.fc42                 updates      2.3 MiB
	 ==> vmware-iso.fedora42srv:    replacing smartmontools                  x86_64 1:7.4-8.fc42                 anaconda     2.2 MiB
	 ==> vmware-iso.fedora42srv:  smartmontools-selinux                      noarch 1:7.5-3.fc42                 updates     33.4 KiB
	 ==> vmware-iso.fedora42srv:    replacing smartmontools-selinux          noarch 1:7.4-8.fc42                 anaconda    33.2 KiB
	 ==> vmware-iso.fedora42srv:  sos                                        noarch 4.10.0-1.fc42                updates      3.9 MiB
	 ==> vmware-iso.fedora42srv:    replacing sos                            noarch 4.8.2-2.fc42                 anaconda     3.7 MiB
	 ==> vmware-iso.fedora42srv:  sqlite-libs                                x86_64 3.47.2-5.fc42                updates      1.5 MiB
	 ==> vmware-iso.fedora42srv:    replacing sqlite-libs                    x86_64 3.47.2-2.fc42                anaconda     1.5 MiB
	 ==> vmware-iso.fedora42srv:  sssd-client                                x86_64 2.11.1-2.fc42                updates    333.9 KiB
	 ==> vmware-iso.fedora42srv:    replacing sssd-client                    x86_64 2.10.2-3.fc42                anaconda   346.4 KiB
	 ==> vmware-iso.fedora42srv:  sssd-common                                x86_64 2.11.1-2.fc42                updates      5.2 MiB
	 ==> vmware-iso.fedora42srv:    replacing sssd-common                    x86_64 2.10.2-3.fc42                anaconda     5.2 MiB
	 ==> vmware-iso.fedora42srv:  sssd-kcm                                   x86_64 2.11.1-2.fc42                updates    225.8 KiB
	 ==> vmware-iso.fedora42srv:    replacing sssd-kcm                       x86_64 2.10.2-3.fc42                anaconda   231.1 KiB
	 ==> vmware-iso.fedora42srv:  sssd-krb5-common                           x86_64 2.11.1-2.fc42                updates    219.3 KiB
	 ==> vmware-iso.fedora42srv:    replacing sssd-krb5-common               x86_64 2.10.2-3.fc42                anaconda   218.8 KiB
	 ==> vmware-iso.fedora42srv:  sssd-nfs-idmap                             x86_64 2.11.1-2.fc42                updates     41.6 KiB
	 ==> vmware-iso.fedora42srv:    replacing sssd-nfs-idmap                 x86_64 2.10.2-3.fc42                anaconda    43.2 KiB
	 ==> vmware-iso.fedora42srv:  sssd-proxy                                 x86_64 2.11.1-2.fc42                updates    161.6 KiB
	 ==> vmware-iso.fedora42srv:    replacing sssd-proxy                     x86_64 2.10.2-3.fc42                anaconda   161.6 KiB
	 ==> vmware-iso.fedora42srv:  sudo                                       x86_64 1.9.17-2.p1.fc42             updates      5.0 MiB
	 ==> vmware-iso.fedora42srv:    replacing sudo                           x86_64 1.9.15-7.p5.fc42             anaconda     4.9 MiB
	 ==> vmware-iso.fedora42srv:  systemd                                    x86_64 257.10-1.fc42                updates     12.1 MiB
	 ==> vmware-iso.fedora42srv:    replacing systemd                        x86_64 257.3-7.fc42                 anaconda    12.1 MiB
	 ==> vmware-iso.fedora42srv:  systemd-libs                               x86_64 257.10-1.fc42                updates      2.2 MiB
	 ==> vmware-iso.fedora42srv:    replacing systemd-libs                   x86_64 257.3-7.fc42                 anaconda     2.2 MiB
	 ==> vmware-iso.fedora42srv:  systemd-oomd-defaults                      noarch 257.10-1.fc42                updates    187.0   B
	 ==> vmware-iso.fedora42srv:    replacing systemd-oomd-defaults          noarch 257.3-7.fc42                 anaconda   187.0   B
	 ==> vmware-iso.fedora42srv:  systemd-pam                                x86_64 257.10-1.fc42                updates      1.1 MiB
	 ==> vmware-iso.fedora42srv:    replacing systemd-pam                    x86_64 257.3-7.fc42                 anaconda     1.1 MiB
	 ==> vmware-iso.fedora42srv:  systemd-resolved                           x86_64 257.10-1.fc42                updates    673.9 KiB
	 ==> vmware-iso.fedora42srv:    replacing systemd-resolved               x86_64 257.3-7.fc42                 anaconda   681.9 KiB
	 ==> vmware-iso.fedora42srv:  systemd-shared                             x86_64 257.10-1.fc42                updates      4.6 MiB
	 ==> vmware-iso.fedora42srv:    replacing systemd-shared                 x86_64 257.3-7.fc42                 anaconda     4.6 MiB
	 ==> vmware-iso.fedora42srv:  systemd-sysusers                           x86_64 257.10-1.fc42                updates     83.8 KiB
	 ==> vmware-iso.fedora42srv:    replacing systemd-sysusers               x86_64 257.3-7.fc42                 anaconda    83.8 KiB
	 ==> vmware-iso.fedora42srv:  systemd-udev                               x86_64 257.10-1.fc42                updates     12.2 MiB
	 ==> vmware-iso.fedora42srv:    replacing systemd-udev                   x86_64 257.3-7.fc42                 anaconda    11.9 MiB
	 ==> vmware-iso.fedora42srv:  tcpdump                                    x86_64 14:4.99.5-4.fc42             updates      1.2 MiB
	 ==> vmware-iso.fedora42srv:    replacing tcpdump                        x86_64 14:4.99.5-3.fc42             anaconda     1.2 MiB
	 ==> vmware-iso.fedora42srv:  tiwilink-firmware                          noarch 20251021-1.fc42              updates      4.6 MiB
	 ==> vmware-iso.fedora42srv:    replacing tiwilink-firmware              noarch 20250311-1.fc42              anaconda     4.6 MiB
	 ==> vmware-iso.fedora42srv:  udisks2                                    x86_64 2.10.91-1.fc42               updates      2.9 MiB
	 ==> vmware-iso.fedora42srv:    replacing udisks2                        x86_64 2.10.90-2.fc42               anaconda     2.9 MiB
	 ==> vmware-iso.fedora42srv:  udisks2-iscsi                              x86_64 2.10.91-1.fc42               updates    583.0 KiB
	 ==> vmware-iso.fedora42srv:    replacing udisks2-iscsi                  x86_64 2.10.90-2.fc42               anaconda   583.0 KiB
	 ==> vmware-iso.fedora42srv:  udisks2-lvm2                               x86_64 2.10.91-1.fc42               updates    635.9 KiB
	 ==> vmware-iso.fedora42srv:    replacing udisks2-lvm2                   x86_64 2.10.90-2.fc42               anaconda   635.8 KiB
	 ==> vmware-iso.fedora42srv:  unbound-libs                               x86_64 1.24.1-1.fc42                updates      1.4 MiB
	 ==> vmware-iso.fedora42srv:    replacing unbound-libs                   x86_64 1.22.0-14.fc42               anaconda     1.4 MiB
	 ==> vmware-iso.fedora42srv:  usb_modeswitch                             x86_64 2.6.2-4.fc42                 updates    217.4 KiB
	 ==> vmware-iso.fedora42srv:    replacing usb_modeswitch                 x86_64 2.6.2-2.fc42                 anaconda   217.2 KiB
	 ==> vmware-iso.fedora42srv:  vim-common                                 x86_64 2:9.1.1818-1.fc42            updates     36.9 MiB
	 ==> vmware-iso.fedora42srv:    replacing vim-common                     x86_64 2:9.1.1227-1.fc42            anaconda    37.8 MiB
	 ==> vmware-iso.fedora42srv:  vim-data                                   noarch 2:9.1.1818-1.fc42            updates     10.2 KiB
	 ==> vmware-iso.fedora42srv:    replacing vim-data                       noarch 2:9.1.1227-1.fc42            anaconda    10.3 KiB
	 ==> vmware-iso.fedora42srv:  vim-default-editor                         noarch 2:9.1.1818-1.fc42            updates    505.0   B
	 ==> vmware-iso.fedora42srv:    replacing vim-default-editor             noarch 2:9.1.1227-1.fc42            anaconda   505.0   B
	 ==> vmware-iso.fedora42srv:  vim-enhanced                               x86_64 2:9.1.1818-1.fc42            updates      4.2 MiB
	 ==> vmware-iso.fedora42srv:    replacing vim-enhanced                   x86_64 2:9.1.1227-1.fc42            anaconda     4.0 MiB
	 ==> vmware-iso.fedora42srv:  vim-filesystem                             noarch 2:9.1.1818-1.fc42            updates     40.0   B
	 ==> vmware-iso.fedora42srv:    replacing vim-filesystem                 noarch 2:9.1.1227-1.fc42            anaconda    40.0   B
	 ==> vmware-iso.fedora42srv:  vim-minimal                                x86_64 2:9.1.1818-1.fc42            updates      1.7 MiB
	 ==> vmware-iso.fedora42srv:    replacing vim-minimal                    x86_64 2:9.1.1227-1.fc42            anaconda     1.7 MiB
	 ==> vmware-iso.fedora42srv:  wget2                                      x86_64 2.2.0-5.fc42                 updates      1.0 MiB
	 ==> vmware-iso.fedora42srv:    replacing wget2                          x86_64 2.2.0-3.fc42                 anaconda     1.0 MiB
	 ==> vmware-iso.fedora42srv:  wget2-libs                                 x86_64 2.2.0-5.fc42                 updates    365.6 KiB
	 ==> vmware-iso.fedora42srv:    replacing wget2-libs                     x86_64 2.2.0-3.fc42                 anaconda   365.6 KiB
	 ==> vmware-iso.fedora42srv:  wget2-wget                                 x86_64 2.2.0-5.fc42                 updates     42.0   B
	 ==> vmware-iso.fedora42srv:    replacing wget2-wget                     x86_64 2.2.0-3.fc42                 anaconda    42.0   B
	 ==> vmware-iso.fedora42srv:  which                                      x86_64 2.23-2.fc42                  updates     83.5 KiB
	 ==> vmware-iso.fedora42srv:    replacing which                          x86_64 2.23-1.fc42                  anaconda    83.4 KiB
	 ==> vmware-iso.fedora42srv:  whois                                      x86_64 5.6.5-1.fc42                 updates    173.0 KiB
	 ==> vmware-iso.fedora42srv:    replacing whois                          x86_64 5.5.20-5.fc42                anaconda   174.2 KiB
	 ==> vmware-iso.fedora42srv:  whois-nls                                  noarch 5.6.5-1.fc42                 updates    132.2 KiB
	 ==> vmware-iso.fedora42srv:    replacing whois-nls                      noarch 5.5.20-5.fc42                anaconda   132.2 KiB
	 ==> vmware-iso.fedora42srv:  wireless-regdb                             noarch 2025.10.07-1.fc42            updates     12.7 KiB
	 ==> vmware-iso.fedora42srv:    replacing wireless-regdb                 noarch 2024.01.23-3.fc42            anaconda    11.3 KiB
	 ==> vmware-iso.fedora42srv:  wpa_supplicant                             x86_64 1:2.11-6.fc42                updates      6.3 MiB
	 ==> vmware-iso.fedora42srv:    replacing wpa_supplicant                 x86_64 1:2.11-4.fc42                anaconda     6.3 MiB
	 ==> vmware-iso.fedora42srv:  xxd                                        x86_64 2:9.1.1818-1.fc42            updates     37.2 KiB
	 ==> vmware-iso.fedora42srv:    replacing xxd                            x86_64 2:9.1.1227-1.fc42            anaconda    33.3 KiB
	 ==> vmware-iso.fedora42srv:  xz                                         x86_64 1:5.8.1-2.fc42               updates      1.3 MiB
	 ==> vmware-iso.fedora42srv:    replacing xz                             x86_64 1:5.6.3-3.fc42               anaconda     1.2 MiB
	 ==> vmware-iso.fedora42srv:  xz-libs                                    x86_64 1:5.8.1-2.fc42               updates    217.8 KiB
	 ==> vmware-iso.fedora42srv:    replacing xz-libs                        x86_64 1:5.6.3-3.fc42               anaconda   218.3 KiB
	 ==> vmware-iso.fedora42srv:  zlib-ng-compat                             x86_64 2.2.5-2.fc42                 updates    137.6 KiB
	 ==> vmware-iso.fedora42srv:    replacing zlib-ng-compat                 x86_64 2.2.4-3.fc42                 anaconda   137.6 KiB
	 ==> vmware-iso.fedora42srv: Installing:
	 ==> vmware-iso.fedora42srv:  kernel                                     x86_64 6.17.6-200.fc42              updates      0.0   B
	 ==> vmware-iso.fedora42srv: Installing dependencies:
	 ==> vmware-iso.fedora42srv:  cockpit-ws-selinux                         x86_64 347-1.fc42                   updates     44.9 KiB
	 ==> vmware-iso.fedora42srv:  gnulib-l10n                                noarch 20241231-1.fc42              updates    655.0 KiB
	 ==> vmware-iso.fedora42srv:  iwlwifi-mld-firmware                       noarch 20251021-1.fc42              updates      7.1 MiB
	 ==> vmware-iso.fedora42srv:  kernel-core                                x86_64 6.17.6-200.fc42              updates     98.8 MiB
	 ==> vmware-iso.fedora42srv:  kernel-modules                             x86_64 6.17.6-200.fc42              updates     95.6 MiB
	 ==> vmware-iso.fedora42srv:  kernel-modules-core                        x86_64 6.17.6-200.fc42              updates     68.3 MiB
	 ==> vmware-iso.fedora42srv:  libfyaml                                   x86_64 0.8-7.fc42                   fedora     549.3 KiB
	 ==> vmware-iso.fedora42srv:  tpm2-tss-fapi                              x86_64 4.1.3-6.fc42                 fedora     878.0 KiB
	 ==> vmware-iso.fedora42srv: Installing weak dependencies:
	 ==> vmware-iso.fedora42srv:  libdnf5-plugin-expired-pgp-keys            x86_64 5.2.17.0-1.fc42              updates     86.5 KiB
	 ==> vmware-iso.fedora42srv:  qcom-wwan-firmware                         noarch 20251021-1.fc42              updates    300.4 KiB
	 ==> vmware-iso.fedora42srv:  rpm-plugin-systemd-inhibit                 x86_64 4.20.1-1.fc42                fedora      12.1 KiB
	 ==> vmware-iso.fedora42srv:  tpm2-tools                                 x86_64 5.7-3.fc42                   fedora       1.5 MiB
	 ==> vmware-iso.fedora42srv:
	 ==> vmware-iso.fedora42srv: Transaction Summary:
	 ==> vmware-iso.fedora42srv:  Installing:        13 packages
	 ==> vmware-iso.fedora42srv:  Upgrading:        265 packages
	 ==> vmware-iso.fedora42srv:  Replacing:        265 packages
	 ==> vmware-iso.fedora42srv:
	 ==> vmware-iso.fedora42srv: [  1/278] libfyaml-0:0.8-7.fc42.x86_64  100% | 678.7 KiB/s | 231.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [  2/278] gnulib-l10n-0:20241231-1.fc42 100% | 272.9 KiB/s | 150.1 KiB |  00m01s
	 ==> vmware-iso.fedora42srv: [  3/278] kernel-0:6.17.6-200.fc42.x86_ 100% | 392.9 KiB/s | 220.4 KiB |  00m01s
	 ==> vmware-iso.fedora42srv: [  4/278] iwlwifi-mld-firmware-0:202510 100% |   6.8 MiB/s |   7.1 MiB |  00m01s
	 ==> vmware-iso.fedora42srv: [  5/278] kernel-core-0:6.17.6-200.fc42 100% |  20.7 MiB/s |  19.8 MiB |  00m01s
	 ==> vmware-iso.fedora42srv: [  6/278] cockpit-ws-selinux-0:347-1.fc 100% | 485.1 KiB/s |  44.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [  7/278] rpm-plugin-systemd-inhibit-0: 100% | 307.9 KiB/s |  20.3 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [  8/278] libdnf5-plugin-expired-pgp-ke 100% |   1.1 MiB/s |  95.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [  9/278] tpm2-tools-0:5.7-3.fc42.x86_6 100% |   4.2 MiB/s | 812.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 10/278] tpm2-tss-fapi-0:4.1.3-6.fc42. 100% |   8.7 MiB/s | 338.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 11/278] qcom-wwan-firmware-0:20251021 100% |   3.0 MiB/s | 300.3 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 12/278] NetworkManager-1:1.52.1-1.fc4 100% |   8.9 MiB/s |   2.2 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 13/278] NetworkManager-libnm-1:1.52.1 100% |  12.7 MiB/s |   1.9 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 14/278] glib2-0:2.84.4-1.fc42.x86_64  100% |  18.9 MiB/s |   3.1 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 15/278] NetworkManager-wwan-1:1.52.1- 100% | 631.4 KiB/s |  58.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 16/278] NetworkManager-wifi-1:1.52.1- 100% |   1.5 MiB/s | 131.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 17/278] NetworkManager-team-1:1.52.1- 100% | 378.3 KiB/s |  30.3 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 18/278] NetworkManager-bluetooth-1:1. 100% | 574.5 KiB/s |  51.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 19/278] kernel-modules-core-0:6.17.6- 100% |  27.2 MiB/s |  69.9 MiB |  00m03s
	 ==> vmware-iso.fedora42srv: [ 20/278] alsa-sof-firmware-0:2025.05.1 100% |  12.9 MiB/s |   9.0 MiB |  00m01s
	 ==> vmware-iso.fedora42srv: [ 21/278] alternatives-0:1.33-1.fc42.x8 100% | 450.5 KiB/s |  40.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 22/278] linux-firmware-whence-0:20251 100% | 647.7 KiB/s |  61.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 23/278] amd-ucode-firmware-0:20251021 100% |   4.3 MiB/s | 397.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 24/278] appstream-0:1.1.0-1.fc42.x86_ 100% |   7.6 MiB/s | 874.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 25/278] amd-gpu-firmware-0:20251021-1 100% |  23.1 MiB/s |  25.9 MiB |  00m01s
	 ==> vmware-iso.fedora42srv: [ 26/278] appstream-data-0:42-8.fc42.no 100% |  16.9 MiB/s |  15.3 MiB |  00m01s
	 ==> vmware-iso.fedora42srv: [ 27/278] at-0:3.2.5-16.fc42.x86_64     100% | 529.1 KiB/s |  61.9 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 28/278] audit-0:4.1.2-2.fc42.x86_64   100% |   2.4 MiB/s | 209.9 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 29/278] audit-libs-0:4.1.2-2.fc42.x86 100% |   1.7 MiB/s | 138.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 30/278] kernel-modules-0:6.17.6-200.f 100% |  20.2 MiB/s |  97.5 MiB |  00m05s
	 ==> vmware-iso.fedora42srv: [ 31/278] audit-rules-0:4.1.2-2.fc42.x8 100% | 107.5 KiB/s |  68.7 KiB |  00m01s
	 ==> vmware-iso.fedora42srv: [ 32/278] python3-audit-0:4.1.2-2.fc42. 100% | 902.5 KiB/s |  69.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 33/278] bash-color-prompt-0:0.7.1-1.f 100% | 229.9 KiB/s |  21.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 34/278] bind-utils-32:9.18.41-1.fc42. 100% |   2.6 MiB/s | 223.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 35/278] bind-libs-32:9.18.41-1.fc42.x 100% |  11.4 MiB/s |   1.3 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 36/278] bluez-0:5.84-2.fc42.x86_64    100% |   7.9 MiB/s |   1.2 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 37/278] binutils-0:2.44-6.fc42.x86_64 100% |  20.5 MiB/s |   5.8 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 38/278] bluez-libs-0:5.84-2.fc42.x86_ 100% | 726.9 KiB/s |  83.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 39/278] btrfs-progs-0:6.16.1-1.fc42.x 100% |   9.8 MiB/s |   1.3 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 40/278] c-ares-0:1.34.5-1.fc42.x86_64 100% |   1.2 MiB/s | 117.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 41/278] brcmfmac-firmware-0:20251021- 100% |  25.6 MiB/s |   9.6 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 42/278] ca-certificates-0:2025.2.80_v 100% |   6.1 MiB/s | 973.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 43/278] chrony-0:4.8-1.fc42.x86_64    100% |   3.6 MiB/s | 350.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 44/278] cirrus-audio-firmware-0:20251 100% |  15.8 MiB/s |   2.1 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 45/278] cockpit-0:347-1.fc42.x86_64   100% | 393.7 KiB/s |  32.3 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 46/278] atheros-firmware-0:20251021-1 100% |  19.4 MiB/s |  41.0 MiB |  00m02s
	 ==> vmware-iso.fedora42srv: [ 47/278] cockpit-bridge-0:347-1.fc42.n 100% |   2.0 MiB/s | 688.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 48/278] cockpit-networkmanager-0:347- 100% |   2.6 MiB/s | 806.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 49/278] cockpit-packagekit-0:347-1.fc 100% |   7.4 MiB/s | 873.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 50/278] cockpit-selinux-0:347-1.fc42. 100% |   3.7 MiB/s | 432.9 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 51/278] cockpit-storaged-0:347-1.fc42 100% |   6.0 MiB/s | 815.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 52/278] cockpit-ws-0:347-1.fc42.x86_6 100% |   6.2 MiB/s |   1.1 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 53/278] coreutils-0:9.6-6.fc42.x86_64 100% |   6.8 MiB/s |   1.1 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 54/278] cockpit-system-0:347-1.fc42.n 100% |  11.9 MiB/s |   3.0 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 55/278] crypto-policies-0:20250707-1. 100% | 623.2 KiB/s |  96.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 56/278] coreutils-common-0:9.6-6.fc42 100% |   8.8 MiB/s |   2.1 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 57/278] crypto-policies-scripts-0:202 100% | 774.4 KiB/s | 127.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 58/278] cryptsetup-0:2.8.1-1.fc42.x86 100% |   2.4 MiB/s | 347.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 59/278] cryptsetup-libs-0:2.8.1-1.fc4 100% |   2.4 MiB/s | 575.3 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 60/278] curl-0:8.11.1-6.fc42.x86_64   100% | 944.1 KiB/s | 220.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 61/278] libcurl-0:8.11.1-6.fc42.x86_6 100% |   1.8 MiB/s | 371.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 62/278] libssh-0:0.11.3-1.fc42.x86_64 100% |   1.8 MiB/s | 233.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 63/278] libssh-config-0:0.11.3-1.fc42 100% |  71.2 KiB/s |   9.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 64/278] dbus-broker-0:36-6.fc42.x86_6 100% |   1.7 MiB/s | 172.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 65/278] dnf-data-0:4.24.0-1.fc42.noar 100% | 496.6 KiB/s |  37.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 66/278] diffutils-0:3.12-1.fc42.x86_6 100% |   4.6 MiB/s | 392.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 67/278] python3-dnf-0:4.24.0-1.fc42.n 100% |   6.8 MiB/s | 632.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 68/278] python3-hawkey-0:0.75.0-1.fc4 100% |   1.3 MiB/s | 101.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 69/278] python3-libdnf-0:0.75.0-1.fc4 100% |   8.3 MiB/s | 844.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 70/278] libdnf-0:0.75.0-1.fc42.x86_64 100% |   7.9 MiB/s | 727.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 71/278] dnf5-0:5.2.17.0-1.fc42.x86_64 100% |   8.7 MiB/s | 942.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 72/278] libdnf5-cli-0:5.2.17.0-1.fc42 100% |   4.2 MiB/s | 357.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 73/278] libdnf5-0:5.2.17.0-1.fc42.x86 100% |  11.2 MiB/s |   1.3 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 74/278] librepo-0:1.20.0-1.fc42.x86_6 100% |   1.1 MiB/s | 101.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 75/278] dnf5-plugins-0:5.2.17.0-1.fc4 100% |   4.3 MiB/s | 478.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 76/278] dnsmasq-0:2.90-6.fc42.x86_64  100% |   3.4 MiB/s | 361.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 77/278] dracut-0:107-4.fc42.x86_64    100% |   5.8 MiB/s | 629.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 78/278] dracut-config-rescue-0:107-4. 100% | 141.6 KiB/s |  11.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 79/278] elfutils-0:0.194-1.fc42.x86_6 100% |   6.2 MiB/s | 575.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 80/278] elfutils-debuginfod-client-0: 100% | 617.7 KiB/s |  46.9 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 81/278] elfutils-libelf-0:0.194-1.fc4 100% |   2.4 MiB/s | 205.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 82/278] elfutils-libs-0:0.194-1.fc42. 100% |   3.0 MiB/s | 271.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 83/278] elfutils-default-yama-scope-0 100% | 158.7 KiB/s |  12.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 84/278] ethtool-2:6.15-3.fc42.x86_64  100% |   3.3 MiB/s | 318.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 85/278] exfatprogs-0:1.3.0-1.fc42.x86 100% |   1.5 MiB/s | 114.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 86/278] expat-0:2.7.2-1.fc42.x86_64   100% |   1.5 MiB/s | 119.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 87/278] fedora-release-common-0:42-30 100% | 269.1 KiB/s |  24.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 88/278] fedora-release-server-0:42-30 100% | 161.1 KiB/s |  13.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 89/278] fedora-release-identity-serve 100% | 181.5 KiB/s |  16.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 90/278] file-0:5.46-3.fc42.x86_64     100% | 528.8 KiB/s |  48.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 91/278] file-libs-0:5.46-3.fc42.x86_6 100% |   7.8 MiB/s | 849.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 92/278] filesystem-0:3.18-47.fc42.x86 100% |   9.4 MiB/s |   1.3 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 93/278] firewalld-0:2.3.1-1.fc42.noar 100% |   5.4 MiB/s | 526.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 94/278] firewalld-filesystem-0:2.3.1- 100% | 122.2 KiB/s |  10.3 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 95/278] fonts-filesystem-1:2.0.5-22.f 100% | 113.3 KiB/s |   8.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 96/278] python3-firewall-0:2.3.1-1.fc 100% |   4.6 MiB/s | 509.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 97/278] fprintd-0:1.94.5-1.fc42.x86_6 100% |   1.7 MiB/s | 181.3 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 98/278] fprintd-pam-0:1.94.5-1.fc42.x 100% | 187.6 KiB/s |  22.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 99/278] libxmlb-0:0.3.24-1.fc42.x86_6 100% |   1.1 MiB/s | 117.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [100/278] fwupd-0:2.0.16-1.fc42.x86_64  100% |  16.9 MiB/s |   2.6 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [101/278] glibc-0:2.41-11.fc42.x86_64   100% |  14.8 MiB/s |   2.2 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [102/278] glibc-common-0:2.41-11.fc42.x 100% |   3.5 MiB/s | 385.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [103/278] gdb-headless-0:16.3-1.fc42.x8 100% |  22.3 MiB/s |   5.1 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [104/278] glibc-langpack-en-0:2.41-11.f 100% |   4.4 MiB/s | 641.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [105/278] glibc-gconv-extra-0:2.41-11.f 100% |   7.4 MiB/s |   1.6 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [106/278] gnutls-0:3.8.10-1.fc42.x86_64 100% |   7.9 MiB/s |   1.4 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [107/278] gnutls-dane-0:3.8.10-1.fc42.x 100% | 382.9 KiB/s |  38.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [108/278] gpgme-0:1.24.3-1.fc42.x86_64  100% |   2.0 MiB/s | 219.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [109/278] grub2-common-1:2.12-32.fc42.n 100% |   7.6 MiB/s |   1.0 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [110/278] grub2-tools-minimal-1:2.12-32 100% |   4.4 MiB/s | 614.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [111/278] grub2-tools-1:2.12-32.fc42.x8 100% |  12.5 MiB/s |   1.8 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [112/278] grub2-pc-1:2.12-32.fc42.x86_6 100% | 126.9 KiB/s |  15.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [113/278] grub2-pc-modules-1:2.12-32.fc 100% |   7.8 MiB/s |   1.1 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [114/278] inih-0:62-1.fc42.x86_64       100% | 239.9 KiB/s |  18.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [115/278] hwdata-0:0.400-1.fc42.noarch  100% |  13.5 MiB/s |   1.7 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [116/278] intel-audio-firmware-0:202510 100% |  17.9 MiB/s |   3.2 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [117/278] iptables-libs-0:1.8.11-9.fc42 100% |   2.9 MiB/s | 403.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [118/278] intel-vsc-firmware-0:20251021 100% |  19.3 MiB/s |   7.7 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [119/278] iptables-nft-0:1.8.11-9.fc42. 100% |   1.0 MiB/s | 184.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [120/278] intel-gpu-firmware-0:20251021 100% |  16.2 MiB/s |   8.8 MiB |  00m01s
	 ==> vmware-iso.fedora42srv: [121/278] iputils-0:20250605-1.fc42.x86 100% |   1.7 MiB/s | 209.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [122/278] iscsi-initiator-utils-0:6.2.1 100% |   3.1 MiB/s | 388.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [123/278] iwlegacy-firmware-0:20251021- 100% |   1.7 MiB/s | 148.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [124/278] iscsi-initiator-utils-iscsiui 100% | 857.5 KiB/s |  81.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [125/278] iwlwifi-dvm-firmware-0:202510 100% |  12.7 MiB/s |   1.8 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [126/278] json-glib-0:1.10.8-1.fc42.x86 100% |   1.8 MiB/s | 172.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [127/278] kexec-tools-0:2.0.32-1.fc42.x 100% |   1.3 MiB/s | 102.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [128/278] krb5-libs-0:1.21.3-6.fc42.x86 100% |   6.6 MiB/s | 759.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [129/278] less-0:679-1.fc42.x86_64      100% |   2.4 MiB/s | 195.3 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [130/278] libarchive-0:3.8.1-1.fc42.x86 100% |   3.3 MiB/s | 421.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [131/278] libblockdev-0:3.3.1-2.fc42.x8 100% | 847.0 KiB/s | 111.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [132/278] libblockdev-utils-0:3.3.1-2.f 100% | 417.7 KiB/s |  38.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [133/278] libblockdev-swap-0:3.3.1-2.fc 100% | 347.3 KiB/s |  30.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [134/278] libblockdev-smart-0:3.3.1-2.f 100% | 343.5 KiB/s |  32.3 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [135/278] libblockdev-part-0:3.3.1-2.fc 100% | 318.3 KiB/s |  37.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [136/278] libblockdev-nvme-0:3.3.1-2.fc 100% | 405.0 KiB/s |  39.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [137/278] libblockdev-mdraid-0:3.3.1-2. 100% | 298.5 KiB/s |  35.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [138/278] libblockdev-lvm-0:3.3.1-2.fc4 100% | 374.9 KiB/s |  51.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [139/278] libblockdev-loop-0:3.3.1-2.fc 100% | 302.2 KiB/s |  29.9 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [140/278] libblockdev-fs-0:3.3.1-2.fc42 100% | 533.3 KiB/s |  60.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [141/278] libblockdev-crypto-0:3.3.1-2. 100% | 417.1 KiB/s |  47.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [142/278] libcomps-0:0.1.22-1.fc42.x86_ 100% | 386.1 KiB/s |  76.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [143/278] python3-libcomps-0:0.1.22-1.f 100% | 237.1 KiB/s |  47.9 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [144/278] libdrm-0:2.4.127-3.fc42.x86_6 100% |   1.2 MiB/s | 162.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [145/278] libeconf-0:0.7.6-2.fc42.x86_6 100% | 253.0 KiB/s |  35.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [146/278] libedit-0:3.1-56.20251016cvs. 100% | 583.7 KiB/s | 105.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [147/278] libertas-firmware-0:20251021- 100% |   5.2 MiB/s |   1.3 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [148/278] libgcc-0:15.2.1-3.fc42.x86_64 100% | 588.7 KiB/s | 133.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [149/278] libgomp-0:15.2.1-3.fc42.x86_6 100% |   2.6 MiB/s | 374.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [150/278] libldb-2:4.22.6-1.fc42.x86_64 100% |   2.3 MiB/s | 187.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [151/278] libjcat-0:0.2.5-1.fc42.x86_64 100% | 923.8 KiB/s |  85.9 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [152/278] samba-common-2:4.22.6-1.fc42. 100% |   1.4 MiB/s | 177.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [153/278] libwbclient-2:4.22.6-1.fc42.x 100% | 594.2 KiB/s |  45.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [154/278] iwlwifi-mvm-firmware-0:202510 100% |  25.8 MiB/s |  60.6 MiB |  00m02s
	 ==> vmware-iso.fedora42srv: [155/278] samba-common-libs-2:4.22.6-1. 100% | 250.8 KiB/s | 106.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [156/278] samba-client-libs-2:4.22.6-1. 100% |   8.2 MiB/s |   5.6 MiB |  00m01s
	 ==> vmware-iso.fedora42srv: [157/278] libnfsidmap-1:2.8.4-0.fc42.x8 100% | 773.8 KiB/s |  62.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [158/278] libmodulemd-0:2.15.2-1.fc42.x 100% |   2.6 MiB/s | 234.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [159/278] libnvme-0:1.15-2.fc42.x86_64  100% |   1.3 MiB/s | 117.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [160/278] libselinux-0:3.8-3.fc42.x86_6 100% |   1.1 MiB/s |  96.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [161/278] python3-libselinux-0:3.8-3.fc 100% |   1.8 MiB/s | 200.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [162/278] libselinux-utils-0:3.8-3.fc42 100% |   1.2 MiB/s | 119.9 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [163/278] libsemanage-0:3.8.1-2.fc42.x8 100% |   1.4 MiB/s | 123.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [164/278] python3-libsemanage-0:3.8.1-2 100% | 837.4 KiB/s |  80.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [165/278] libsolv-0:0.7.35-1.fc42.x86_6 100% |   4.8 MiB/s | 446.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [166/278] libsss_certmap-0:2.11.1-2.fc4 100% | 970.6 KiB/s |  77.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [167/278] sssd-common-0:2.11.1-2.fc42.x 100% |  12.7 MiB/s |   1.5 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [168/278] sssd-proxy-0:2.11.1-2.fc42.x8 100% | 790.0 KiB/s |  66.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [169/278] sssd-krb5-common-0:2.11.1-2.f 100% |   1.2 MiB/s |  90.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [170/278] sssd-nfs-idmap-0:2.11.1-2.fc4 100% | 414.5 KiB/s |  32.3 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [171/278] sssd-kcm-0:2.11.1-2.fc42.x86_ 100% |   1.2 MiB/s |  99.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [172/278] sssd-client-0:2.11.1-2.fc42.x 100% |   1.8 MiB/s | 147.3 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [173/278] libsss_nss_idmap-0:2.11.1-2.f 100% | 535.4 KiB/s |  40.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [174/278] libsss_idmap-0:2.11.1-2.fc42. 100% | 476.3 KiB/s |  37.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [175/278] libsss_sudo-0:2.11.1-2.fc42.x 100% | 404.2 KiB/s |  29.9 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [176/278] libtirpc-0:1.3.7-1.fc42.x86_6 100% |   1.2 MiB/s |  95.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [177/278] libstdc++-0:15.2.1-3.fc42.x86 100% |   9.2 MiB/s | 919.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [178/278] libudisks2-0:2.10.91-1.fc42.x 100% |   2.2 MiB/s | 218.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [179/278] udisks2-0:2.10.91-1.fc42.x86_ 100% |   5.1 MiB/s | 547.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [180/278] udisks2-lvm2-0:2.10.91-1.fc42 100% |   2.3 MiB/s | 217.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [181/278] udisks2-iscsi-0:2.10.91-1.fc4 100% |   2.2 MiB/s | 202.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [182/278] libusb1-0:1.0.29-4.fc42.x86_6 100% | 974.0 KiB/s |  79.9 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [183/278] libuv-1:1.51.0-1.fc42.x86_64  100% |   3.2 MiB/s | 266.3 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [184/278] libxcrypt-0:4.4.38-7.fc42.x86 100% |   1.3 MiB/s | 127.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [185/278] lua-libs-0:5.4.8-1.fc42.x86_6 100% |   1.3 MiB/s | 131.9 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [186/278] mdadm-0:4.3-8.fc42.x86_64     100% |   4.2 MiB/s | 449.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [187/278] mpdecimal-0:4.0.1-1.fc42.x86_ 100% |   1.1 MiB/s |  97.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [188/278] microcode_ctl-2:2.1-70.fc42.x 100% |  25.1 MiB/s |  10.5 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [189/278] nfs-utils-1:2.8.4-0.fc42.x86_ 100% |   5.0 MiB/s | 476.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [190/278] nspr-0:4.37.0-4.fc42.x86_64   100% |   1.5 MiB/s | 137.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [191/278] nss-0:3.117.0-1.fc42.x86_64   100% |   7.1 MiB/s | 715.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [192/278] mt7xxx-firmware-0:20251021-1. 100% |  24.3 MiB/s |  17.7 MiB |  00m01s
	 ==> vmware-iso.fedora42srv: [193/278] nss-softokn-0:3.117.0-1.fc42. 100% |   2.9 MiB/s | 430.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [194/278] nss-util-0:3.117.0-1.fc42.x86 100% |   1.1 MiB/s |  86.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [195/278] nss-softokn-freebl-0:3.117.0- 100% |   3.8 MiB/s | 329.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [196/278] nss-sysinit-0:3.117.0-1.fc42. 100% | 236.1 KiB/s |  18.9 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [197/278] ntfs-3g-2:2022.10.3-9.fc42.x8 100% |   1.2 MiB/s | 127.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [198/278] linux-firmware-0:20251021-1.f 100% |  28.2 MiB/s |  41.7 MiB |  00m01s
	 ==> vmware-iso.fedora42srv: [199/278] ntfs-3g-libs-2:2022.10.3-9.fc 100% | 473.4 KiB/s | 175.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [200/278] ntfsprogs-2:2022.10.3-9.fc42. 100% |   1.1 MiB/s | 380.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [201/278] open-vm-tools-0:13.0.0-1.fc42 100% |   7.9 MiB/s | 844.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [202/278] nxpwireless-firmware-0:202510 100% |   7.5 MiB/s | 930.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [203/278] openldap-0:2.6.10-1.fc42.x86_ 100% |   2.7 MiB/s | 258.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [204/278] opensc-0:0.26.1-3.fc42.x86_64 100% |   4.4 MiB/s | 414.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [205/278] openssh-0:9.9p1-11.fc42.x86_6 100% |   3.9 MiB/s | 353.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [206/278] opensc-libs-0:0.26.1-3.fc42.x 100% |   8.1 MiB/s | 917.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [207/278] openssh-server-0:9.9p1-11.fc4 100% |   5.4 MiB/s | 540.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [208/278] openssh-clients-0:9.9p1-11.fc 100% |   7.2 MiB/s | 767.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [209/278] openssl-1:3.2.6-2.fc42.x86_64 100% |   8.2 MiB/s |   1.1 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [210/278] openssl-libs-1:3.2.6-2.fc42.x 100% |  12.8 MiB/s |   2.3 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [211/278] p11-kit-0:0.25.8-1.fc42.x86_6 100% |   4.3 MiB/s | 503.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [212/278] p11-kit-trust-0:0.25.8-1.fc42 100% |   1.1 MiB/s | 139.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [213/278] pam-0:1.7.0-6.fc42.x86_64     100% |   3.6 MiB/s | 556.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [214/278] pam-libs-0:1.7.0-6.fc42.x86_6 100% | 500.3 KiB/s |  57.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [215/278] passim-libs-0:0.1.10-1.fc42.x 100% | 298.4 KiB/s |  33.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [216/278] pciutils-0:3.14.0-1.fc42.x86_ 100% | 860.1 KiB/s | 124.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [217/278] pciutils-libs-0:3.14.0-1.fc42 100% | 457.7 KiB/s |  52.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [218/278] pcre2-0:10.46-1.fc42.x86_64   100% |   3.0 MiB/s | 262.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [219/278] pcre2-syntax-0:10.46-1.fc42.n 100% |   2.0 MiB/s | 162.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [220/278] pixman-0:0.46.2-1.fc42.x86_64 100% |   3.4 MiB/s | 292.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [221/278] plymouth-0:24.004.60-19.fc42. 100% |   1.1 MiB/s | 127.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [222/278] plymouth-scripts-0:24.004.60- 100% | 209.2 KiB/s |  18.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [223/278] plymouth-core-libs-0:24.004.6 100% |   1.3 MiB/s | 122.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [224/278] polkit-0:126-3.fc42.1.x86_64  100% |   1.5 MiB/s | 160.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [225/278] polkit-libs-0:126-3.fc42.1.x8 100% | 687.5 KiB/s |  67.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [226/278] procps-ng-0:4.0.4-6.fc42.1.x8 100% |   3.4 MiB/s | 364.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [227/278] protobuf-c-0:1.5.1-1.fc42.x86 100% | 220.3 KiB/s |  32.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [228/278] publicsuffix-list-dafsa-0:202 100% | 484.9 KiB/s |  59.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [229/278] python3-0:3.13.9-1.fc42.x86_6 100% | 394.9 KiB/s |  30.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [230/278] python-pip-wheel-0:24.3.1-5.f 100% |  10.5 MiB/s |   1.2 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [231/278] python3-argcomplete-0:3.6.2-2 100% | 988.1 KiB/s |  97.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [232/278] python3-augeas-0:1.2.0-1.fc42 100% | 518.4 KiB/s |  47.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [233/278] python3-libs-0:3.13.9-1.fc42. 100% |  24.6 MiB/s |   9.2 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [234/278] python3-requests-0:2.32.4-1.f 100% |   1.0 MiB/s | 158.9 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [235/278] python3-setools-0:4.5.1-6.fc4 100% |   5.6 MiB/s | 727.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [236/278] python3-setuptools-0:74.1.3-7 100% |  11.8 MiB/s |   2.0 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [237/278] realmd-0:0.17.1-17.fc42.x86_6 100% |   1.7 MiB/s | 248.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [238/278] rpcbind-0:1.2.8-0.fc42.x86_64 100% | 449.2 KiB/s |  58.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [239/278] realtek-firmware-0:20251021-1 100% |  12.4 MiB/s |   5.3 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [240/278] rsyslog-0:8.2508.0-1.fc42.x86 100% |   3.5 MiB/s | 832.3 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [241/278] selinux-policy-0:42.13-1.fc42 100% | 656.0 KiB/s |  61.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [242/278] nvidia-gpu-firmware-0:2025102 100% |  28.7 MiB/s |  99.3 MiB |  00m03s
	 ==> vmware-iso.fedora42srv: [243/278] smartmontools-1:7.5-3.fc42.x8 100% | 907.1 KiB/s | 669.5 KiB |  00m01s
	 ==> vmware-iso.fedora42srv: [244/278] smartmontools-selinux-1:7.5-3 100% | 358.7 KiB/s |  32.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [245/278] sos-0:4.10.0-1.fc42.noarch    100% |   9.9 MiB/s |   1.3 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [246/278] selinux-policy-targeted-0:42. 100% |   6.6 MiB/s |   6.8 MiB |  00m01s
	 ==> vmware-iso.fedora42srv: [247/278] sqlite-libs-0:3.47.2-5.fc42.x 100% |   4.5 MiB/s | 753.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [248/278] sudo-0:1.9.17-2.p1.fc42.x86_6 100% |  10.2 MiB/s |   1.3 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [249/278] systemd-libs-0:257.10-1.fc42. 100% |   8.5 MiB/s | 809.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [250/278] systemd-pam-0:257.10-1.fc42.x 100% |   3.5 MiB/s | 410.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [251/278] systemd-shared-0:257.10-1.fc4 100% |  13.9 MiB/s |   1.8 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [252/278] systemd-udev-0:257.10-1.fc42. 100% |  17.0 MiB/s |   2.4 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [253/278] systemd-resolved-0:257.10-1.f 100% |   3.5 MiB/s | 311.3 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [254/278] systemd-0:257.10-1.fc42.x86_6 100% |  11.0 MiB/s |   4.0 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [255/278] systemd-oomd-defaults-0:257.1 100% | 288.8 KiB/s |  28.9 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [256/278] systemd-sysusers-0:257.10-1.f 100% | 783.3 KiB/s |  66.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [257/278] tcpdump-14:4.99.5-4.fc42.x86_ 100% |   3.3 MiB/s | 501.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [258/278] unbound-libs-0:1.24.1-1.fc42. 100% |   4.8 MiB/s | 564.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [259/278] tiwilink-firmware-0:20251021- 100% |  20.3 MiB/s |   4.6 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [260/278] usb_modeswitch-0:2.6.2-4.fc42 100% | 799.8 KiB/s |  73.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [261/278] vim-data-2:9.1.1818-1.fc42.no 100% | 203.6 KiB/s |  17.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [262/278] vim-enhanced-2:9.1.1818-1.fc4 100% |  13.4 MiB/s |   2.0 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [263/278] vim-common-2:9.1.1818-1.fc42. 100% |  26.6 MiB/s |   8.1 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [264/278] vim-minimal-2:9.1.1818-1.fc42 100% |   5.9 MiB/s | 848.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [265/278] vim-default-editor-2:9.1.1818 100% | 172.6 KiB/s |  13.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [266/278] vim-filesystem-2:9.1.1818-1.f 100% | 198.2 KiB/s |  15.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [267/278] wget2-libs-0:2.2.0-5.fc42.x86 100% |   1.4 MiB/s | 147.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [268/278] wget2-0:2.2.0-5.fc42.x86_64   100% |   2.6 MiB/s | 280.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [269/278] wget2-wget-0:2.2.0-5.fc42.x86 100% | 105.8 KiB/s |   9.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [270/278] which-0:2.23-2.fc42.x86_64    100% | 509.0 KiB/s |  41.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [271/278] whois-0:5.6.5-1.fc42.x86_64   100% | 737.6 KiB/s |  66.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [272/278] whois-nls-0:5.6.5-1.fc42.noar 100% | 465.5 KiB/s |  37.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [273/278] wireless-regdb-0:2025.10.07-1 100% | 204.9 KiB/s |  16.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [274/278] xxd-2:9.1.1818-1.fc42.x86_64  100% | 345.2 KiB/s |  31.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [275/278] xz-1:5.8.1-2.fc42.x86_64      100% |   5.8 MiB/s | 572.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [276/278] wpa_supplicant-1:2.11-6.fc42. 100% |   8.8 MiB/s |   1.7 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [277/278] xz-libs-1:5.8.1-2.fc42.x86_64 100% |   1.3 MiB/s | 113.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [278/278] zlib-ng-compat-0:2.2.5-2.fc42 100% | 800.1 KiB/s |  79.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: --------------------------------------------------------------------------------
	 ==> vmware-iso.fedora42srv: [278/278] Total                         100% |  34.1 MiB/s | 709.9 MiB |  00m21s
	 ==> vmware-iso.fedora42srv: Running transaction
	 ==> vmware-iso.fedora42srv: [  1/545] Verify package files          100% |  81.0   B/s | 278.0   B |  00m03s
	 ==> vmware-iso.fedora42srv: [  2/545] Prepare transaction           100% |   1.5 KiB/s | 543.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [  3/545] Upgrading libgcc-0:15.2.1-3.f 100% |   6.4 MiB/s | 268.3 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [  4/545] Upgrading filesystem-0:3.18-4 100% |   1.5 MiB/s | 212.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [  5/545] Upgrading glibc-langpack-en-0 100% |  89.0 MiB/s |   5.8 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [  6/545] Upgrading glibc-0:2.41-11.fc4 100% |  14.9 MiB/s |   6.7 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [  7/545] Upgrading glibc-common-0:2.41 100% |  28.3 MiB/s |   1.0 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [  8/545] Upgrading glibc-gconv-extra-0 100% |  84.0 MiB/s |   7.3 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [  9/545] Upgrading systemd-libs-0:257. 100% | 159.7 MiB/s |   2.2 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 10/545] Upgrading zlib-ng-compat-0:2. 100% |  67.6 MiB/s | 138.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 11/545] Upgrading linux-firmware-when 100% | 170.0 MiB/s | 348.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 12/545] Upgrading audit-libs-0:4.1.2- 100% |  46.6 MiB/s | 381.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 13/545] Upgrading libstdc++-0:15.2.1- 100% |  81.0 MiB/s |   2.8 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 14/545] Upgrading xz-libs-1:5.8.1-2.f 100% |  15.3 MiB/s | 218.9 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 15/545] Upgrading crypto-policies-0:2 100% |  10.2 MiB/s | 167.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 16/545] Upgrading sqlite-libs-0:3.47. 100% | 189.1 MiB/s |   1.5 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 17/545] Upgrading alternatives-0:1.33 100% |   2.6 MiB/s |  63.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 18/545] Upgrading nspr-0:4.37.0-4.fc4 100% |  77.5 MiB/s | 317.3 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 19/545] Upgrading nss-util-0:3.117.0- 100% |  67.0 MiB/s | 205.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 20/545] Upgrading expat-0:2.7.2-1.fc4 100% |  11.7 MiB/s | 300.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 21/545] Upgrading libxcrypt-0:4.4.38- 100% |  70.1 MiB/s | 287.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 22/545] Upgrading p11-kit-0:0.25.8-1. 100% |  44.0 MiB/s |   2.3 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 23/545] Upgrading protobuf-c-0:1.5.1- 100% |   3.6 MiB/s |  51.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 24/545] Upgrading grub2-common-1:2.12 100% | 166.3 MiB/s |   6.2 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 25/545] Upgrading p11-kit-trust-0:0.2 100% |  11.8 MiB/s | 448.3 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 26/545] Upgrading gnutls-0:3.8.10-1.f 100% | 182.8 MiB/s |   3.8 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 27/545] Upgrading libsolv-0:0.7.35-1. 100% | 158.4 MiB/s | 973.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 28/545] Upgrading elfutils-libelf-0:0 100% | 160.2 MiB/s |   1.1 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 29/545] Upgrading gpgme-0:1.24.3-1.fc 100% |  20.6 MiB/s | 590.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 30/545] Upgrading libusb1-0:1.0.29-4. 100% |  42.2 MiB/s | 172.9 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 31/545] Upgrading libdrm-0:2.4.127-3. 100% |  43.8 MiB/s | 403.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 32/545] Upgrading libeconf-0:0.7.6-2. 100% |  32.3 MiB/s |  66.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 33/545] Upgrading pam-libs-0:1.7.0-6. 100% |  25.2 MiB/s | 129.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 34/545] Upgrading libedit-0:3.1-56.20 100% |  78.7 MiB/s | 241.9 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 35/545] Upgrading libsss_idmap-0:2.11 100% |  24.4 MiB/s |  75.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 36/545] Upgrading ntfs-3g-libs-2:2022 100% |  71.5 MiB/s | 366.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 37/545] Upgrading vim-data-2:9.1.1818 100% |   5.5 MiB/s |  11.3 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 38/545] Upgrading grub2-tools-minimal 100% |  63.1 MiB/s |   3.0 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 39/545] Upgrading grub2-pc-modules-1: 100% |  54.3 MiB/s |   3.2 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 40/545] Upgrading libcomps-0:0.1.22-1 100% |  50.4 MiB/s | 206.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 41/545] Upgrading nss-softokn-freebl- 100% |  63.9 MiB/s | 850.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 42/545] Upgrading nss-softokn-0:3.117 100% | 196.9 MiB/s |   2.0 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 43/545] Upgrading xz-1:5.8.1-2.fc42.x 100% |  34.1 MiB/s |   1.3 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 44/545] Installing iwlwifi-mld-firmwa 100% | 323.2 MiB/s |   7.1 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 45/545] Upgrading linux-firmware-0:20 100% | 223.1 MiB/s |  41.9 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 46/545] Upgrading file-libs-0:5.46-3. 100% | 395.2 MiB/s |  11.9 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 47/545] Upgrading file-0:5.46-3.fc42. 100% |   4.3 MiB/s | 101.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 48/545] Upgrading plymouth-core-libs- 100% |  87.1 MiB/s | 356.9 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 49/545] Upgrading procps-ng-0:4.0.4-6 100% |  28.9 MiB/s |   1.0 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 50/545] Installing libfyaml-0:0.8-7.f 100% |  20.8 MiB/s | 553.3 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 51/545] Upgrading bluez-libs-0:5.84-2 100% |  64.9 MiB/s | 199.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 52/545] Upgrading c-ares-0:1.34.5-1.f 100% |  66.1 MiB/s | 270.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 53/545] Upgrading iptables-libs-0:1.8 100% |  52.0 MiB/s |   1.5 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 54/545] Upgrading libsss_nss_idmap-0: 100% |  40.7 MiB/s |  83.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 55/545] Upgrading libsss_sudo-0:2.11. 100% |  53.5 MiB/s |  54.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 56/545] Upgrading libuv-1:1.51.0-1.fc 100% | 111.9 MiB/s | 573.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 57/545] Upgrading mpdecimal-0:4.0.1-1 100% |  53.4 MiB/s | 218.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 58/545] Upgrading pciutils-libs-0:3.1 100% |  24.5 MiB/s | 100.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 59/545] Upgrading xxd-2:9.1.1818-1.fc 100% |   1.3 MiB/s |  38.3 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 60/545] Upgrading whois-nls-0:5.6.5-1 100% |  43.9 MiB/s | 134.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 61/545] Upgrading vim-filesystem-2:9. 100% | 589.8 KiB/s |   4.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 62/545] Upgrading vim-common-2:9.1.18 100% |  85.1 MiB/s |  37.3 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 63/545] Upgrading pcre2-syntax-0:10.4 100% |  54.2 MiB/s | 277.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 64/545] Upgrading pcre2-0:10.46-1.fc4 100% |  66.5 KiB/s | 699.1 KiB |  00m11s
	 ==> vmware-iso.fedora42srv: [ 65/545] Upgrading libselinux-0:3.8-3. 100% |   7.3 MiB/s | 194.3 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 66/545] Upgrading glib2-0:2.84.4-1.fc 100% | 156.5 MiB/s |  14.7 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 67/545] Upgrading libblockdev-utils-0 100% |  21.7 MiB/s |  44.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 68/545] Upgrading polkit-libs-0:126-3 100% |  65.6 MiB/s | 201.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 69/545] Upgrading libblockdev-0:3.3.1 100% |  60.6 MiB/s | 372.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 70/545] Upgrading json-glib-0:1.10.8- 100% |  53.7 MiB/s | 604.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 71/545] Upgrading libmodulemd-0:2.15. 100% |  27.0 MiB/s | 720.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 72/545] Upgrading libudisks2-0:2.10.9 100% | 143.2 MiB/s |   1.0 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 73/545] Upgrading libxmlb-0:0.3.24-1. 100% |   9.9 MiB/s | 282.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 74/545] Upgrading libselinux-utils-0: 100% |   9.9 MiB/s | 323.3 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 75/545] Upgrading libjcat-0:0.2.5-1.f 100% |   5.4 MiB/s | 216.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 76/545] Upgrading fprintd-0:1.94.5-1. 100% |  22.9 MiB/s | 845.3 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 77/545] Upgrading libblockdev-swap-0: 100% | 885.9 KiB/s |  20.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 78/545] Upgrading libblockdev-smart-0 100% |  13.1 MiB/s |  40.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 79/545] Upgrading libblockdev-part-0: 100% |   7.2 MiB/s |  44.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 80/545] Upgrading libblockdev-lvm-0:3 100% |  23.8 MiB/s |  73.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 81/545] Upgrading libblockdev-loop-0: 100% |   9.9 MiB/s |  20.3 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 82/545] Upgrading libblockdev-fs-0:3. 100% |  35.6 MiB/s | 109.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 83/545] Upgrading NetworkManager-libn 100% | 231.1 MiB/s |   9.9 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 84/545] Upgrading passim-libs-0:0.1.1 100% |  34.8 MiB/s |  71.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 85/545] Upgrading libsemanage-0:3.8.1 100% |  99.7 MiB/s | 306.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 86/545] Upgrading hwdata-0:0.400-1.fc 100% | 309.5 MiB/s |   9.6 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 87/545] Upgrading pciutils-0:3.14.0-1 100% |  10.0 MiB/s | 286.9 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 88/545] Upgrading firewalld-filesyste 100% | 857.4 KiB/s |   1.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 89/545] Upgrading fedora-release-iden 100% |   1.6 MiB/s |   3.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 90/545] Upgrading fedora-release-serv 100% | 121.1 KiB/s | 124.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [ 91/545] Upgrading fedora-release-comm 100% |   4.0 MiB/s |  24.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 92/545] Upgrading elfutils-default-ya 100% | 204.3 KiB/s |   2.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 93/545] Upgrading elfutils-libs-0:0.1 100% | 112.2 MiB/s | 689.3 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 94/545] Upgrading libssh-config-0:0.1 100% |  99.6 KiB/s | 816.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [ 95/545] Upgrading appstream-data-0:42 100% |  34.1 MiB/s |  15.7 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 96/545] Installing gnulib-l10n-0:2024 100% |  58.8 MiB/s | 661.9 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 97/545] Upgrading coreutils-common-0: 100% |  97.8 MiB/s |  11.2 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 98/545] Upgrading openssl-libs-1:3.2. 100% | 269.8 MiB/s |   7.8 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [ 99/545] Upgrading coreutils-0:9.6-6.f 100% |  81.4 MiB/s |   5.5 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [100/545] Upgrading ca-certificates-0:2 100% |   1.6 MiB/s |   2.5 MiB |  00m02s
	 ==> vmware-iso.fedora42srv: [101/545] Upgrading krb5-libs-0:1.21.3- 100% | 152.8 MiB/s |   2.3 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [102/545] Upgrading openldap-0:2.6.10-1 100% | 128.8 MiB/s | 659.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [103/545] Upgrading libtirpc-0:1.3.7-1. 100% |  65.9 MiB/s | 202.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [104/545] Upgrading systemd-shared-0:25 100% | 257.9 MiB/s |   4.6 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [105/545] Upgrading which-0:2.23-2.fc42 100% |   3.5 MiB/s |  85.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [106/545] Upgrading cryptsetup-libs-0:2 100% | 203.4 MiB/s |   2.6 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [107/545] Upgrading pam-0:1.7.0-6.fc42. 100% |  23.0 MiB/s |   1.7 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [108/545] Upgrading libnfsidmap-1:2.8.4 100% |  33.5 MiB/s | 171.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [109/545] Upgrading selinux-policy-0:42 100% |   6.5 KiB/s |  33.1 KiB |  00m05s
	 ==> vmware-iso.fedora42srv: [110/545] Upgrading selinux-policy-targ 100% |  89.8 MiB/s |  14.9 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [111/545] Upgrading libarchive-0:3.8.1- 100% | 186.9 MiB/s | 957.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [112/545] Upgrading libsss_certmap-0:2. 100% |  43.9 MiB/s | 134.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [113/545] Upgrading openssh-0:9.9p1-11. 100% |  40.6 MiB/s |   1.4 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [114/545] Installing cockpit-ws-selinux 100% |   4.4 KiB/s |  45.8 KiB |  00m10s
	 ==> vmware-iso.fedora42srv: >>> Running pre-install scriptlet: smartmontools-selinux-1:7.5-3.fc42.noarch
	 ==> vmware-iso.fedora42srv: >>> Finished pre-install scriptlet: smartmontools-selinux-1:7.5-3.fc42.noarch
	 ==> vmware-iso.fedora42srv: >>> [RPM] libselinux: type 1: /etc/selinux/targeted/contexts/files/file_contexts
	 ==> vmware-iso.fedora42srv: >>> [RPM] libselinux: type 1: /etc/selinux/targeted/contexts/files/file_contexts
	 ==> vmware-iso.fedora42srv: [115/545] Upgrading smartmontools-selin 100% |   2.9 KiB/s |  34.1 KiB |  00m12s
	 ==> vmware-iso.fedora42srv: [116/545] Upgrading sssd-nfs-idmap-0:2. 100% |  14.0 MiB/s |  42.9 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: >>> [RPM] libselinux: type 1: /etc/selinux/targeted/contexts/files/file_contexts
	 ==> vmware-iso.fedora42srv: >>> [RPM] libselinux: type 1: /etc/selinux/targeted/contexts/files/file_contexts
	 ==> vmware-iso.fedora42srv: [117/545] Upgrading vim-enhanced-2:9.1. 100% |  95.4 MiB/s |   4.2 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [118/545] Upgrading systemd-sysusers-0: 100% |   3.3 MiB/s |  84.9 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [119/545] Upgrading systemd-pam-0:257.1 100% |  31.5 MiB/s |   1.1 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [120/545] Upgrading systemd-0:257.10-1. 100% |  63.9 MiB/s |  12.3 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [121/545] Upgrading systemd-udev-0:257. 100% |  23.0 MiB/s |  12.3 MiB |  00m01s
	 ==> vmware-iso.fedora42srv: [122/545] Upgrading dracut-0:107-4.fc42 100% |  19.0 MiB/s |   1.6 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [123/545] Installing kernel-modules-cor 100% |  76.0 MiB/s |  68.9 MiB |  00m01s
	 ==> vmware-iso.fedora42srv: [124/545] Installing kernel-core-0:6.17 100% |  84.4 MiB/s |  29.5 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [125/545] Upgrading polkit-0:126-3.fc42 100% |  10.7 MiB/s | 470.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [126/545] Upgrading iscsi-initiator-uti 100% |   4.7 MiB/s | 164.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [127/545] Upgrading iscsi-initiator-uti 100% |  22.3 MiB/s |   1.4 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [128/545] Upgrading samba-common-2:4.22 100% |  13.8 MiB/s | 212.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [129/545] Upgrading libldb-2:4.22.6-1.f 100% |  27.9 MiB/s | 456.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [130/545] Upgrading libwbclient-2:4.22. 100% |  22.6 MiB/s |  69.3 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [131/545] Upgrading samba-client-libs-2 100% | 205.7 MiB/s |  19.5 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [132/545] Upgrading samba-common-libs-2 100% |  14.2 MiB/s | 261.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [133/545] Installing kernel-modules-0:6 100% |  12.5 MiB/s |  96.1 MiB |  00m08s
	 ==> vmware-iso.fedora42srv: [134/545] Upgrading grub2-tools-1:2.12- 100% | 120.4 MiB/s |   7.7 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [135/545] Upgrading plymouth-0:24.004.6 100% |   8.7 MiB/s | 349.3 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [136/545] Upgrading plymouth-scripts-0: 100% |   1.4 MiB/s |  31.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [137/545] Upgrading wireless-regdb-0:20 100% | 627.0 KiB/s |  14.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [138/545] Upgrading bluez-0:5.84-2.fc42 100% |  59.8 MiB/s |   3.5 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [139/545] Upgrading rpcbind-0:1.2.8-0.f 100% |   2.4 MiB/s | 111.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [140/545] Upgrading wpa_supplicant-1:2. 100% | 107.2 MiB/s |   6.3 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [141/545] Upgrading bind-libs-32:9.18.4 100% | 211.6 MiB/s |   3.6 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [142/545] Upgrading libssh-0:0.11.3-1.f 100% | 139.0 MiB/s | 569.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [143/545] Upgrading libcurl-0:8.11.1-6. 100% |  74.1 MiB/s | 835.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [144/545] Upgrading NetworkManager-1:1. 100% |  17.3 MiB/s |   5.8 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [145/545] Upgrading elfutils-debuginfod 100% |   3.4 MiB/s |  86.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [146/545] Upgrading librepo-0:1.20.0-1. 100% |   2.1 MiB/s | 250.3 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [147/545] Upgrading libdnf5-0:5.2.17.0- 100% | 159.8 MiB/s |   3.8 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [148/545] Upgrading libdnf5-cli-0:5.2.1 100% |  90.4 MiB/s | 925.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [149/545] Upgrading libdnf-0:0.75.0-1.f 100% |  92.6 MiB/s |   2.2 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [150/545] Upgrading dnf5-0:5.2.17.0-1.f 100% |  46.9 MiB/s |   2.8 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [151/545] Upgrading dnf-data-0:4.24.0-1 100% |   6.8 MiB/s |  41.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [152/545] Upgrading binutils-0:2.44-6.f 100% |  88.2 MiB/s |  25.8 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [153/545] Upgrading NetworkManager-wwan 100% |  19.3 MiB/s | 138.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [154/545] Installing tpm2-tss-fapi-0:4. 100% | 122.6 MiB/s | 879.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [155/545] Upgrading sssd-client-0:2.11. 100% |   8.1 MiB/s | 340.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [156/545] Upgrading sssd-common-0:2.11. 100% |  66.5 MiB/s |   5.2 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [157/545] Upgrading sssd-krb5-common-0: 100% |  54.0 MiB/s | 221.3 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [158/545] Upgrading python-pip-wheel-0: 100% | 138.3 MiB/s |   1.2 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [159/545] Upgrading python3-libs-0:3.13 100% | 136.3 MiB/s |  40.5 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [160/545] Upgrading python3-0:3.13.9-1. 100% | 609.2 KiB/s |  30.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [161/545] Upgrading cockpit-bridge-0:34 100% |  35.3 MiB/s |   1.9 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [162/545] Upgrading cockpit-system-0:34 100% | 115.8 MiB/s |   3.0 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [163/545] Upgrading python3-libdnf-0:0. 100% | 219.8 MiB/s |   3.7 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [164/545] Upgrading python3-hawkey-0:0. 100% |  72.5 MiB/s | 297.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [165/545] Upgrading python3-firewall-0: 100% |  70.7 MiB/s |   2.8 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [166/545] Upgrading python3-libcomps-0: 100% |  34.6 MiB/s | 141.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [167/545] Upgrading python3-libselinux- 100% |  74.5 MiB/s | 610.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [168/545] Upgrading python3-setuptools- 100% |  58.2 MiB/s |   8.6 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [169/545] Upgrading unbound-libs-0:1.24 100% | 145.1 MiB/s |   1.5 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [170/545] Upgrading gnutls-dane-0:3.8.1 100% |  30.1 MiB/s |  61.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [171/545] Upgrading wget2-libs-0:2.2.0- 100% | 119.4 MiB/s | 366.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [172/545] Upgrading wget2-0:2.2.0-5.fc4 100% |  34.0 MiB/s |   1.1 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [173/545] Upgrading audit-rules-0:4.1.2 100% |   2.1 MiB/s | 120.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: >>> Running post-install scriptlet: audit-rules-0:4.1.2-2.fc42.x86_64
	 ==> vmware-iso.fedora42srv: >>> Finished post-install scriptlet: audit-rules-0:4.1.2-2.fc42.x86_64
	 ==> vmware-iso.fedora42srv: >>> Scriptlet output:
	 ==> vmware-iso.fedora42srv: >>> No rules detected, adding default
	 ==> vmware-iso.fedora42srv: >>> No rules
	 ==> vmware-iso.fedora42srv: >>>
	 ==> vmware-iso.fedora42srv: [174/545] Upgrading mdadm-0:4.3-8.fc42. 100% |  21.7 MiB/s |   1.0 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [175/545] Upgrading libblockdev-mdraid- 100% |  15.8 MiB/s |  32.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [176/545] Upgrading nss-0:3.117.0-1.fc4 100% | 110.9 MiB/s |   1.9 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [177/545] Upgrading nss-sysinit-0:3.117 100% | 767.7 KiB/s |  19.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [178/545] Upgrading libblockdev-crypto- 100% |  22.3 MiB/s |  68.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [179/545] Upgrading openssl-1:3.2.6-2.f 100% |  33.3 MiB/s |   1.7 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [180/545] Upgrading cockpit-ws-0:347-1. 100% |   6.5 MiB/s |   1.8 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [181/545] Upgrading libnvme-0:1.15-2.fc 100% |  59.3 MiB/s | 303.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [182/545] Upgrading libblockdev-nvme-0: 100% |  23.5 MiB/s |  48.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [183/545] Upgrading udisks2-0:2.10.91-1 100% |  20.8 MiB/s |   2.9 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [184/545] Upgrading opensc-libs-0:0.26. 100% | 162.8 MiB/s |   2.3 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [185/545] Upgrading opensc-0:0.26.1-3.f 100% |  26.4 MiB/s |   1.2 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [186/545] Upgrading cockpit-storaged-0: 100% |  12.4 MiB/s | 812.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [187/545] Upgrading udisks2-lvm2-0:2.10 100% | 103.6 MiB/s | 636.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [188/545] Upgrading udisks2-iscsi-0:2.1 100% | 114.0 MiB/s | 583.9 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [189/545] Upgrading cockpit-0:347-1.fc4 100% |  20.6 MiB/s |  63.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [190/545] Upgrading audit-0:4.1.2-2.fc4 100% |   5.6 KiB/s | 507.7 KiB |  01m30s
	 ==> vmware-iso.fedora42srv: >>> Running post-install scriptlet: audit-0:4.1.2-2.fc42.x86_64
	 ==> vmware-iso.fedora42srv: >>> Finished post-install scriptlet: audit-0:4.1.2-2.fc42.x86_64
	 ==> vmware-iso.fedora42srv: >>> Scriptlet output:
	 ==> vmware-iso.fedora42srv: >>> Warning: The unit file, source configuration file or drop-ins of auditd.serv
	 ==> vmware-iso.fedora42srv: >>> Job for auditd.service failed because a timeout was exceeded.
	 ==> vmware-iso.fedora42srv: >>> See "systemctl status auditd.service" and "journalctl -xeu auditd.service" f
	 ==> vmware-iso.fedora42srv: >>>
	 ==> vmware-iso.fedora42srv: [191/545] Upgrading wget2-wget-0:2.2.0- 100% |  18.9 KiB/s | 444.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [192/545] Upgrading python3-setools-0:4 100% |  97.5 MiB/s |   2.9 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [193/545] Upgrading python3-libsemanage 100% | 124.9 MiB/s | 383.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [194/545] Upgrading python3-dnf-0:4.24. 100% |  50.3 MiB/s |   2.7 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [195/545] Upgrading firewalld-0:2.3.1-1 100% |  26.0 MiB/s |   2.1 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [196/545] Upgrading cockpit-networkmana 100% |  98.5 MiB/s | 806.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [197/545] Upgrading cockpit-selinux-0:3 100% |  59.7 MiB/s | 428.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [198/545] Upgrading cockpit-packagekit- 100% |  84.6 MiB/s | 866.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [199/545] Upgrading python3-audit-0:4.1 100% |  93.8 MiB/s | 288.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [200/545] Upgrading crypto-policies-scr 100% |   9.2 MiB/s | 384.9 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [201/545] Upgrading nfs-utils-1:2.8.4-0 100% |   8.2 MiB/s |   1.3 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: >>> Running trigger-install scriptlet: nfs-utils-1:2.8.2-1.rc8.fc42.x86_64
	 ==> vmware-iso.fedora42srv: >>> Finished trigger-install scriptlet: nfs-utils-1:2.8.2-1.rc8.fc42.x86_64
	 ==> vmware-iso.fedora42srv: >>> Scriptlet output:
	 ==> vmware-iso.fedora42srv: >>> Warning: The unit file, source configuration file or drop-ins of gssproxy.se
	 ==> vmware-iso.fedora42srv: >>>
	 ==> vmware-iso.fedora42srv: >>> Running trigger-install scriptlet: nfs-utils-1:2.8.4-0.fc42.x86_64
	 ==> vmware-iso.fedora42srv: >>> Finished trigger-install scriptlet: nfs-utils-1:2.8.4-0.fc42.x86_64
	 ==> vmware-iso.fedora42srv: >>> Scriptlet output:
	 ==> vmware-iso.fedora42srv: >>> Warning: The unit file, source configuration file or drop-ins of gssproxy.se
	 ==> vmware-iso.fedora42srv: >>>
	 ==> vmware-iso.fedora42srv: >>> Running trigger-install scriptlet: nfs-utils-1:2.8.4-0.fc42.x86_64
	 ==> vmware-iso.fedora42srv: >>> Finished trigger-install scriptlet: nfs-utils-1:2.8.4-0.fc42.x86_64
	 ==> vmware-iso.fedora42srv: >>> Scriptlet output:
	 ==> vmware-iso.fedora42srv: >>> Warning: The unit file, source configuration file or drop-ins of gssproxy.se
	 ==> vmware-iso.fedora42srv: >>>
	 ==> vmware-iso.fedora42srv: [202/545] Upgrading python3-argcomplete 100% |  10.8 MiB/s | 330.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [203/545] Upgrading python3-augeas-0:1. 100% |  57.3 MiB/s | 176.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [204/545] Upgrading python3-requests-0: 100% |  47.4 MiB/s | 485.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [205/545] Upgrading sos-0:4.10.0-1.fc42 100% |  29.0 MiB/s |   4.2 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [206/545] Upgrading gdb-headless-0:16.3 100% | 189.7 MiB/s |  15.7 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [207/545] Upgrading sssd-kcm-0:2.11.1-2 100% |  24.7 MiB/s | 227.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [208/545] Upgrading sssd-proxy-0:2.11.1 100% |  53.1 MiB/s | 163.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [209/545] Installing tpm2-tools-0:5.7-3 100% |  36.7 MiB/s |   1.5 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [210/545] Upgrading NetworkManager-blue 100% |  49.7 MiB/s | 101.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [211/545] Upgrading dnf5-plugins-0:5.2. 100% |  76.2 MiB/s |   1.4 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [212/545] Installing libdnf5-plugin-exp 100% |  42.8 MiB/s |  87.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [213/545] Upgrading elfutils-0:0.194-1. 100% |  88.8 MiB/s |   2.9 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [214/545] Upgrading NetworkManager-wifi 100% | 157.2 MiB/s | 321.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [215/545] Upgrading NetworkManager-team 100% |   6.4 MiB/s |  52.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [216/545] Upgrading appstream-0:1.1.0-1 100% | 108.3 MiB/s |   4.3 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [217/545] Upgrading curl-0:8.11.1-6.fc4 100% |  19.2 MiB/s | 453.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [218/545] Upgrading fwupd-0:2.0.16-1.fc 100% |  75.1 MiB/s |   9.1 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [219/545] Upgrading rsyslog-0:8.2508.0- 100% |  61.2 MiB/s |   2.8 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [220/545] Upgrading bind-utils-32:9.18. 100% |  24.3 MiB/s | 672.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [221/545] Upgrading grub2-pc-1:2.12-32. 100% | 277.3 KiB/s | 568.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [222/545] Installing kernel-0:6.17.6-20 100% | 121.1 KiB/s | 124.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [223/545] Upgrading realmd-0:0.17.1-17. 100% |  21.2 MiB/s | 847.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [224/545] Upgrading dracut-config-rescu 100% |   4.8 MiB/s |   5.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [225/545] Upgrading systemd-oomd-defaul 100% |  23.8 KiB/s | 976.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [226/545] Upgrading at-0:3.2.5-16.fc42. 100% |   2.5 MiB/s | 126.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [227/545] Upgrading chrony-0:4.8-1.fc42 100% |  13.6 MiB/s | 694.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [228/545] Upgrading dnsmasq-0:2.90-6.fc 100% |  22.7 MiB/s | 767.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [229/545] Upgrading iputils-0:20250605- 100% |  18.1 MiB/s | 835.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [230/545] Upgrading openssh-server-0:9. 100% |  26.4 MiB/s |   1.4 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [231/545] Upgrading systemd-resolved-0: 100% |  20.1 MiB/s | 677.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [232/545] Upgrading usb_modeswitch-0:2. 100% |   8.9 MiB/s | 219.9 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [233/545] Upgrading vim-default-editor- 100% |   1.2 MiB/s |   1.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [234/545] Upgrading smartmontools-1:7.5 100% |  63.3 MiB/s |   2.3 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [235/545] Upgrading openssh-clients-0:9 100% |  69.4 MiB/s |   2.7 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [236/545] Upgrading sudo-0:1.9.17-2.p1. 100% |  99.4 MiB/s |   5.1 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [237/545] Upgrading cryptsetup-0:2.8.1- 100% |  24.3 MiB/s | 772.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [238/545] Upgrading open-vm-tools-0:13. 100% |  50.6 MiB/s |   3.0 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [239/545] Upgrading iptables-nft-0:1.8. 100% |   7.5 MiB/s | 476.9 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [240/545] Upgrading tcpdump-14:4.99.5-4 100% |  45.0 MiB/s |   1.2 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [241/545] Upgrading fprintd-pam-0:1.94. 100% |   3.4 MiB/s |  31.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [242/545] Upgrading dbus-broker-0:36-6. 100% |  12.3 MiB/s | 389.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [243/545] Upgrading vim-minimal-2:9.1.1 100% |  61.3 MiB/s |   1.7 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [244/545] Upgrading whois-0:5.6.5-1.fc4 100% |   5.9 MiB/s | 174.9 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [245/545] Upgrading iwlwifi-mvm-firmwar 100% | 432.4 MiB/s |  62.7 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [246/545] Upgrading ntfs-3g-2:2022.10.3 100% |  12.9 MiB/s | 316.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [247/545] Upgrading ntfsprogs-2:2022.10 100% |  34.0 MiB/s |   1.0 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [248/545] Upgrading kexec-tools-0:2.0.3 100% |  10.3 MiB/s | 231.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [249/545] Installing qcom-wwan-firmware 100% |  98.2 MiB/s | 301.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [250/545] Upgrading amd-gpu-firmware-0: 100% | 208.2 MiB/s |  25.8 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [251/545] Upgrading amd-ucode-firmware- 100% |  68.9 MiB/s | 423.5 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [252/545] Upgrading atheros-firmware-0: 100% | 359.1 MiB/s |  40.9 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [253/545] Upgrading brcmfmac-firmware-0 100% | 281.0 MiB/s |   9.6 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [254/545] Upgrading cirrus-audio-firmwa 100% |  22.3 MiB/s |   2.1 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [255/545] Upgrading intel-audio-firmwar 100% | 275.4 MiB/s |   3.3 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [256/545] Upgrading intel-gpu-firmware- 100% | 283.2 MiB/s |   8.8 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [257/545] Upgrading intel-vsc-firmware- 100% | 406.2 MiB/s |   7.7 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [258/545] Upgrading iwlegacy-firmware-0 100% | 121.4 MiB/s | 124.3 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [259/545] Upgrading iwlwifi-dvm-firmwar 100% | 304.0 MiB/s |   1.8 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [260/545] Upgrading libertas-firmware-0 100% | 216.6 MiB/s |   1.3 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [261/545] Upgrading mt7xxx-firmware-0:2 100% | 392.8 MiB/s |  18.5 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [262/545] Upgrading nvidia-gpu-firmware 100% | 216.5 MiB/s | 101.1 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [263/545] Upgrading nxpwireless-firmwar 100% | 177.1 MiB/s | 906.9 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [264/545] Upgrading realtek-firmware-0: 100% | 227.9 MiB/s |   5.2 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [265/545] Upgrading tiwilink-firmware-0 100% | 327.6 MiB/s |   4.6 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [266/545] Upgrading btrfs-progs-0:6.16. 100% | 149.8 MiB/s |   6.3 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [267/545] Installing rpm-plugin-systemd 100% |  12.9 MiB/s |  13.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [268/545] Upgrading diffutils-0:3.12-1. 100% |  52.0 MiB/s |   1.6 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [269/545] Upgrading ethtool-2:6.15-3.fc 100% |  39.0 MiB/s | 998.9 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [270/545] Upgrading exfatprogs-0:1.3.0- 100% |  12.1 MiB/s | 297.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [271/545] Upgrading inih-0:62-1.fc42.x8 100% |  23.1 MiB/s |  23.6 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [272/545] Upgrading less-0:679-1.fc42.x 100% |  17.4 MiB/s | 409.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [273/545] Upgrading libgomp-0:15.2.1-3. 100% | 176.8 MiB/s | 543.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [274/545] Upgrading lua-libs-0:5.4.8-1. 100% | 137.7 MiB/s | 282.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [275/545] Upgrading pixman-0:0.46.2-1.f 100% | 231.6 MiB/s | 711.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [276/545] Upgrading publicsuffix-list-d 100% |  68.2 MiB/s |  69.8 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [277/545] Upgrading microcode_ctl-2:2.1 100% | 100.1 MiB/s |  14.4 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [278/545] Upgrading fonts-filesystem-1: 100% | 128.3 KiB/s | 788.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [279/545] Upgrading bash-color-prompt-0 100% |  10.8 MiB/s |  33.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [280/545] Upgrading alsa-sof-firmware-0 100% | 110.8 MiB/s |   9.9 MiB |  00m00s
	 ==> vmware-iso.fedora42srv: [281/545] Removing fwupd-0:2.0.7-2.fc42 100% |   3.0 KiB/s | 139.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [282/545] Removing elfutils-0:0.192-9.f 100% |   2.8 KiB/s |  67.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [283/545] Removing gdb-headless-0:16.2- 100% |   3.4 KiB/s | 204.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [284/545] Removing nfs-utils-1:2.8.2-1. 100% |   3.3 KiB/s | 151.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [285/545] Removing binutils-0:2.44-3.fc 100% |  11.0 KiB/s | 247.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [286/545] Removing dnf5-plugins-0:5.2.1 100% |   6.3 KiB/s | 122.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [287/545] Removing dnf5-0:5.2.12.0-1.fc 100% |   3.5 KiB/s | 145.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [288/545] Removing open-vm-tools-0:12.4 100% |   4.1 KiB/s | 189.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [289/545] Removing openssh-server-0:9.9 100% | 911.0   B/s |  31.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [290/545] Removing sudo-0:1.9.15-7.p5.f 100% |   6.5 KiB/s | 160.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [291/545] Removing pam-0:1.7.0-4.fc42.x 100% |  19.9 KiB/s | 346.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [292/545] Removing libdnf5-cli-0:5.2.12 100% |   1.3 KiB/s |  24.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [293/545] Removing rsyslog-0:8.2412.0-3 100% |   2.9 KiB/s | 128.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [294/545] Removing audit-0:4.0.3-2.fc42 100% |   1.5 KiB/s |  47.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [295/545] Removing smartmontools-1:7.4- 100% |   1.0 KiB/s |  43.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [296/545] Removing dbus-broker-0:36-5.f 100% | 666.0   B/s |  16.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [297/545] Removing sssd-kcm-0:2.10.2-3. 100% | 302.0   B/s |  13.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [298/545] Removing appstream-0:1.0.4-2. 100% |   5.1 KiB/s |  73.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [299/545] Removing sssd-proxy-0:2.10.2- 100% | 500.0   B/s |   9.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [300/545] Removing chrony-0:4.6.1-2.fc4 100% | 795.0   B/s |  35.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [301/545] Removing rpcbind-0:1.2.7-1.rc 100% | 488.0   B/s |  21.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [302/545] Removing openssh-clients-0:9. 100% |   3.1 KiB/s |  41.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [303/545] Removing udisks2-iscsi-0:2.10 100% | 312.0   B/s |   5.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [304/545] Removing iscsi-initiator-util 100% |   1.8 KiB/s |  49.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [305/545] Removing elfutils-debuginfod- 100% |   1.2 KiB/s |  15.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [306/545] Removing elfutils-libs-0:0.19 100% |  10.7 KiB/s |  11.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [307/545] Removing udisks2-lvm2-0:2.10. 100% | 277.0   B/s |   5.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [308/545] Removing systemd-resolved-0:2 100% |   1.1 KiB/s |  26.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [309/545] Removing btrfs-progs-0:6.14-1 100% |   2.5 KiB/s |  58.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [310/545] Removing openssh-0:9.9p1-10.f 100% |   2.4 KiB/s |  29.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [311/545] Removing libarchive-0:3.7.7-4 100% |   1.1 KiB/s |  13.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [312/545] Removing libjcat-0:0.2.3-1.fc 100% | 681.0   B/s |  15.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [313/545] Removing bind-utils-32:9.18.3 100% |   4.0 KiB/s |  49.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [314/545] Removing bind-libs-32:9.18.33 100% |   1.8 KiB/s |  24.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [315/545] Removing iscsi-initiator-util 100% | 533.0   B/s |   8.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [316/545] Removing sssd-krb5-common-0:2 100% | 500.0   B/s |   9.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [317/545] Removing sssd-common-0:2.10.2 100% |   3.2 KiB/s | 213.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [318/545] Removing sssd-client-0:2.10.2 100% |   2.4 KiB/s |  49.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [319/545] Removing realmd-0:0.17.1-15.f 100% |   3.4 KiB/s |  90.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [320/545] Removing libuv-1:1.50.0-1.fc4 100% |   9.3 KiB/s |  19.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [321/545] Removing fprintd-pam-0:1.94.4 100% | 388.0   B/s |   7.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [322/545] Removing cryptsetup-0:2.7.5-2 100% |   8.7 KiB/s | 107.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [323/545] Removing libblockdev-lvm-0:3. 100% | 416.0   B/s |   5.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [324/545] Removing pciutils-0:3.13.0-7. 100% | 681.0   B/s |  15.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [325/545] Removing opensc-0:0.26.1-2.fc 100% |   6.0 KiB/s | 148.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [326/545] Removing kexec-tools-0:2.0.30 100% | 608.0   B/s |  14.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [327/545] Removing iputils-0:20240905-3 100% | 736.0   B/s |  42.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [328/545] Removing iptables-nft-0:1.8.1 100% |   2.8 KiB/s | 102.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [329/545] Removing vim-minimal-2:9.1.12 100% | 727.0   B/s |  16.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [330/545] Removing plymouth-0:24.004.60 100% |   8.1 KiB/s | 116.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [331/545] Removing plymouth-core-libs-0 100% | 666.0   B/s |  14.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [332/545] Removing at-0:3.2.5-14.fc42.x 100% |   1.3 KiB/s |  34.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [333/545] Removing iptables-libs-0:1.8. 100% |  14.6 KiB/s | 299.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [334/545] Removing tcpdump-14:4.99.5-3. 100% | 695.0   B/s |  16.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [335/545] Removing ntfsprogs-2:2022.10. 100% |   4.1 KiB/s | 101.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [336/545] Removing dnsmasq-0:2.90-4.fc4 100% |   1.0 KiB/s |  22.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [337/545] Removing NetworkManager-bluet 100% | 222.0   B/s |   4.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [338/545] Removing bluez-0:5.80-1.fc42. 100% |   2.3 KiB/s |  62.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [339/545] Removing NetworkManager-wifi- 100% | 222.0   B/s |   4.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [340/545] Removing wpa_supplicant-1:2.1 100% |   5.0 KiB/s |  66.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [341/545] Removing opensc-libs-0:0.26.1 100% |  13.2 KiB/s |  27.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [342/545] Removing c-ares-0:1.34.4-3.fc 100% | 909.0   B/s |  10.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [343/545] Removing libxmlb-0:0.3.22-1.f 100% | 555.0   B/s |  15.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [344/545] Removing audit-rules-0:4.0.3- 100% |   2.2 KiB/s |  50.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [345/545] Removing ntfs-3g-2:2022.10.3- 100% |   1.2 KiB/s |  27.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [346/545] Removing curl-0:8.11.1-4.fc42 100% |   1.4 KiB/s |  17.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [347/545] Removing NetworkManager-wwan- 100% | 583.0   B/s |   7.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [348/545] Removing fprintd-0:1.94.4-2.f 100% |   7.6 KiB/s | 101.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [349/545] Removing lua-libs-0:5.4.7-3.f 100% |   7.8 KiB/s |   8.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [350/545] Removing python3-libsemanage- 100% |   7.8 KiB/s |   8.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [351/545] Removing libsemanage-0:3.8-1. 100% |  11.7 KiB/s |  12.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [352/545] Removing python3-libselinux-0 100% |   1.9 KiB/s |  21.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [353/545] Removing ethtool-2:6.11-2.fc4 100% | 761.0   B/s |  16.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [354/545] Removing diffutils-0:3.10-9.f 100% |   4.8 KiB/s |  59.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [355/545] Removing ntfs-3g-libs-2:2022. 100% |   6.8 KiB/s |   7.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [356/545] Removing pciutils-libs-0:3.13 100% |   6.8 KiB/s |   7.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [357/545] Removing sssd-nfs-idmap-0:2.1 100% |   8.8 KiB/s |   9.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [358/545] Removing libnfsidmap-1:2.8.2- 100% |  10.7 KiB/s |  22.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [359/545] Removing samba-common-libs-2: 100% |   6.3 KiB/s |  13.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [360/545] Removing libldb-2:4.22.0-20.f 100% |  18.1 KiB/s |  37.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [361/545] Removing samba-client-libs-2: 100% |  37.5 KiB/s | 269.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [362/545] Removing libtirpc-0:1.3.6-1.r 100% |   5.9 KiB/s |  12.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [363/545] Removing libdrm-0:2.4.124-2.f 100% |  12.7 KiB/s |  26.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [364/545] Removing passim-libs-0:0.1.9- 100% | 636.0   B/s |   7.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [365/545] Removing whois-0:5.5.20-5.fc4 100% | 833.0   B/s |  15.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [366/545] Removing python3-setools-0:4. 100% |  19.4 KiB/s | 258.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [367/545] Removing exfatprogs-0:1.2.8-1 100% |   2.6 KiB/s |  29.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [368/545] Removing libsss_nss_idmap-0:2 100% |   7.8 KiB/s |   8.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [369/545] Removing libedit-0:3.1-55.202 100% |   1.0 KiB/s |  11.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [370/545] Removing usb_modeswitch-0:2.6 100% |   1.3 KiB/s |  16.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [371/545] Removing libusb1-0:1.0.28-2.f 100% | 916.0   B/s |  11.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [372/545] Removing less-0:668-2.fc42.x8 100% |   2.0 KiB/s |  23.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [373/545] Removing NetworkManager-team- 100% |   3.9 KiB/s |   4.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [374/545] Removing grub2-pc-1:2.12-28.f 100% | 363.0   B/s |   4.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [375/545] Removing python3-dnf-0:4.23.0 100% |   8.4 KiB/s | 276.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [376/545] Removing firewalld-0:2.3.0-4. 100% |  15.9 KiB/s | 439.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [377/545] Removing smartmontools-selinu 100% | 294.0   B/s |   5.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [378/545] Removing wireless-regdb-0:202 100% | 523.0   B/s |  11.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [379/545] Removing plymouth-scripts-0:2 100% | 363.0   B/s |   4.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [380/545] Removing cockpit-storaged-0:3 100% |  46.9 KiB/s |  48.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [381/545] Removing cockpit-networkmanag 100% |  49.8 KiB/s |  51.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [382/545] Removing cockpit-0:336.2-1.fc 100% |   5.9 KiB/s |   6.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [383/545] Removing fedora-release-commo 100% |   2.0 KiB/s |  29.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [384/545] Removing sos-0:4.8.2-2.fc42.n 100% |  38.8 KiB/s |   1.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [385/545] Removing python3-argcomplete- 100% |   3.2 KiB/s |  73.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [386/545] Removing crypto-policies-scri 100% |   6.7 KiB/s |  76.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [387/545] Removing cockpit-selinux-0:33 100% |  46.9 KiB/s |  48.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [388/545] Removing cockpit-system-0:336 100% | 202.1 KiB/s | 207.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [389/545] Removing cockpit-packagekit-0 100% |   8.4 KiB/s |  95.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [390/545] Removing cockpit-bridge-0:336 100% |  20.6 KiB/s | 253.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [391/545] Removing python3-firewall-0:2 100% | 179.7 KiB/s | 184.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [392/545] Removing dnf-data-0:4.23.0-1. 100% |  11.2 KiB/s |  23.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [393/545] Removing grub2-pc-modules-1:2 100% |  74.5 KiB/s | 305.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [394/545] Removing python3-setuptools-0 100% | 256.8 KiB/s |   1.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [395/545] Removing samba-common-2:4.22. 100% |   2.2 KiB/s |  27.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [396/545] Removing wget2-wget-0:2.2.0-3 100% | 200.0   B/s |   2.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [397/545] Removing vim-default-editor-2 100% |   0.0   B/s |   4.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [398/545] Removing tiwilink-firmware-0: 100% |  39.1 KiB/s |  40.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [399/545] Removing systemd-oomd-default 100% |   2.0 KiB/s |   4.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [400/545] Removing realtek-firmware-0:2 100% | 109.4 KiB/s | 112.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [401/545] Removing python3-requests-0:2 100% |  32.7 KiB/s |  67.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [402/545] Removing python3-augeas-0:1.1 100% |  21.5 KiB/s |  22.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [403/545] Removing nxpwireless-firmware 100% |   9.8 KiB/s |  10.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [404/545] Removing nvidia-gpu-firmware- 100% | 181.6 KiB/s | 558.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [405/545] Removing mt7xxx-firmware-0:20 100% |  46.9 KiB/s |  96.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [406/545] Removing linux-firmware-0:202 100% | 166.3 KiB/s |   1.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [407/545] Removing libertas-firmware-0: 100% |  27.3 KiB/s |  28.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [408/545] Removing iwlwifi-mvm-firmware 100% | 141.6 KiB/s | 145.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [409/545] Removing iwlwifi-dvm-firmware 100% |   0.0   B/s |  14.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [410/545] Removing iwlegacy-firmware-0: 100% |   3.9 KiB/s |   4.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [411/545] Removing intel-vsc-firmware-0 100% |  42.0 KiB/s |  43.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [412/545] Removing intel-gpu-firmware-0 100% |  64.0 KiB/s | 131.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [413/545] Removing intel-audio-firmware 100% |   4.7 KiB/s |  58.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [414/545] Removing dracut-config-rescue 100% |   1.0 KiB/s |   2.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [415/545] Removing cirrus-audio-firmwar 100% | 274.2 KiB/s |   1.1 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [416/545] Removing brcmfmac-firmware-0: 100% |  68.4 KiB/s | 140.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [417/545] Removing atheros-firmware-0:2 100% | 194.3 KiB/s | 398.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [418/545] Removing amd-ucode-firmware-0 100% |  18.6 KiB/s |  19.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [419/545] Removing amd-gpu-firmware-0:2 100% | 293.3 KiB/s | 901.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [420/545] Removing linux-firmware-whenc 100% |   0.0   B/s |   2.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [421/545] Removing fedora-release-ident 100% |   2.9 KiB/s |   6.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [422/545] Removing fedora-release-serve 100% |   0.0   B/s | 100.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [423/545] Removing firewalld-filesystem 100% |   9.8 KiB/s |  10.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [424/545] Removing whois-nls-0:5.5.20-5 100% |  15.6 KiB/s |  16.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [425/545] Removing hwdata-0:0.393-1.fc4 100% |  10.7 KiB/s |  11.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [426/545] Removing elfutils-default-yam 100% | 500.0   B/s |   1.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [427/545] Removing appstream-data-0:42- 100% | 430.0 KiB/s |   3.0 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [428/545] Removing publicsuffix-list-da 100% |   0.0   B/s |   4.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [429/545] Removing microcode_ctl-2:2.1- 100% | 147.5 KiB/s | 151.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [430/545] Removing fonts-filesystem-1:2 100% |   0.0   B/s |   5.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [431/545] Removing bash-color-prompt-0: 100% |   4.9 KiB/s |   5.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [432/545] Removing alsa-sof-firmware-0: 100% |  27.2 KiB/s | 502.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [433/545] Removing NetworkManager-1:1.5 100% | 332.0   B/s |  87.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [434/545] Removing libdnf5-0:5.2.12.0-1 100% |   6.0 KiB/s |  49.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [435/545] Removing cockpit-ws-0:336.2-1 100% |   5.0 KiB/s | 173.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [436/545] Removing udisks2-0:2.10.90-2. 100% |   3.9 KiB/s | 108.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [437/545] Removing libblockdev-crypto-0 100% |   2.4 KiB/s |   5.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [438/545] Removing nss-0:3.109.0-1.fc42 100% | 863.0   B/s |  19.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [439/545] Removing polkit-0:126-2.fc42. 100% |   2.6 KiB/s |  67.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [440/545] Removing nss-softokn-0:3.109. 100% |  12.2 KiB/s |  25.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [441/545] Removing python3-hawkey-0:0.7 100% |  16.6 KiB/s |  17.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [442/545] Removing NetworkManager-libnm 100% |  35.2 KiB/s |  72.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [443/545] Removing python3-libdnf-0:0.7 100% |  27.3 KiB/s |  56.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [444/545] Removing libdnf-0:0.74.0-1.fc 100% |  30.8 KiB/s |  63.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [445/545] Removing libstdc++-0:15.0.1-0 100% |   2.5 KiB/s |  31.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [446/545] Removing openssl-1:3.2.4-3.fc 100% |  13.2 KiB/s | 310.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [447/545] Removing vim-enhanced-2:9.1.1 100% | 333.0   B/s |   7.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [448/545] Removing wget2-0:2.2.0-3.fc42 100% |   3.3 KiB/s |  40.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [449/545] Removing wget2-libs-0:2.2.0-3 100% | 444.0   B/s |   8.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [450/545] Removing grub2-tools-1:2.12-2 100% | 666.0   B/s |  78.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [451/545] Removing dracut-0:105-2.fc42. 100% |  12.6 KiB/s | 452.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [452/545] Removing systemd-udev-0:257.3 100% |   8.5 KiB/s | 586.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [453/545] Removing systemd-0:257.3-7.fc 100% |   4.1 KiB/s | 990.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [454/545] Removing systemd-pam-0:257.3- 100% | 406.0   B/s |  13.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [455/545] Removing procps-ng-0:4.0.4-6. 100% |   3.6 KiB/s |  84.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [456/545] Removing xz-1:5.6.3-3.fc42.x8 100% |  10.1 KiB/s | 124.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [457/545] Removing cryptsetup-libs-0:2. 100% |  10.1 KiB/s |  31.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [458/545] Removing librepo-0:1.19.0-3.f 100% |   3.9 KiB/s |   8.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [459/545] Removing libcurl-0:8.11.1-4.f 100% |   3.4 KiB/s |   7.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [460/545] Removing libssh-0:0.11.1-4.fc 100% |   6.8 KiB/s |  14.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [461/545] Removing krb5-libs-0:1.21.3-5 100% |   3.9 KiB/s |  64.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [462/545] Removing libselinux-utils-0:3 100% |   3.6 KiB/s |  97.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [463/545] Removing systemd-sysusers-0:2 100% | 500.0   B/s |   6.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [464/545] Removing systemd-shared-0:257 100% |   3.4 KiB/s |   7.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [465/545] Removing libblockdev-fs-0:3.3 100% |   4.9 KiB/s |   5.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [466/545] Removing libblockdev-nvme-0:3 100% |   4.9 KiB/s |   5.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [467/545] Removing libnvme-0:1.12-1.fc4 100% |  12.7 KiB/s |  13.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [468/545] Removing pam-libs-0:1.7.0-4.f 100% |  15.6 KiB/s |  16.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [469/545] Removing openldap-0:2.6.9-3.f 100% |   2.1 KiB/s |  26.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [470/545] Removing gpgme-0:1.24.2-1.fc4 100% |   1.4 KiB/s |  17.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [471/545] Removing libsolv-0:0.7.31-5.f 100% |  10.7 KiB/s |  11.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [472/545] Removing libblockdev-loop-0:3 100% |   4.9 KiB/s |   5.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [473/545] Removing libblockdev-mdraid-0 100% | 238.0   B/s |   5.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [474/545] Removing mdadm-0:4.3-7.fc42.x 100% |   1.3 KiB/s |  46.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [475/545] Removing grub2-tools-minimal- 100% |   2.2 KiB/s |  27.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [476/545] Removing gnutls-dane-0:3.8.9- 100% |   4.9 KiB/s |   5.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [477/545] Removing unbound-libs-0:1.22. 100% |   7.3 KiB/s |  15.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [478/545] Removing libblockdev-swap-0:3 100% |   2.4 KiB/s |   5.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [479/545] Removing libblockdev-0:3.3.0- 100% |   5.4 KiB/s |  11.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [480/545] Removing libblockdev-part-0:3 100% | 384.0   B/s |   5.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [481/545] Removing libmodulemd-0:2.15.0 100% |   1.3 KiB/s |  16.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [482/545] Removing nss-softokn-freebl-0 100% |   6.8 KiB/s |  14.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [483/545] Removing polkit-libs-0:126-2. 100% | 916.0   B/s |  11.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [484/545] Removing nss-sysinit-0:3.109. 100% | 636.0   B/s |   7.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [485/545] Removing nss-util-0:3.109.0-1 100% |   5.9 KiB/s |   6.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [486/545] Removing nspr-0:4.36.0-5.fc42 100% |  11.7 KiB/s |  12.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [487/545] Removing libblockdev-smart-0: 100% |   4.9 KiB/s |   5.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [488/545] Removing libblockdev-utils-0: 100% |   4.9 KiB/s |   5.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [489/545] Removing libeconf-0:0.7.6-1.f 100% |  10.7 KiB/s |  11.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [490/545] Removing python3-libcomps-0:0 100% |  13.7 KiB/s |  14.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [491/545] Removing libcomps-0:0.1.21-5. 100% |   7.8 KiB/s |   8.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [492/545] Removing libwbclient-2:4.22.0 100% |   3.9 KiB/s |   4.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [493/545] Removing elfutils-libelf-0:0. 100% |  14.6 KiB/s |  15.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [494/545] Removing libxcrypt-0:4.4.38-6 100% |   1.5 KiB/s |  18.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [495/545] Removing file-0:5.46-1.fc42.x 100% | 909.0   B/s |  10.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [496/545] Removing file-libs-0:5.46-1.f 100% |   1.3 KiB/s |  15.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [497/545] Removing which-0:2.23-1.fc42. 100% |   1.3 KiB/s |  15.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [498/545] Removing json-glib-0:1.10.6-2 100% |  36.1 KiB/s |  74.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [499/545] Removing bluez-libs-0:5.80-1. 100% |   3.4 KiB/s |   7.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [500/545] Removing libsss_certmap-0:2.1 100% |   6.3 KiB/s |  13.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [501/545] Removing pixman-0:0.44.2-2.fc 100% |   6.8 KiB/s |   7.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [502/545] Removing libgomp-0:15.0.1-0.1 100% |   8.8 KiB/s |   9.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [503/545] Removing python3-audit-0:4.0. 100% |  11.7 KiB/s |  12.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [504/545] Removing audit-libs-0:4.0.3-2 100% |   6.8 KiB/s |  14.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [505/545] Removing libudisks2-0:2.10.90 100% | 500.0   B/s |   6.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [506/545] Removing glib2-0:2.84.0-1.fc4 100% |  12.3 KiB/s | 177.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [507/545] Removing gnutls-0:3.8.9-3.fc4 100% |  16.1 KiB/s |  33.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [508/545] Removing libsss_sudo-0:2.10.2 100% |   4.9 KiB/s |   5.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [509/545] Removing libsss_idmap-0:2.10. 100% | 500.0   B/s |   7.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [510/545] Removing python3-0:3.13.2-2.f 100% |   1.0 KiB/s |  12.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [511/545] Removing python3-libs-0:3.13. 100% | 197.3 KiB/s |   2.2 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [512/545] Removing sqlite-libs-0:3.47.2 100% | 500.0   B/s |   7.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [513/545] Removing expat-0:2.7.1-1.fc42 100% |   1.1 KiB/s |  14.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [514/545] Removing xz-libs-1:5.6.3-3.fc 100% |   6.8 KiB/s |   7.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [515/545] Removing mpdecimal-0:4.0.0-2. 100% |   9.8 KiB/s |  10.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [516/545] Removing protobuf-c-0:1.5.0-4 100% |   9.8 KiB/s |  10.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [517/545] Removing inih-0:58-3.fc42.x86 100% |   3.9 KiB/s |   8.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [518/545] Removing vim-common-2:9.1.122 100% | 162.8 KiB/s |   2.4 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [519/545] Removing selinux-policy-0:41. 100% |   1.5 KiB/s |  12.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [520/545] Removing selinux-policy-targe 100% | 143.1 KiB/s |   1.7 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [521/545] Removing python-pip-wheel-0:2 100% | 333.0   B/s |   4.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [522/545] Removing coreutils-0:9.6-2.fc 100% |  16.5 KiB/s | 304.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [523/545] Removing openssl-libs-1:3.2.4 100% |   2.9 KiB/s |  38.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [524/545] Removing ca-certificates-0:20 100% |  55.0 KiB/s | 789.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [525/545] Removing crypto-policies-0:20 100% |  61.8 KiB/s | 190.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [526/545] Removing coreutils-common-0:9 100% |  82.0 KiB/s | 252.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [527/545] Removing vim-data-2:9.1.1227- 100% |   6.8 KiB/s |   7.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [528/545] Removing vim-filesystem-2:9.1 100% |   2.9 KiB/s |  33.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [529/545] Removing grub2-common-1:2.12- 100% |  27.8 KiB/s |  57.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [530/545] Removing libssh-config-0:0.11 100% |   2.9 KiB/s |   3.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [531/545] Removing systemd-libs-0:257.3 100% |   1.5 KiB/s |  21.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [532/545] Removing p11-kit-trust-0:0.25 100% | 631.0   B/s |  12.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [533/545] Removing libselinux-0:3.8-1.f 100% | 666.0   B/s |   8.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [534/545] Removing p11-kit-0:0.25.5-5.f 100% |   4.2 KiB/s |  99.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [535/545] Removing alternatives-0:1.32- 100% |   1.0 KiB/s |  12.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [536/545] Removing pcre2-0:10.45-1.fc42 100% | 818.0   B/s |   9.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [537/545] Removing xxd-2:9.1.1227-1.fc4 100% | 583.0   B/s |   7.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [538/545] Removing zlib-ng-compat-0:2.2 100% |   4.9 KiB/s |   5.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [539/545] Removing pcre2-syntax-0:10.45 100% |   1.4 KiB/s |  16.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [540/545] Removing glibc-0:2.41-1.fc42. 100% |   6.6 KiB/s | 102.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [541/545] Removing glibc-langpack-en-0: 100% | 240.2 KiB/s | 492.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [542/545] Removing glibc-gconv-extra-0: 100% |  24.9 KiB/s | 637.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [543/545] Removing glibc-common-0:2.41- 100% |   1.4 KiB/s |  50.0   B |  00m00s
	 ==> vmware-iso.fedora42srv: [544/545] Removing filesystem-0:3.18-36 100% | 375.5 KiB/s |  16.9 KiB |  00m00s
	 ==> vmware-iso.fedora42srv: [545/545] Removing libgcc-0:15.0.1-0.11 100% |   0.0   B/s |  11.0   B |  01m12s
	 ==> vmware-iso.fedora42srv: >>> Running post-transaction scriptlet: systemd-0:257.10-1.fc42.x86_64
	 ==> vmware-iso.fedora42srv: >>> Finished post-transaction scriptlet: systemd-0:257.10-1.fc42.x86_64
	 ==> vmware-iso.fedora42srv: >>> [RPM] libselinux: type 1: /etc/selinux/targeted/contexts/files/file_contexts
	 ==> vmware-iso.fedora42srv: >>> [RPM] libselinux: type 1: /etc/selinux/targeted/contexts/files/file_contexts
	 ==> vmware-iso.fedora42srv: Complete!
	 ==> vmware-iso.fedora42srv: Removed 18 files, 11 directories (total of 97 MiB). 0 errors occurred.
	 ==> vmware-iso.fedora42srv: Gracefully halting virtual machine...
	 ==> vmware-iso.fedora42srv: Waiting for clean up...
	 ==> vmware-iso.fedora42srv: Deleting unnecessary files...
	 ==> vmware-iso.fedora42srv: Deleting: /vmfs/volumes/datastore1/Fedorasrv42_Demo-20251105220546/Fedorasrv42_Demo-20251105220546.scoreboard
	 ==> vmware-iso.fedora42srv: Deleting: /vmfs/volumes/datastore1/Fedorasrv42_Demo-20251105220546/vmware.log
	 ==> vmware-iso.fedora42srv: Skipping disk compaction...
	 ==> vmware-iso.fedora42srv: Cleaning VMX prior to finishing up...
	 ==> vmware-iso.fedora42srv: Detaching ISO from CD-ROM device ide0:0...
	 ==> vmware-iso.fedora42srv: Disabling VNC server...
	 ==> vmware-iso.fedora42srv: Exporting virtual machine...
	 ==> vmware-iso.fedora42srv: Executing: ovftool --noSSLVerify=true --skipManifestCheck -tt=ova vi://root:%3Cpassword%3E@shuttle01.sc.brunoe.net/Fedorasrv42_Demo-20251105220546 output-artifacts/Fedorasrv42_Demo-20251105220546.ova
	 ==> vmware-iso.fedora42srv: Deleting virtual machine...
	 Build 'vmware-iso.fedora42srv' finished after 12 minutes 10 seconds.

	 ==> Wait completed after 12 minutes 10 seconds

	 ==> Builds finished. The artifacts of successful builds are:
	 --> vmware-iso.fedora42srv: VM files in directory: ./output-artifacts


## fedora42srv\_vsphere.pkr.hcl ##

Variables:
 | Name                 | Description  | Type | Default | Required | Adjust for deployment environment |
 |:---------------------|:-------------|:-----|:--------|:--------:|:--------------------:|
 | remote\_username     | User name for login | string | None | Yes | Yes |
 | remote\_password     | User password for login  | string | None | Yes | Yes |
 | convert\_to\_template| Convert the virtual machine to a template after the build is complete. If set to true, the virtual machine can not be imported into a content library | bool | true | Yes | Yes |
 | datacenter           | Datacenter name | string | None | Yes | Yes |
 | esxi\_server         | esxi server IP/FQDN | string | None | Yes | Yes |
 | output\_directory    | Output directory for VM artifacts |string | ./output-artifacts | Yes | Yes |
 | vcenter\_server      | vCenter Server IP/FQDN | string | None | Yes | Yes |
 | vm\_name             | Virtual Machine name to build  | string | Fedorasrv42\_Demo | Yes | Yes |

### Sample Vsphere iso ###

	./cleanup.sh; packer build -force  fedora42srv_vsphere.pkr.hcl >& log.txt

	vsphere-iso.fedora42srv: output will be in this color.

	==> vsphere-iso.fedora42srv: File /Users/ebruno/.cache/packer/b9942652230ed0bdd2af7b94bdea1b41b2d3c33a.iso already uploaded; continuing
	==> vsphere-iso.fedora42srv: File [datastore1] packer_cache//b9942652230ed0bdd2af7b94bdea1b41b2d3c33a.iso already exists; skipping upload.
	==> vsphere-iso.fedora42srv: Creating virtual machine...
	==> vsphere-iso.fedora42srv: Customizing hardware...
	==> vsphere-iso.fedora42srv: Mounting ISO images...
	==> vsphere-iso.fedora42srv: Adding configuration parameters...
	==> vsphere-iso.fedora42srv: Starting HTTP server on port 8311
	==> vsphere-iso.fedora42srv: Set boot order temporary...
	==> vsphere-iso.fedora42srv: Power on VM...
	==> vsphere-iso.fedora42srv: Waiting 35s for boot...
	==> vsphere-iso.fedora42srv: HTTP server is working at http://10.10.41.211:8311/
	==> vsphere-iso.fedora42srv: Typing boot command...
	==> vsphere-iso.fedora42srv: Waiting for IP...
	==> vsphere-iso.fedora42srv: IP address: 10.10.41.227
	==> vsphere-iso.fedora42srv: Using SSH communicator to connect: 10.10.41.227
	==> vsphere-iso.fedora42srv: Waiting for SSH to become available...
	==> vsphere-iso.fedora42srv: Connected to SSH!
	==> vsphere-iso.fedora42srv: Provisioning with shell script: /var/folders/sw/fs5srh7d2g11p6q8bqbh0rnr0000gn/T/packer-shell2828443186
	[1;31m==> vsphere-iso.fedora42srv: Updating and loading repositories:
	[1;31m==> vsphere-iso.fedora42srv:  Fedora 42 - x86_64 - Updates           100% |   3.9 MiB/s |   9.3 MiB |  00m02s
	[1;31m==> vsphere-iso.fedora42srv:  Fedora 42 - x86_64                     100% |   4.9 MiB/s |  35.4 MiB |  00m07s
	[1;31m==> vsphere-iso.fedora42srv:  Fedora 42 openh264 (From Cisco) - x86_ 100% |   6.1 KiB/s |   5.8 KiB |  00m01s
	[1;31m==> vsphere-iso.fedora42srv: Repositories loaded.
	==> vsphere-iso.fedora42srv: Package                                     Arch   Version                      Repository      Size
	==> vsphere-iso.fedora42srv: Upgrading:
	==> vsphere-iso.fedora42srv:  NetworkManager                             x86_64 1:1.52.1-1.fc42              updates      5.8 MiB
	==> vsphere-iso.fedora42srv:    replacing NetworkManager                 x86_64 1:1.52.0-1.fc42              anaconda     5.8 MiB
	==> vsphere-iso.fedora42srv:  NetworkManager-bluetooth                   x86_64 1:1.52.1-1.fc42              updates    101.1 KiB
	==> vsphere-iso.fedora42srv:    replacing NetworkManager-bluetooth       x86_64 1:1.52.0-1.fc42              anaconda   101.1 KiB
	==> vsphere-iso.fedora42srv:  NetworkManager-libnm                       x86_64 1:1.52.1-1.fc42              updates      9.9 MiB
	==> vsphere-iso.fedora42srv:    replacing NetworkManager-libnm           x86_64 1:1.52.0-1.fc42              anaconda     9.9 MiB
	==> vsphere-iso.fedora42srv:  NetworkManager-team                        x86_64 1:1.52.1-1.fc42              updates     52.1 KiB
	==> vsphere-iso.fedora42srv:    replacing NetworkManager-team            x86_64 1:1.52.0-1.fc42              anaconda    52.1 KiB
	==> vsphere-iso.fedora42srv:  NetworkManager-wifi                        x86_64 1:1.52.1-1.fc42              updates    321.1 KiB
	==> vsphere-iso.fedora42srv:    replacing NetworkManager-wifi            x86_64 1:1.52.0-1.fc42              anaconda   321.1 KiB
	==> vsphere-iso.fedora42srv:  NetworkManager-wwan                        x86_64 1:1.52.1-1.fc42              updates    137.0 KiB
	==> vsphere-iso.fedora42srv:    replacing NetworkManager-wwan            x86_64 1:1.52.0-1.fc42              anaconda   141.0 KiB
	[1;31m==> vsphere-iso.fedora42srv: Total size of inbound packages is 710 MiB. Need to download 710 MiB.
	[1;31m==> vsphere-iso.fedora42srv: After this operation, 352 MiB extra will be used (install 1 GiB, remove 805 MiB).
	==> vsphere-iso.fedora42srv:  alsa-sof-firmware                          noarch 2025.05.1-1.fc42             updates      9.8 MiB
	==> vsphere-iso.fedora42srv:    replacing alsa-sof-firmware              noarch 2025.01-1.fc42               anaconda     8.6 MiB
	==> vsphere-iso.fedora42srv:  alternatives                               x86_64 1.33-1.fc42                  updates     62.2 KiB
	==> vsphere-iso.fedora42srv:    replacing alternatives                   x86_64 1.32-1.fc42                  anaconda    62.2 KiB
	==> vsphere-iso.fedora42srv:  amd-gpu-firmware                           noarch 20251021-1.fc42              updates     25.7 MiB
	==> vsphere-iso.fedora42srv:    replacing amd-gpu-firmware               noarch 20250311-1.fc42              anaconda    24.8 MiB
	==> vsphere-iso.fedora42srv:  amd-ucode-firmware                         noarch 20251021-1.fc42              updates    419.9 KiB
	==> vsphere-iso.fedora42srv:    replacing amd-ucode-firmware             noarch 20250311-1.fc42              anaconda   385.0 KiB
	==> vsphere-iso.fedora42srv:  appstream                                  x86_64 1.1.0-1.fc42                 updates      4.3 MiB
	==> vsphere-iso.fedora42srv:    replacing appstream                      x86_64 1.0.4-2.fc42                 anaconda     4.2 MiB
	==> vsphere-iso.fedora42srv:  appstream-data                             noarch 42-8.fc42                    updates     15.2 MiB
	==> vsphere-iso.fedora42srv:    replacing appstream-data                 noarch 42-7.fc42                    anaconda    15.0 MiB
	==> vsphere-iso.fedora42srv:  at                                         x86_64 3.2.5-16.fc42                updates    121.7 KiB
	==> vsphere-iso.fedora42srv:    replacing at                             x86_64 3.2.5-14.fc42                anaconda   121.7 KiB
	==> vsphere-iso.fedora42srv:  atheros-firmware                           noarch 20251021-1.fc42              updates     40.9 MiB
	==> vsphere-iso.fedora42srv:    replacing atheros-firmware               noarch 20250311-1.fc42              anaconda    36.5 MiB
	==> vsphere-iso.fedora42srv:  audit                                      x86_64 4.1.2-2.fc42                 updates    500.5 KiB
	==> vsphere-iso.fedora42srv:    replacing audit                          x86_64 4.0.3-2.fc42                 anaconda   486.2 KiB
	==> vsphere-iso.fedora42srv:  audit-libs                                 x86_64 4.1.2-2.fc42                 updates    378.8 KiB
	==> vsphere-iso.fedora42srv:    replacing audit-libs                     x86_64 4.0.3-2.fc42                 anaconda   351.3 KiB
	==> vsphere-iso.fedora42srv:  audit-rules                                x86_64 4.1.2-2.fc42                 updates    113.0 KiB
	==> vsphere-iso.fedora42srv:    replacing audit-rules                    x86_64 4.0.3-2.fc42                 anaconda   113.0 KiB
	==> vsphere-iso.fedora42srv:  bash-color-prompt                          noarch 0.7.1-1.fc42                 updates     32.3 KiB
	==> vsphere-iso.fedora42srv:    replacing bash-color-prompt              noarch 0.5-3.fc42                   anaconda    26.3 KiB
	==> vsphere-iso.fedora42srv:  bind-libs                                  x86_64 32:9.18.41-1.fc42            updates      3.6 MiB
	==> vsphere-iso.fedora42srv:    replacing bind-libs                      x86_64 32:9.18.33-1.fc42            anaconda     3.6 MiB
	==> vsphere-iso.fedora42srv:  bind-utils                                 x86_64 32:9.18.41-1.fc42            updates    665.2 KiB
	==> vsphere-iso.fedora42srv:    replacing bind-utils                     x86_64 32:9.18.33-1.fc42            anaconda   665.2 KiB
	==> vsphere-iso.fedora42srv:  binutils                                   x86_64 2.44-6.fc42                  updates     25.8 MiB
	==> vsphere-iso.fedora42srv:    replacing binutils                       x86_64 2.44-3.fc42                  anaconda    25.9 MiB
	==> vsphere-iso.fedora42srv:  bluez                                      x86_64 5.84-2.fc42                  updates      3.5 MiB
	==> vsphere-iso.fedora42srv:    replacing bluez                          x86_64 5.80-1.fc42                  anaconda     3.3 MiB
	==> vsphere-iso.fedora42srv:  bluez-libs                                 x86_64 5.84-2.fc42                  updates    198.3 KiB
	==> vsphere-iso.fedora42srv:    replacing bluez-libs                     x86_64 5.80-1.fc42                  anaconda   198.3 KiB
	==> vsphere-iso.fedora42srv:  brcmfmac-firmware                          noarch 20251021-1.fc42              updates      9.5 MiB
	==> vsphere-iso.fedora42srv:    replacing brcmfmac-firmware              noarch 20250311-1.fc42              anaconda     9.5 MiB
	==> vsphere-iso.fedora42srv:  btrfs-progs                                x86_64 6.16.1-1.fc42                updates      6.3 MiB
	==> vsphere-iso.fedora42srv:    replacing btrfs-progs                    x86_64 6.14-1.fc42                  anaconda     6.2 MiB
	==> vsphere-iso.fedora42srv:  c-ares                                     x86_64 1.34.5-1.fc42                updates    269.1 KiB
	==> vsphere-iso.fedora42srv:    replacing c-ares                         x86_64 1.34.4-3.fc42                anaconda   269.6 KiB
	==> vsphere-iso.fedora42srv:  ca-certificates                            noarch 2025.2.80_v9.0.304-1.0.fc42  updates      2.7 MiB
	==> vsphere-iso.fedora42srv:    replacing ca-certificates                noarch 2024.2.69_v8.0.401-5.fc42    anaconda     2.6 MiB
	==> vsphere-iso.fedora42srv:  chrony                                     x86_64 4.8-1.fc42                   updates    689.9 KiB
	==> vsphere-iso.fedora42srv:    replacing chrony                         x86_64 4.6.1-2.fc42                 anaconda   673.5 KiB
	==> vsphere-iso.fedora42srv:  cirrus-audio-firmware                      noarch 20251021-1.fc42              updates      1.9 MiB
	==> vsphere-iso.fedora42srv:    replacing cirrus-audio-firmware          noarch 20250311-1.fc42              anaconda     1.5 MiB
	==> vsphere-iso.fedora42srv:  cockpit                                    x86_64 347-1.fc42                   updates     61.9 KiB
	==> vsphere-iso.fedora42srv:    replacing cockpit                        x86_64 336.2-1.fc42                 anaconda    59.2 KiB
	==> vsphere-iso.fedora42srv:  cockpit-bridge                             noarch 347-1.fc42                   updates      1.8 MiB
	==> vsphere-iso.fedora42srv:    replacing cockpit-bridge                 noarch 336.2-1.fc42                 anaconda     1.8 MiB
	==> vsphere-iso.fedora42srv:  cockpit-networkmanager                     noarch 347-1.fc42                   updates    798.2 KiB
	==> vsphere-iso.fedora42srv:    replacing cockpit-networkmanager         noarch 336.2-1.fc42                 anaconda   780.4 KiB
	==> vsphere-iso.fedora42srv:  cockpit-packagekit                         noarch 347-1.fc42                   updates    851.4 KiB
	==> vsphere-iso.fedora42srv:    replacing cockpit-packagekit             noarch 336.2-1.fc42                 anaconda   821.6 KiB
	==> vsphere-iso.fedora42srv:  cockpit-selinux                            noarch 347-1.fc42                   updates    420.4 KiB
	==> vsphere-iso.fedora42srv:    replacing cockpit-selinux                noarch 336.2-1.fc42                 anaconda   377.5 KiB
	==> vsphere-iso.fedora42srv:  cockpit-storaged                           noarch 347-1.fc42                   updates    804.9 KiB
	==> vsphere-iso.fedora42srv:    replacing cockpit-storaged               noarch 336.2-1.fc42                 anaconda   788.6 KiB
	==> vsphere-iso.fedora42srv:  cockpit-system                             noarch 347-1.fc42                   updates      3.0 MiB
	==> vsphere-iso.fedora42srv:    replacing cockpit-system                 noarch 336.2-1.fc42                 anaconda     3.1 MiB
	==> vsphere-iso.fedora42srv:  cockpit-ws                                 x86_64 347-1.fc42                   updates      1.8 MiB
	==> vsphere-iso.fedora42srv:    replacing cockpit-ws                     x86_64 336.2-1.fc42                 anaconda     1.6 MiB
	==> vsphere-iso.fedora42srv:  coreutils                                  x86_64 9.6-6.fc42                   updates      5.4 MiB
	==> vsphere-iso.fedora42srv:    replacing coreutils                      x86_64 9.6-2.fc42                   anaconda     5.5 MiB
	==> vsphere-iso.fedora42srv:  coreutils-common                           x86_64 9.6-6.fc42                   updates     11.1 MiB
	==> vsphere-iso.fedora42srv:    replacing coreutils-common               x86_64 9.6-2.fc42                   anaconda    11.1 MiB
	==> vsphere-iso.fedora42srv:  crypto-policies                            noarch 20250707-1.gitad370a8.fc42   updates    142.9 KiB
	==> vsphere-iso.fedora42srv:    replacing crypto-policies                noarch 20250214-1.gitff7551b.fc42   anaconda   137.2 KiB
	==> vsphere-iso.fedora42srv:  crypto-policies-scripts                    noarch 20250707-1.gitad370a8.fc42   updates    370.6 KiB
	==> vsphere-iso.fedora42srv:    replacing crypto-policies-scripts        noarch 20250214-1.gitff7551b.fc42   anaconda   380.2 KiB
	==> vsphere-iso.fedora42srv:  cryptsetup                                 x86_64 2.8.1-1.fc42                 updates    755.6 KiB
	==> vsphere-iso.fedora42srv:    replacing cryptsetup                     x86_64 2.7.5-2.fc42                 anaconda   724.1 KiB
	==> vsphere-iso.fedora42srv:  cryptsetup-libs                            x86_64 2.8.1-1.fc42                 updates      2.6 MiB
	==> vsphere-iso.fedora42srv:    replacing cryptsetup-libs                x86_64 2.7.5-2.fc42                 anaconda     2.3 MiB
	==> vsphere-iso.fedora42srv:  curl                                       x86_64 8.11.1-6.fc42                updates    450.6 KiB
	==> vsphere-iso.fedora42srv:    replacing curl                           x86_64 8.11.1-4.fc42                anaconda   450.6 KiB
	==> vsphere-iso.fedora42srv:  dbus-broker                                x86_64 36-6.fc42                    updates    387.1 KiB
	==> vsphere-iso.fedora42srv:    replacing dbus-broker                    x86_64 36-5.fc42                    anaconda   395.1 KiB
	==> vsphere-iso.fedora42srv:  diffutils                                  x86_64 3.12-1.fc42                  updates      1.6 MiB
	==> vsphere-iso.fedora42srv:    replacing diffutils                      x86_64 3.10-9.fc42                  anaconda     1.6 MiB
	==> vsphere-iso.fedora42srv:  dnf-data                                   noarch 4.24.0-1.fc42                updates     39.8 KiB
	==> vsphere-iso.fedora42srv:    replacing dnf-data                       noarch 4.23.0-1.fc42                anaconda    39.4 KiB
	==> vsphere-iso.fedora42srv:  dnf5                                       x86_64 5.2.17.0-1.fc42              updates      2.8 MiB
	==> vsphere-iso.fedora42srv:    replacing dnf5                           x86_64 5.2.12.0-1.fc42              anaconda     2.3 MiB
	==> vsphere-iso.fedora42srv:  dnf5-plugins                               x86_64 5.2.17.0-1.fc42              updates      1.3 MiB
	==> vsphere-iso.fedora42srv:    replacing dnf5-plugins                   x86_64 5.2.12.0-1.fc42              anaconda     1.2 MiB
	==> vsphere-iso.fedora42srv:  dnsmasq                                    x86_64 2.90-6.fc42                  updates    764.2 KiB
	==> vsphere-iso.fedora42srv:    replacing dnsmasq                        x86_64 2.90-4.fc42                  anaconda   766.8 KiB
	==> vsphere-iso.fedora42srv:  dracut                                     x86_64 107-4.fc42                   updates      1.6 MiB
	==> vsphere-iso.fedora42srv:    replacing dracut                         x86_64 105-2.fc42                   anaconda     1.9 MiB
	==> vsphere-iso.fedora42srv:  dracut-config-rescue                       x86_64 107-4.fc42                   updates      4.5 KiB
	==> vsphere-iso.fedora42srv:    replacing dracut-config-rescue           x86_64 105-2.fc42                   anaconda     4.5 KiB
	==> vsphere-iso.fedora42srv:  elfutils                                   x86_64 0.194-1.fc42                 updates      2.9 MiB
	==> vsphere-iso.fedora42srv:    replacing elfutils                       x86_64 0.192-9.fc42                 anaconda     2.6 MiB
	==> vsphere-iso.fedora42srv:  elfutils-debuginfod-client                 x86_64 0.194-1.fc42                 updates     83.9 KiB
	==> vsphere-iso.fedora42srv:    replacing elfutils-debuginfod-client     x86_64 0.192-9.fc42                 anaconda    79.9 KiB
	==> vsphere-iso.fedora42srv:  elfutils-default-yama-scope                noarch 0.194-1.fc42                 updates      1.8 KiB
	==> vsphere-iso.fedora42srv:    replacing elfutils-default-yama-scope    noarch 0.192-9.fc42                 anaconda     1.8 KiB
	==> vsphere-iso.fedora42srv:  elfutils-libelf                            x86_64 0.194-1.fc42                 updates      1.1 MiB
	==> vsphere-iso.fedora42srv:    replacing elfutils-libelf                x86_64 0.192-9.fc42                 anaconda     1.2 MiB
	==> vsphere-iso.fedora42srv:  elfutils-libs                              x86_64 0.194-1.fc42                 updates    687.4 KiB
	==> vsphere-iso.fedora42srv:    replacing elfutils-libs                  x86_64 0.192-9.fc42                 anaconda   667.0 KiB
	==> vsphere-iso.fedora42srv:  ethtool                                    x86_64 2:6.15-3.fc42                updates    996.4 KiB
	==> vsphere-iso.fedora42srv:    replacing ethtool                        x86_64 2:6.11-2.fc42                anaconda   688.4 KiB
	==> vsphere-iso.fedora42srv:  exfatprogs                                 x86_64 1.3.0-1.fc42                 updates    292.9 KiB
	==> vsphere-iso.fedora42srv:    replacing exfatprogs                     x86_64 1.2.8-1.fc42                 anaconda   242.8 KiB
	==> vsphere-iso.fedora42srv:  expat                                      x86_64 2.7.2-1.fc42                 updates    298.6 KiB
	==> vsphere-iso.fedora42srv:    replacing expat                          x86_64 2.7.1-1.fc42                 anaconda   290.2 KiB
	==> vsphere-iso.fedora42srv:  fedora-release-common                      noarch 42-30                        updates     20.2 KiB
	==> vsphere-iso.fedora42srv:    replacing fedora-release-common          noarch 42-25                        anaconda    20.1 KiB
	==> vsphere-iso.fedora42srv:  fedora-release-identity-server             noarch 42-30                        updates      2.1 KiB
	==> vsphere-iso.fedora42srv:    replacing fedora-release-identity-server noarch 42-25                        anaconda     2.1 KiB
	==> vsphere-iso.fedora42srv:  fedora-release-server                      noarch 42-30                        updates      0.0   B
	==> vsphere-iso.fedora42srv:    replacing fedora-release-server          noarch 42-25                        anaconda     0.0   B
	==> vsphere-iso.fedora42srv:  file                                       x86_64 5.46-3.fc42                  updates    100.2 KiB
	==> vsphere-iso.fedora42srv:    replacing file                           x86_64 5.46-1.fc42                  anaconda   100.2 KiB
	==> vsphere-iso.fedora42srv:  file-libs                                  x86_64 5.46-3.fc42                  updates     11.9 MiB
	==> vsphere-iso.fedora42srv:    replacing file-libs                      x86_64 5.46-1.fc42                  anaconda    11.9 MiB
	==> vsphere-iso.fedora42srv:  filesystem                                 x86_64 3.18-47.fc42                 updates    112.0   B
	==> vsphere-iso.fedora42srv:    replacing filesystem                     x86_64 3.18-36.fc42                 anaconda   112.0   B
	==> vsphere-iso.fedora42srv:  firewalld                                  noarch 2.3.1-1.fc42                 updates      2.0 MiB
	==> vsphere-iso.fedora42srv:    replacing firewalld                      noarch 2.3.0-4.fc42                 anaconda     2.0 MiB
	==> vsphere-iso.fedora42srv:  firewalld-filesystem                       noarch 2.3.1-1.fc42                 updates    239.0   B
	==> vsphere-iso.fedora42srv:    replacing firewalld-filesystem           noarch 2.3.0-4.fc42                 anaconda   239.0   B
	==> vsphere-iso.fedora42srv:  fonts-filesystem                           noarch 1:2.0.5-22.fc42              updates      0.0   B
	==> vsphere-iso.fedora42srv:    replacing fonts-filesystem               noarch 1:2.0.5-21.fc42              anaconda     0.0   B
	==> vsphere-iso.fedora42srv:  fprintd                                    x86_64 1.94.5-1.fc42                updates    829.9 KiB
	==> vsphere-iso.fedora42srv:    replacing fprintd                        x86_64 1.94.4-2.fc42                anaconda   845.9 KiB
	==> vsphere-iso.fedora42srv:  fprintd-pam                                x86_64 1.94.5-1.fc42                updates     30.4 KiB
	==> vsphere-iso.fedora42srv:    replacing fprintd-pam                    x86_64 1.94.4-2.fc42                anaconda    34.3 KiB
	==> vsphere-iso.fedora42srv:  fwupd                                      x86_64 2.0.16-1.fc42                updates      9.1 MiB
	==> vsphere-iso.fedora42srv:    replacing fwupd                          x86_64 2.0.7-2.fc42                 anaconda     8.6 MiB
	==> vsphere-iso.fedora42srv:  gdb-headless                               x86_64 16.3-1.fc42                  updates     15.7 MiB
	==> vsphere-iso.fedora42srv:    replacing gdb-headless                   x86_64 16.2-3.fc42                  anaconda    15.7 MiB
	==> vsphere-iso.fedora42srv:  glib2                                      x86_64 2.84.4-1.fc42                updates     14.7 MiB
	==> vsphere-iso.fedora42srv:    replacing glib2                          x86_64 2.84.0-1.fc42                anaconda    14.7 MiB
	==> vsphere-iso.fedora42srv:  glibc                                      x86_64 2.41-11.fc42                 updates      6.6 MiB
	==> vsphere-iso.fedora42srv:    replacing glibc                          x86_64 2.41-1.fc42                  anaconda     6.6 MiB
	==> vsphere-iso.fedora42srv:  glibc-common                               x86_64 2.41-11.fc42                 updates      1.0 MiB
	==> vsphere-iso.fedora42srv:    replacing glibc-common                   x86_64 2.41-1.fc42                  anaconda     1.0 MiB
	==> vsphere-iso.fedora42srv:  glibc-gconv-extra                          x86_64 2.41-11.fc42                 updates      7.2 MiB
	==> vsphere-iso.fedora42srv:    replacing glibc-gconv-extra              x86_64 2.41-1.fc42                  anaconda     7.2 MiB
	==> vsphere-iso.fedora42srv:  glibc-langpack-en                          x86_64 2.41-11.fc42                 updates      5.7 MiB
	==> vsphere-iso.fedora42srv:    replacing glibc-langpack-en              x86_64 2.41-1.fc42                  anaconda     5.7 MiB
	==> vsphere-iso.fedora42srv:  gnutls                                     x86_64 3.8.10-1.fc42                updates      3.8 MiB
	==> vsphere-iso.fedora42srv:    replacing gnutls                         x86_64 3.8.9-3.fc42                 anaconda     3.6 MiB
	==> vsphere-iso.fedora42srv:  gnutls-dane                                x86_64 3.8.10-1.fc42                updates     60.9 KiB
	==> vsphere-iso.fedora42srv:    replacing gnutls-dane                    x86_64 3.8.9-3.fc42                 anaconda    69.3 KiB
	==> vsphere-iso.fedora42srv:  gpgme                                      x86_64 1.24.3-1.fc42                updates    587.9 KiB
	==> vsphere-iso.fedora42srv:    replacing gpgme                          x86_64 1.24.2-1.fc42                anaconda   591.4 KiB
	==> vsphere-iso.fedora42srv:  grub2-common                               noarch 1:2.12-32.fc42               updates      6.1 MiB
	==> vsphere-iso.fedora42srv:    replacing grub2-common                   noarch 1:2.12-28.fc42               anaconda     6.1 MiB
	==> vsphere-iso.fedora42srv:  grub2-pc                                   x86_64 1:2.12-32.fc42               updates     31.0   B
	==> vsphere-iso.fedora42srv:    replacing grub2-pc                       x86_64 1:2.12-28.fc42               anaconda    31.0   B
	==> vsphere-iso.fedora42srv:  grub2-pc-modules                           noarch 1:2.12-32.fc42               updates      3.2 MiB
	==> vsphere-iso.fedora42srv:    replacing grub2-pc-modules               noarch 1:2.12-28.fc42               anaconda     3.2 MiB
	==> vsphere-iso.fedora42srv:  grub2-tools                                x86_64 1:2.12-32.fc42               updates      7.7 MiB
	==> vsphere-iso.fedora42srv:    replacing grub2-tools                    x86_64 1:2.12-28.fc42               anaconda     7.7 MiB
	==> vsphere-iso.fedora42srv:  grub2-tools-minimal                        x86_64 1:2.12-32.fc42               updates      3.0 MiB
	==> vsphere-iso.fedora42srv:    replacing grub2-tools-minimal            x86_64 1:2.12-28.fc42               anaconda     3.0 MiB
	==> vsphere-iso.fedora42srv:  hwdata                                     noarch 0.400-1.fc42                 updates      9.6 MiB
	==> vsphere-iso.fedora42srv:    replacing hwdata                         noarch 0.393-1.fc42                 anaconda     9.4 MiB
	==> vsphere-iso.fedora42srv:  inih                                       x86_64 62-1.fc42                    updates     22.4 KiB
	==> vsphere-iso.fedora42srv:    replacing inih                           x86_64 58-3.fc42                    anaconda    26.4 KiB
	==> vsphere-iso.fedora42srv:  intel-audio-firmware                       noarch 20251021-1.fc42              updates      3.3 MiB
	==> vsphere-iso.fedora42srv:    replacing intel-audio-firmware           noarch 20250311-1.fc42              anaconda     3.3 MiB
	==> vsphere-iso.fedora42srv:  intel-gpu-firmware                         noarch 20251021-1.fc42              updates      8.8 MiB
	==> vsphere-iso.fedora42srv:    replacing intel-gpu-firmware             noarch 20250311-1.fc42              anaconda     8.7 MiB
	==> vsphere-iso.fedora42srv:  intel-vsc-firmware                         noarch 20251021-1.fc42              updates      7.7 MiB
	==> vsphere-iso.fedora42srv:    replacing intel-vsc-firmware             noarch 20250311-1.fc42              anaconda     7.5 MiB
	==> vsphere-iso.fedora42srv:  iptables-libs                              x86_64 1.8.11-9.fc42                updates      1.5 MiB
	==> vsphere-iso.fedora42srv:    replacing iptables-libs                  x86_64 1.8.11-4.fc42                anaconda     1.8 MiB
	==> vsphere-iso.fedora42srv:  iptables-nft                               x86_64 1.8.11-9.fc42                updates    465.6 KiB
	==> vsphere-iso.fedora42srv:    replacing iptables-nft                   x86_64 1.8.11-4.fc42                anaconda   537.5 KiB
	==> vsphere-iso.fedora42srv:  iputils                                    x86_64 20250605-1.fc42              updates    828.4 KiB
	==> vsphere-iso.fedora42srv:    replacing iputils                        x86_64 20240905-3.fc42              anaconda   760.8 KiB
	==> vsphere-iso.fedora42srv:  iscsi-initiator-utils                      x86_64 6.2.1.11-0.git4b3e853.fc42   updates      1.4 MiB
	==> vsphere-iso.fedora42srv:    replacing iscsi-initiator-utils          x86_64 6.2.1.10-0.gitd0f04ae.fc41.1 anaconda     1.4 MiB
	==> vsphere-iso.fedora42srv:  iscsi-initiator-utils-iscsiuio             x86_64 6.2.1.11-0.git4b3e853.fc42   updates    163.4 KiB
	==> vsphere-iso.fedora42srv:    replacing iscsi-initiator-utils-iscsiuio x86_64 6.2.1.10-0.gitd0f04ae.fc41.1 anaconda   163.7 KiB
	==> vsphere-iso.fedora42srv:  iwlegacy-firmware                          noarch 20251021-1.fc42              updates    123.2 KiB
	==> vsphere-iso.fedora42srv:    replacing iwlegacy-firmware              noarch 20250311-1.fc42              anaconda   123.1 KiB
	==> vsphere-iso.fedora42srv:  iwlwifi-dvm-firmware                       noarch 20251021-1.fc42              updates      1.8 MiB
	==> vsphere-iso.fedora42srv:    replacing iwlwifi-dvm-firmware           noarch 20250311-1.fc42              anaconda     1.8 MiB
	==> vsphere-iso.fedora42srv:  iwlwifi-mvm-firmware                       noarch 20251021-1.fc42              updates     62.7 MiB
	==> vsphere-iso.fedora42srv:    replacing iwlwifi-mvm-firmware           noarch 20250311-1.fc42              anaconda    61.7 MiB
	==> vsphere-iso.fedora42srv:  json-glib                                  x86_64 1.10.8-1.fc42                updates    592.3 KiB
	==> vsphere-iso.fedora42srv:    replacing json-glib                      x86_64 1.10.6-2.fc42                anaconda   590.7 KiB
	==> vsphere-iso.fedora42srv:  kexec-tools                                x86_64 2.0.32-1.fc42                updates    229.4 KiB
	==> vsphere-iso.fedora42srv:    replacing kexec-tools                    x86_64 2.0.30-3.fc42                anaconda   233.4 KiB
	==> vsphere-iso.fedora42srv:  krb5-libs                                  x86_64 1.21.3-6.fc42                updates      2.3 MiB
	==> vsphere-iso.fedora42srv:    replacing krb5-libs                      x86_64 1.21.3-5.fc42                anaconda     2.3 MiB
	==> vsphere-iso.fedora42srv:  less                                       x86_64 679-1.fc42                   updates    406.1 KiB
	==> vsphere-iso.fedora42srv:    replacing less                           x86_64 668-2.fc42                   anaconda   405.8 KiB
	==> vsphere-iso.fedora42srv:  libarchive                                 x86_64 3.8.1-1.fc42                 updates    955.2 KiB
	==> vsphere-iso.fedora42srv:    replacing libarchive                     x86_64 3.7.7-4.fc42                 anaconda   930.6 KiB
	==> vsphere-iso.fedora42srv:  libblockdev                                x86_64 3.3.1-2.fc42                 updates    370.7 KiB
	==> vsphere-iso.fedora42srv:    replacing libblockdev                    x86_64 3.3.0-3.fc42                 anaconda   370.7 KiB
	==> vsphere-iso.fedora42srv:  libblockdev-crypto                         x86_64 3.3.1-2.fc42                 updates     67.6 KiB
	==> vsphere-iso.fedora42srv:    replacing libblockdev-crypto             x86_64 3.3.0-3.fc42                 anaconda    67.6 KiB
	==> vsphere-iso.fedora42srv:  libblockdev-fs                             x86_64 3.3.1-2.fc42                 updates    108.6 KiB
	==> vsphere-iso.fedora42srv:    replacing libblockdev-fs                 x86_64 3.3.0-3.fc42                 anaconda   108.6 KiB
	==> vsphere-iso.fedora42srv:  libblockdev-loop                           x86_64 3.3.1-2.fc42                 updates     19.5 KiB
	==> vsphere-iso.fedora42srv:    replacing libblockdev-loop               x86_64 3.3.0-3.fc42                 anaconda    19.5 KiB
	==> vsphere-iso.fedora42srv:  libblockdev-lvm                            x86_64 3.3.1-2.fc42                 updates     72.3 KiB
	==> vsphere-iso.fedora42srv:    replacing libblockdev-lvm                x86_64 3.3.0-3.fc42                 anaconda    72.3 KiB
	==> vsphere-iso.fedora42srv:  libblockdev-mdraid                         x86_64 3.3.1-2.fc42                 updates     31.7 KiB
	==> vsphere-iso.fedora42srv:    replacing libblockdev-mdraid             x86_64 3.3.0-3.fc42                 anaconda    31.7 KiB
	==> vsphere-iso.fedora42srv:  libblockdev-nvme                           x86_64 3.3.1-2.fc42                 updates     47.4 KiB
	==> vsphere-iso.fedora42srv:    replacing libblockdev-nvme               x86_64 3.3.0-3.fc42                 anaconda    47.4 KiB
	==> vsphere-iso.fedora42srv:  libblockdev-part                           x86_64 3.3.1-2.fc42                 updates     43.4 KiB
	==> vsphere-iso.fedora42srv:    replacing libblockdev-part               x86_64 3.3.0-3.fc42                 anaconda    43.4 KiB
	==> vsphere-iso.fedora42srv:  libblockdev-smart                          x86_64 3.3.1-2.fc42                 updates     39.3 KiB
	==> vsphere-iso.fedora42srv:    replacing libblockdev-smart              x86_64 3.3.0-3.fc42                 anaconda    39.3 KiB
	==> vsphere-iso.fedora42srv:  libblockdev-swap                           x86_64 3.3.1-2.fc42                 updates     19.5 KiB
	==> vsphere-iso.fedora42srv:    replacing libblockdev-swap               x86_64 3.3.0-3.fc42                 anaconda    19.5 KiB
	==> vsphere-iso.fedora42srv:  libblockdev-utils                          x86_64 3.3.1-2.fc42                 updates     43.6 KiB
	==> vsphere-iso.fedora42srv:    replacing libblockdev-utils              x86_64 3.3.0-3.fc42                 anaconda    43.6 KiB
	==> vsphere-iso.fedora42srv:  libcomps                                   x86_64 0.1.22-1.fc42                updates    205.3 KiB
	==> vsphere-iso.fedora42srv:    replacing libcomps                       x86_64 0.1.21-5.fc42                anaconda   209.3 KiB
	==> vsphere-iso.fedora42srv:  libcurl                                    x86_64 8.11.1-6.fc42                updates    834.1 KiB
	==> vsphere-iso.fedora42srv:    replacing libcurl                        x86_64 8.11.1-4.fc42                anaconda   842.1 KiB
	==> vsphere-iso.fedora42srv:  libdnf                                     x86_64 0.75.0-1.fc42                updates      2.2 MiB
	==> vsphere-iso.fedora42srv:    replacing libdnf                         x86_64 0.74.0-1.fc42                anaconda     2.2 MiB
	==> vsphere-iso.fedora42srv:  libdnf5                                    x86_64 5.2.17.0-1.fc42              updates      3.8 MiB
	==> vsphere-iso.fedora42srv:    replacing libdnf5                        x86_64 5.2.12.0-1.fc42              anaconda     3.6 MiB
	==> vsphere-iso.fedora42srv:  libdnf5-cli                                x86_64 5.2.17.0-1.fc42              updates    920.8 KiB
	==> vsphere-iso.fedora42srv:    replacing libdnf5-cli                    x86_64 5.2.12.0-1.fc42              anaconda   867.6 KiB
	==> vsphere-iso.fedora42srv:  libdrm                                     x86_64 2.4.127-3.fc42               updates    399.8 KiB
	==> vsphere-iso.fedora42srv:    replacing libdrm                         x86_64 2.4.124-2.fc42               anaconda   407.9 KiB
	==> vsphere-iso.fedora42srv:  libeconf                                   x86_64 0.7.6-2.fc42                 updates     64.6 KiB
	==> vsphere-iso.fedora42srv:    replacing libeconf                       x86_64 0.7.6-1.fc42                 anaconda    64.6 KiB
	==> vsphere-iso.fedora42srv:  libedit                                    x86_64 3.1-56.20251016cvs.fc42      updates    240.2 KiB
	==> vsphere-iso.fedora42srv:    replacing libedit                        x86_64 3.1-55.20250104cvs.fc42      anaconda   244.1 KiB
	==> vsphere-iso.fedora42srv:  libertas-firmware                          noarch 20251021-1.fc42              updates      1.3 MiB
	==> vsphere-iso.fedora42srv:    replacing libertas-firmware              noarch 20250311-1.fc42              anaconda     1.3 MiB
	==> vsphere-iso.fedora42srv:  libgcc                                     x86_64 15.2.1-3.fc42                updates    266.6 KiB
	==> vsphere-iso.fedora42srv:    replacing libgcc                         x86_64 15.0.1-0.11.fc42             anaconda   266.6 KiB
	==> vsphere-iso.fedora42srv:  libgomp                                    x86_64 15.2.1-3.fc42                updates    541.6 KiB
	==> vsphere-iso.fedora42srv:    replacing libgomp                        x86_64 15.0.1-0.11.fc42             anaconda   537.6 KiB
	==> vsphere-iso.fedora42srv:  libjcat                                    x86_64 0.2.5-1.fc42                 updates    213.8 KiB
	==> vsphere-iso.fedora42srv:    replacing libjcat                        x86_64 0.2.3-1.fc42                 anaconda   209.6 KiB
	==> vsphere-iso.fedora42srv:  libldb                                     x86_64 2:4.22.6-1.fc42              updates    450.8 KiB
	==> vsphere-iso.fedora42srv:    replacing libldb                         x86_64 2:4.22.0-20.fc42             anaconda   451.7 KiB
	==> vsphere-iso.fedora42srv:  libmodulemd                                x86_64 2.15.2-1.fc42                updates    717.7 KiB
	==> vsphere-iso.fedora42srv:    replacing libmodulemd                    x86_64 2.15.0-16.fc42               anaconda   721.0 KiB
	==> vsphere-iso.fedora42srv:  libnfsidmap                                x86_64 1:2.8.4-0.fc42               updates    168.2 KiB
	==> vsphere-iso.fedora42srv:    replacing libnfsidmap                    x86_64 1:2.8.2-1.rc8.fc42           anaconda   168.2 KiB
	==> vsphere-iso.fedora42srv:  libnvme                                    x86_64 1.15-2.fc42                  updates    301.8 KiB
	==> vsphere-iso.fedora42srv:    replacing libnvme                        x86_64 1.12-1.fc42                  anaconda   293.5 KiB
	==> vsphere-iso.fedora42srv:  librepo                                    x86_64 1.20.0-1.fc42                updates    249.0 KiB
	==> vsphere-iso.fedora42srv:    replacing librepo                        x86_64 1.19.0-3.fc42                anaconda   244.9 KiB
	==> vsphere-iso.fedora42srv:  libselinux                                 x86_64 3.8-3.fc42                   updates    193.1 KiB
	==> vsphere-iso.fedora42srv:    replacing libselinux                     x86_64 3.8-1.fc42                   anaconda   193.1 KiB
	==> vsphere-iso.fedora42srv:  libselinux-utils                           x86_64 3.8-3.fc42                   updates    309.1 KiB
	==> vsphere-iso.fedora42srv:    replacing libselinux-utils               x86_64 3.8-1.fc42                   anaconda   309.1 KiB
	==> vsphere-iso.fedora42srv:  libsemanage                                x86_64 3.8.1-2.fc42                 updates    304.4 KiB
	==> vsphere-iso.fedora42srv:    replacing libsemanage                    x86_64 3.8-1.fc42                   anaconda   308.4 KiB
	==> vsphere-iso.fedora42srv:  libsolv                                    x86_64 0.7.35-1.fc42                updates    971.3 KiB
	==> vsphere-iso.fedora42srv:    replacing libsolv                        x86_64 0.7.31-5.fc42                anaconda   940.4 KiB
	==> vsphere-iso.fedora42srv:  libssh                                     x86_64 0.11.3-1.fc42                updates    567.1 KiB
	==> vsphere-iso.fedora42srv:    replacing libssh                         x86_64 0.11.1-4.fc42                anaconda   565.5 KiB
	==> vsphere-iso.fedora42srv:  libssh-config                              noarch 0.11.3-1.fc42                updates    277.0   B
	==> vsphere-iso.fedora42srv:    replacing libssh-config                  noarch 0.11.1-4.fc42                anaconda   277.0   B
	==> vsphere-iso.fedora42srv:  libsss_certmap                             x86_64 2.11.1-2.fc42                updates    132.8 KiB
	==> vsphere-iso.fedora42srv:    replacing libsss_certmap                 x86_64 2.10.2-3.fc42                anaconda   140.3 KiB
	==> vsphere-iso.fedora42srv:  libsss_idmap                               x86_64 2.11.1-2.fc42                updates     73.9 KiB
	==> vsphere-iso.fedora42srv:    replacing libsss_idmap                   x86_64 2.10.2-3.fc42                anaconda    73.7 KiB
	==> vsphere-iso.fedora42srv:  libsss_nss_idmap                           x86_64 2.11.1-2.fc42                updates     82.2 KiB
	==> vsphere-iso.fedora42srv:    replacing libsss_nss_idmap               x86_64 2.10.2-3.fc42                anaconda    82.2 KiB
	==> vsphere-iso.fedora42srv:  libsss_sudo                                x86_64 2.11.1-2.fc42                updates     53.8 KiB
	==> vsphere-iso.fedora42srv:    replacing libsss_sudo                    x86_64 2.10.2-3.fc42                anaconda    53.8 KiB
	==> vsphere-iso.fedora42srv:  libstdc++                                  x86_64 15.2.1-3.fc42                updates      2.8 MiB
	==> vsphere-iso.fedora42srv:    replacing libstdc++                      x86_64 15.0.1-0.11.fc42             anaconda     2.8 MiB
	==> vsphere-iso.fedora42srv:  libtirpc                                   x86_64 1.3.7-1.fc42                 updates    200.4 KiB
	==> vsphere-iso.fedora42srv:    replacing libtirpc                       x86_64 1.3.6-1.rc3.fc42.2           anaconda   199.0 KiB
	==> vsphere-iso.fedora42srv:  libudisks2                                 x86_64 2.10.91-1.fc42               updates      1.0 MiB
	==> vsphere-iso.fedora42srv:    replacing libudisks2                     x86_64 2.10.90-2.fc42               anaconda     1.0 MiB
	==> vsphere-iso.fedora42srv:  libusb1                                    x86_64 1.0.29-4.fc42                updates    171.3 KiB
	==> vsphere-iso.fedora42srv:    replacing libusb1                        x86_64 1.0.28-2.fc42                anaconda   171.0 KiB
	==> vsphere-iso.fedora42srv:  libuv                                      x86_64 1:1.51.0-1.fc42              updates    570.2 KiB
	==> vsphere-iso.fedora42srv:    replacing libuv                          x86_64 1:1.50.0-1.fc42              anaconda   566.8 KiB
	==> vsphere-iso.fedora42srv:  libwbclient                                x86_64 2:4.22.6-1.fc42              updates     68.6 KiB
	==> vsphere-iso.fedora42srv:    replacing libwbclient                    x86_64 2:4.22.0-20.fc42             anaconda    69.3 KiB
	==> vsphere-iso.fedora42srv:  libxcrypt                                  x86_64 4.4.38-7.fc42                updates    284.5 KiB
	==> vsphere-iso.fedora42srv:    replacing libxcrypt                      x86_64 4.4.38-6.fc42                anaconda   284.5 KiB
	==> vsphere-iso.fedora42srv:  libxmlb                                    x86_64 0.3.24-1.fc42                updates    280.3 KiB
	==> vsphere-iso.fedora42srv:    replacing libxmlb                        x86_64 0.3.22-1.fc42                anaconda   280.4 KiB
	==> vsphere-iso.fedora42srv:  linux-firmware                             noarch 20251021-1.fc42              updates     41.8 MiB
	==> vsphere-iso.fedora42srv:    replacing linux-firmware                 noarch 20250311-1.fc42              anaconda    39.9 MiB
	==> vsphere-iso.fedora42srv:  linux-firmware-whence                      noarch 20251021-1.fc42              updates    347.8 KiB
	==> vsphere-iso.fedora42srv:    replacing linux-firmware-whence          noarch 20250311-1.fc42              anaconda   316.2 KiB
	==> vsphere-iso.fedora42srv:  lua-libs                                   x86_64 5.4.8-1.fc42                 updates    280.8 KiB
	==> vsphere-iso.fedora42srv:    replacing lua-libs                       x86_64 5.4.7-3.fc42                 anaconda   280.8 KiB
	==> vsphere-iso.fedora42srv:  mdadm                                      x86_64 4.3-8.fc42                   updates      1.0 MiB
	==> vsphere-iso.fedora42srv:    replacing mdadm                          x86_64 4.3-7.fc42                   anaconda     1.0 MiB
	==> vsphere-iso.fedora42srv:  microcode_ctl                              x86_64 2:2.1-70.fc42                updates     14.4 MiB
	==> vsphere-iso.fedora42srv:    replacing microcode_ctl                  x86_64 2:2.1-69.fc42                anaconda    11.4 MiB
	==> vsphere-iso.fedora42srv:  mpdecimal                                  x86_64 4.0.1-1.fc42                 updates    217.2 KiB
	==> vsphere-iso.fedora42srv:    replacing mpdecimal                      x86_64 4.0.0-2.fc42                 anaconda   216.8 KiB
	==> vsphere-iso.fedora42srv:  mt7xxx-firmware                            noarch 20251021-1.fc42              updates     18.5 MiB
	==> vsphere-iso.fedora42srv:    replacing mt7xxx-firmware                noarch 20250311-1.fc42              anaconda    20.2 MiB
	==> vsphere-iso.fedora42srv:  nfs-utils                                  x86_64 1:2.8.4-0.fc42               updates      1.3 MiB
	==> vsphere-iso.fedora42srv:    replacing nfs-utils                      x86_64 1:2.8.2-1.rc8.fc42           anaconda     1.2 MiB
	==> vsphere-iso.fedora42srv:  nspr                                       x86_64 4.37.0-4.fc42                updates    315.5 KiB
	==> vsphere-iso.fedora42srv:    replacing nspr                           x86_64 4.36.0-5.fc42                anaconda   315.5 KiB
	==> vsphere-iso.fedora42srv:  nss                                        x86_64 3.117.0-1.fc42               updates      1.9 MiB
	==> vsphere-iso.fedora42srv:    replacing nss                            x86_64 3.109.0-1.fc42               anaconda     1.9 MiB
	==> vsphere-iso.fedora42srv:  nss-softokn                                x86_64 3.117.0-1.fc42               updates      2.0 MiB
	==> vsphere-iso.fedora42srv:    replacing nss-softokn                    x86_64 3.109.0-1.fc42               anaconda     1.9 MiB
	==> vsphere-iso.fedora42srv:  nss-softokn-freebl                         x86_64 3.117.0-1.fc42               updates    848.4 KiB
	==> vsphere-iso.fedora42srv:    replacing nss-softokn-freebl             x86_64 3.109.0-1.fc42               anaconda   852.4 KiB
	==> vsphere-iso.fedora42srv:  nss-sysinit                                x86_64 3.117.0-1.fc42               updates     18.1 KiB
	==> vsphere-iso.fedora42srv:    replacing nss-sysinit                    x86_64 3.109.0-1.fc42               anaconda    18.1 KiB
	==> vsphere-iso.fedora42srv:  nss-util                                   x86_64 3.117.0-1.fc42               updates    204.8 KiB
	==> vsphere-iso.fedora42srv:    replacing nss-util                       x86_64 3.109.0-1.fc42               anaconda   204.8 KiB
	==> vsphere-iso.fedora42srv:  ntfs-3g                                    x86_64 2:2022.10.3-9.fc42           updates    312.3 KiB
	==> vsphere-iso.fedora42srv:    replacing ntfs-3g                        x86_64 2:2022.10.3-8.fc42           anaconda   316.3 KiB
	==> vsphere-iso.fedora42srv:  ntfs-3g-libs                               x86_64 2:2022.10.3-9.fc42           updates    364.8 KiB
	==> vsphere-iso.fedora42srv:    replacing ntfs-3g-libs                   x86_64 2:2022.10.3-8.fc42           anaconda   364.8 KiB
	==> vsphere-iso.fedora42srv:  ntfsprogs                                  x86_64 2:2022.10.3-9.fc42           updates    995.4 KiB
	==> vsphere-iso.fedora42srv:    replacing ntfsprogs                      x86_64 2:2022.10.3-8.fc42           anaconda   995.4 KiB
	==> vsphere-iso.fedora42srv:  nvidia-gpu-firmware                        noarch 20251021-1.fc42              updates    101.0 MiB
	==> vsphere-iso.fedora42srv:    replacing nvidia-gpu-firmware            noarch 20250311-1.fc42              anaconda    37.9 MiB
	==> vsphere-iso.fedora42srv:  nxpwireless-firmware                       noarch 20251021-1.fc42              updates    905.2 KiB
	==> vsphere-iso.fedora42srv:    replacing nxpwireless-firmware           noarch 20250311-1.fc42              anaconda   905.2 KiB
	==> vsphere-iso.fedora42srv:  open-vm-tools                              x86_64 13.0.0-1.fc42                updates      3.0 MiB
	==> vsphere-iso.fedora42srv:    replacing open-vm-tools                  x86_64 12.4.0-4.fc42                anaconda     3.1 MiB
	==> vsphere-iso.fedora42srv:  openldap                                   x86_64 2.6.10-1.fc42                updates    655.8 KiB
	==> vsphere-iso.fedora42srv:    replacing openldap                       x86_64 2.6.9-3.fc42                 anaconda   655.1 KiB
	==> vsphere-iso.fedora42srv:  opensc                                     x86_64 0.26.1-3.fc42                updates      1.2 MiB
	==> vsphere-iso.fedora42srv:    replacing opensc                         x86_64 0.26.1-2.fc42                anaconda     1.2 MiB
	==> vsphere-iso.fedora42srv:  opensc-libs                                x86_64 0.26.1-3.fc42                updates      2.3 MiB
	==> vsphere-iso.fedora42srv:    replacing opensc-libs                    x86_64 0.26.1-2.fc42                anaconda     2.3 MiB
	==> vsphere-iso.fedora42srv:  openssh                                    x86_64 9.9p1-11.fc42                updates      1.4 MiB
	==> vsphere-iso.fedora42srv:    replacing openssh                        x86_64 9.9p1-10.fc42                anaconda     1.4 MiB
	==> vsphere-iso.fedora42srv:  openssh-clients                            x86_64 9.9p1-11.fc42                updates      2.7 MiB
	==> vsphere-iso.fedora42srv:    replacing openssh-clients                x86_64 9.9p1-10.fc42                anaconda     2.7 MiB
	==> vsphere-iso.fedora42srv:  openssh-server                             x86_64 9.9p1-11.fc42                updates      1.4 MiB
	==> vsphere-iso.fedora42srv:    replacing openssh-server                 x86_64 9.9p1-10.fc42                anaconda     1.4 MiB
	==> vsphere-iso.fedora42srv:  openssl                                    x86_64 1:3.2.6-2.fc42               updates      1.7 MiB
	==> vsphere-iso.fedora42srv:    replacing openssl                        x86_64 1:3.2.4-3.fc42               anaconda     1.7 MiB
	==> vsphere-iso.fedora42srv:  openssl-libs                               x86_64 1:3.2.6-2.fc42               updates      7.8 MiB
	==> vsphere-iso.fedora42srv:    replacing openssl-libs                   x86_64 1:3.2.4-3.fc42               anaconda     7.8 MiB
	==> vsphere-iso.fedora42srv:  p11-kit                                    x86_64 0.25.8-1.fc42                updates      2.3 MiB
	==> vsphere-iso.fedora42srv:    replacing p11-kit                        x86_64 0.25.5-5.fc42                anaconda     2.2 MiB
	==> vsphere-iso.fedora42srv:  p11-kit-trust                              x86_64 0.25.8-1.fc42                updates    446.5 KiB
	==> vsphere-iso.fedora42srv:    replacing p11-kit-trust                  x86_64 0.25.5-5.fc42                anaconda   395.5 KiB
	==> vsphere-iso.fedora42srv:  pam                                        x86_64 1.7.0-6.fc42                 updates      1.6 MiB
	==> vsphere-iso.fedora42srv:    replacing pam                            x86_64 1.7.0-4.fc42                 anaconda     1.6 MiB
	==> vsphere-iso.fedora42srv:  pam-libs                                   x86_64 1.7.0-6.fc42                 updates    126.7 KiB
	==> vsphere-iso.fedora42srv:    replacing pam-libs                       x86_64 1.7.0-4.fc42                 anaconda   126.7 KiB
	==> vsphere-iso.fedora42srv:  passim-libs                                x86_64 0.1.10-1.fc42                updates     70.1 KiB
	==> vsphere-iso.fedora42srv:    replacing passim-libs                    x86_64 0.1.9-1.fc42                 anaconda    70.1 KiB
	==> vsphere-iso.fedora42srv:  pciutils                                   x86_64 3.14.0-1.fc42                updates    284.1 KiB
	==> vsphere-iso.fedora42srv:    replacing pciutils                       x86_64 3.13.0-7.fc42                anaconda   232.2 KiB
	==> vsphere-iso.fedora42srv:  pciutils-libs                              x86_64 3.14.0-1.fc42                updates     99.4 KiB
	==> vsphere-iso.fedora42srv:    replacing pciutils-libs                  x86_64 3.13.0-7.fc42                anaconda    99.4 KiB
	==> vsphere-iso.fedora42srv:  pcre2                                      x86_64 10.46-1.fc42                 updates    697.7 KiB
	==> vsphere-iso.fedora42srv:    replacing pcre2                          x86_64 10.45-1.fc42                 anaconda   697.7 KiB
	==> vsphere-iso.fedora42srv:  pcre2-syntax                               noarch 10.46-1.fc42                 updates    275.3 KiB
	==> vsphere-iso.fedora42srv:    replacing pcre2-syntax                   noarch 10.45-1.fc42                 anaconda   273.9 KiB
	==> vsphere-iso.fedora42srv:  pixman                                     x86_64 0.46.2-1.fc42                updates    710.3 KiB
	==> vsphere-iso.fedora42srv:    replacing pixman                         x86_64 0.44.2-2.fc42                anaconda   674.2 KiB
	==> vsphere-iso.fedora42srv:  plymouth                                   x86_64 24.004.60-19.fc42            updates    331.0 KiB
	==> vsphere-iso.fedora42srv:    replacing plymouth                       x86_64 24.004.60-18.fc42            anaconda   331.0 KiB
	==> vsphere-iso.fedora42srv:  plymouth-core-libs                         x86_64 24.004.60-19.fc42            updates    354.8 KiB
	==> vsphere-iso.fedora42srv:    replacing plymouth-core-libs             x86_64 24.004.60-18.fc42            anaconda   354.7 KiB
	==> vsphere-iso.fedora42srv:  plymouth-scripts                           x86_64 24.004.60-19.fc42            updates     30.5 KiB
	==> vsphere-iso.fedora42srv:    replacing plymouth-scripts               x86_64 24.004.60-18.fc42            anaconda    30.5 KiB
	==> vsphere-iso.fedora42srv:  polkit                                     x86_64 126-3.fc42.1                 updates    460.0 KiB
	==> vsphere-iso.fedora42srv:    replacing polkit                         x86_64 126-2.fc42                   anaconda   460.0 KiB
	==> vsphere-iso.fedora42srv:  polkit-libs                                x86_64 126-3.fc42.1                 updates    199.8 KiB
	==> vsphere-iso.fedora42srv:    replacing polkit-libs                    x86_64 126-2.fc42                   anaconda   199.8 KiB
	==> vsphere-iso.fedora42srv:  procps-ng                                  x86_64 4.0.4-6.fc42.1               updates      1.0 MiB
	==> vsphere-iso.fedora42srv:    replacing procps-ng                      x86_64 4.0.4-6.fc42                 anaconda     1.0 MiB
	==> vsphere-iso.fedora42srv:  protobuf-c                                 x86_64 1.5.1-1.fc42                 updates     49.8 KiB
	==> vsphere-iso.fedora42srv:    replacing protobuf-c                     x86_64 1.5.0-4.fc41                 anaconda    54.0 KiB
	==> vsphere-iso.fedora42srv:  publicsuffix-list-dafsa                    noarch 20250616-1.fc42              updates     69.1 KiB
	==> vsphere-iso.fedora42srv:    replacing publicsuffix-list-dafsa        noarch 20250116-1.fc42              anaconda    68.5 KiB
	==> vsphere-iso.fedora42srv:  python-pip-wheel                           noarch 24.3.1-5.fc42                updates      1.2 MiB
	==> vsphere-iso.fedora42srv:    replacing python-pip-wheel               noarch 24.3.1-2.fc42                anaconda     1.2 MiB
	==> vsphere-iso.fedora42srv:  python3                                    x86_64 3.13.9-1.fc42                updates     28.7 KiB
	==> vsphere-iso.fedora42srv:    replacing python3                        x86_64 3.13.2-2.fc42                anaconda    27.6 KiB
	==> vsphere-iso.fedora42srv:  python3-argcomplete                        noarch 3.6.2-2.fc42                 updates    316.8 KiB
	==> vsphere-iso.fedora42srv:    replacing python3-argcomplete            noarch 3.6.0-1.fc42                 anaconda   314.5 KiB
	==> vsphere-iso.fedora42srv:  python3-audit                              x86_64 4.1.2-2.fc42                 updates    286.2 KiB
	==> vsphere-iso.fedora42srv:    replacing python3-audit                  x86_64 4.0.3-2.fc42                 anaconda   290.7 KiB
	==> vsphere-iso.fedora42srv:  python3-augeas                             x86_64 1.2.0-1.fc42                 updates    171.8 KiB
	==> vsphere-iso.fedora42srv:    replacing python3-augeas                 noarch 1.1.0-15.fc42                anaconda    94.4 KiB
	==> vsphere-iso.fedora42srv:  python3-dnf                                noarch 4.24.0-1.fc42                updates      2.7 MiB
	==> vsphere-iso.fedora42srv:    replacing python3-dnf                    noarch 4.23.0-1.fc42                anaconda     2.7 MiB
	==> vsphere-iso.fedora42srv:  python3-firewall                           noarch 2.3.1-1.fc42                 updates      2.8 MiB
	==> vsphere-iso.fedora42srv:    replacing python3-firewall               noarch 2.3.0-4.fc42                 anaconda     2.8 MiB
	==> vsphere-iso.fedora42srv:  python3-hawkey                             x86_64 0.75.0-1.fc42                updates    294.2 KiB
	==> vsphere-iso.fedora42srv:    replacing python3-hawkey                 x86_64 0.74.0-1.fc42                anaconda   294.0 KiB
	==> vsphere-iso.fedora42srv:  python3-libcomps                           x86_64 0.1.22-1.fc42                updates    139.3 KiB
	==> vsphere-iso.fedora42srv:    replacing python3-libcomps               x86_64 0.1.21-5.fc42                anaconda   143.3 KiB
	==> vsphere-iso.fedora42srv:  python3-libdnf                             x86_64 0.75.0-1.fc42                updates      3.7 MiB
	==> vsphere-iso.fedora42srv:    replacing python3-libdnf                 x86_64 0.74.0-1.fc42                anaconda     3.7 MiB
	==> vsphere-iso.fedora42srv:  python3-libs                               x86_64 3.13.9-1.fc42                updates     40.1 MiB
	==> vsphere-iso.fedora42srv:    replacing python3-libs                   x86_64 3.13.2-2.fc42                anaconda    39.9 MiB
	==> vsphere-iso.fedora42srv:  python3-libselinux                         x86_64 3.8-3.fc42                   updates    606.8 KiB
	==> vsphere-iso.fedora42srv:    replacing python3-libselinux             x86_64 3.8-1.fc42                   anaconda   606.9 KiB
	==> vsphere-iso.fedora42srv:  python3-libsemanage                        x86_64 3.8.1-2.fc42                 updates    382.2 KiB
	==> vsphere-iso.fedora42srv:    replacing python3-libsemanage            x86_64 3.8-1.fc42                   anaconda   382.2 KiB
	==> vsphere-iso.fedora42srv:  python3-requests                           noarch 2.32.4-1.fc42                updates    473.8 KiB
	==> vsphere-iso.fedora42srv:    replacing python3-requests               noarch 2.32.3-4.fc42                anaconda   483.1 KiB
	==> vsphere-iso.fedora42srv:  python3-setools                            x86_64 4.5.1-6.fc42                 updates      2.9 MiB
	==> vsphere-iso.fedora42srv:    replacing python3-setools                x86_64 4.5.1-5.fc42                 anaconda     2.9 MiB
	==> vsphere-iso.fedora42srv:  python3-setuptools                         noarch 74.1.3-7.fc42                updates      8.4 MiB
	==> vsphere-iso.fedora42srv:    replacing python3-setuptools             noarch 74.1.3-5.fc42                anaconda     8.4 MiB
	==> vsphere-iso.fedora42srv:  realmd                                     x86_64 0.17.1-17.fc42               updates    833.7 KiB
	==> vsphere-iso.fedora42srv:    replacing realmd                         x86_64 0.17.1-15.fc42               anaconda   825.1 KiB
	==> vsphere-iso.fedora42srv:  realtek-firmware                           noarch 20251021-1.fc42              updates      5.2 MiB
	==> vsphere-iso.fedora42srv:    replacing realtek-firmware               noarch 20250311-1.fc42              anaconda     4.6 MiB
	==> vsphere-iso.fedora42srv:  rpcbind                                    x86_64 1.2.8-0.fc42                 updates    108.0 KiB
	==> vsphere-iso.fedora42srv:    replacing rpcbind                        x86_64 1.2.7-1.rc1.fc42.4           anaconda   108.0 KiB
	==> vsphere-iso.fedora42srv:  rsyslog                                    x86_64 8.2508.0-1.fc42              updates      2.7 MiB
	==> vsphere-iso.fedora42srv:    replacing rsyslog                        x86_64 8.2412.0-3.fc42              anaconda     2.7 MiB
	==> vsphere-iso.fedora42srv:  samba-client-libs                          x86_64 2:4.22.6-1.fc42              updates     19.5 MiB
	==> vsphere-iso.fedora42srv:    replacing samba-client-libs              x86_64 2:4.22.0-20.fc42             anaconda    19.5 MiB
	==> vsphere-iso.fedora42srv:  samba-common                               noarch 2:4.22.6-1.fc42              updates    208.5 KiB
	==> vsphere-iso.fedora42srv:    replacing samba-common                   noarch 2:4.22.0-20.fc42             anaconda   193.0 KiB
	==> vsphere-iso.fedora42srv:  samba-common-libs                          x86_64 2:4.22.6-1.fc42              updates    259.4 KiB
	==> vsphere-iso.fedora42srv:    replacing samba-common-libs              x86_64 2:4.22.0-20.fc42             anaconda   260.1 KiB
	==> vsphere-iso.fedora42srv:  selinux-policy                             noarch 42.13-1.fc42                 updates     31.6 KiB
	==> vsphere-iso.fedora42srv:    replacing selinux-policy                 noarch 41.34-1.fc42                 anaconda    31.4 KiB
	==> vsphere-iso.fedora42srv:  selinux-policy-targeted                    noarch 42.13-1.fc42                 updates     18.7 MiB
	==> vsphere-iso.fedora42srv:    replacing selinux-policy-targeted        noarch 41.34-1.fc42                 anaconda    18.5 MiB
	==> vsphere-iso.fedora42srv:  smartmontools                              x86_64 1:7.5-3.fc42                 updates      2.3 MiB
	==> vsphere-iso.fedora42srv:    replacing smartmontools                  x86_64 1:7.4-8.fc42                 anaconda     2.2 MiB
	==> vsphere-iso.fedora42srv:  smartmontools-selinux                      noarch 1:7.5-3.fc42                 updates     33.4 KiB
	==> vsphere-iso.fedora42srv:    replacing smartmontools-selinux          noarch 1:7.4-8.fc42                 anaconda    33.2 KiB
	==> vsphere-iso.fedora42srv:  sos                                        noarch 4.10.0-1.fc42                updates      3.9 MiB
	==> vsphere-iso.fedora42srv:    replacing sos                            noarch 4.8.2-2.fc42                 anaconda     3.7 MiB
	==> vsphere-iso.fedora42srv:  sqlite-libs                                x86_64 3.47.2-5.fc42                updates      1.5 MiB
	==> vsphere-iso.fedora42srv:    replacing sqlite-libs                    x86_64 3.47.2-2.fc42                anaconda     1.5 MiB
	==> vsphere-iso.fedora42srv:  sssd-client                                x86_64 2.11.1-2.fc42                updates    333.9 KiB
	==> vsphere-iso.fedora42srv:    replacing sssd-client                    x86_64 2.10.2-3.fc42                anaconda   346.4 KiB
	==> vsphere-iso.fedora42srv:  sssd-common                                x86_64 2.11.1-2.fc42                updates      5.2 MiB
	==> vsphere-iso.fedora42srv:    replacing sssd-common                    x86_64 2.10.2-3.fc42                anaconda     5.2 MiB
	==> vsphere-iso.fedora42srv:  sssd-kcm                                   x86_64 2.11.1-2.fc42                updates    225.8 KiB
	==> vsphere-iso.fedora42srv:    replacing sssd-kcm                       x86_64 2.10.2-3.fc42                anaconda   231.1 KiB
	==> vsphere-iso.fedora42srv:  sssd-krb5-common                           x86_64 2.11.1-2.fc42                updates    219.3 KiB
	==> vsphere-iso.fedora42srv:    replacing sssd-krb5-common               x86_64 2.10.2-3.fc42                anaconda   218.8 KiB
	==> vsphere-iso.fedora42srv:  sssd-nfs-idmap                             x86_64 2.11.1-2.fc42                updates     41.6 KiB
	==> vsphere-iso.fedora42srv:    replacing sssd-nfs-idmap                 x86_64 2.10.2-3.fc42                anaconda    43.2 KiB
	==> vsphere-iso.fedora42srv:  sssd-proxy                                 x86_64 2.11.1-2.fc42                updates    161.6 KiB
	==> vsphere-iso.fedora42srv:    replacing sssd-proxy                     x86_64 2.10.2-3.fc42                anaconda   161.6 KiB
	==> vsphere-iso.fedora42srv:  sudo                                       x86_64 1.9.17-2.p1.fc42             updates      5.0 MiB
	==> vsphere-iso.fedora42srv:    replacing sudo                           x86_64 1.9.15-7.p5.fc42             anaconda     4.9 MiB
	==> vsphere-iso.fedora42srv:  systemd                                    x86_64 257.10-1.fc42                updates     12.1 MiB
	==> vsphere-iso.fedora42srv:    replacing systemd                        x86_64 257.3-7.fc42                 anaconda    12.1 MiB
	==> vsphere-iso.fedora42srv:  systemd-libs                               x86_64 257.10-1.fc42                updates      2.2 MiB
	==> vsphere-iso.fedora42srv:    replacing systemd-libs                   x86_64 257.3-7.fc42                 anaconda     2.2 MiB
	==> vsphere-iso.fedora42srv:  systemd-oomd-defaults                      noarch 257.10-1.fc42                updates    187.0   B
	==> vsphere-iso.fedora42srv:    replacing systemd-oomd-defaults          noarch 257.3-7.fc42                 anaconda   187.0   B
	==> vsphere-iso.fedora42srv:  systemd-pam                                x86_64 257.10-1.fc42                updates      1.1 MiB
	==> vsphere-iso.fedora42srv:    replacing systemd-pam                    x86_64 257.3-7.fc42                 anaconda     1.1 MiB
	==> vsphere-iso.fedora42srv:  systemd-resolved                           x86_64 257.10-1.fc42                updates    673.9 KiB
	==> vsphere-iso.fedora42srv:    replacing systemd-resolved               x86_64 257.3-7.fc42                 anaconda   681.9 KiB
	==> vsphere-iso.fedora42srv:  systemd-shared                             x86_64 257.10-1.fc42                updates      4.6 MiB
	==> vsphere-iso.fedora42srv:    replacing systemd-shared                 x86_64 257.3-7.fc42                 anaconda     4.6 MiB
	==> vsphere-iso.fedora42srv:  systemd-sysusers                           x86_64 257.10-1.fc42                updates     83.8 KiB
	==> vsphere-iso.fedora42srv:    replacing systemd-sysusers               x86_64 257.3-7.fc42                 anaconda    83.8 KiB
	==> vsphere-iso.fedora42srv:  systemd-udev                               x86_64 257.10-1.fc42                updates     12.2 MiB
	==> vsphere-iso.fedora42srv:    replacing systemd-udev                   x86_64 257.3-7.fc42                 anaconda    11.9 MiB
	==> vsphere-iso.fedora42srv:  tcpdump                                    x86_64 14:4.99.5-4.fc42             updates      1.2 MiB
	==> vsphere-iso.fedora42srv:    replacing tcpdump                        x86_64 14:4.99.5-3.fc42             anaconda     1.2 MiB
	==> vsphere-iso.fedora42srv:  tiwilink-firmware                          noarch 20251021-1.fc42              updates      4.6 MiB
	==> vsphere-iso.fedora42srv:    replacing tiwilink-firmware              noarch 20250311-1.fc42              anaconda     4.6 MiB
	==> vsphere-iso.fedora42srv:  udisks2                                    x86_64 2.10.91-1.fc42               updates      2.9 MiB
	==> vsphere-iso.fedora42srv:    replacing udisks2                        x86_64 2.10.90-2.fc42               anaconda     2.9 MiB
	==> vsphere-iso.fedora42srv:  udisks2-iscsi                              x86_64 2.10.91-1.fc42               updates    583.0 KiB
	==> vsphere-iso.fedora42srv:    replacing udisks2-iscsi                  x86_64 2.10.90-2.fc42               anaconda   583.0 KiB
	==> vsphere-iso.fedora42srv:  udisks2-lvm2                               x86_64 2.10.91-1.fc42               updates    635.9 KiB
	==> vsphere-iso.fedora42srv:    replacing udisks2-lvm2                   x86_64 2.10.90-2.fc42               anaconda   635.8 KiB
	==> vsphere-iso.fedora42srv:  unbound-libs                               x86_64 1.24.1-1.fc42                updates      1.4 MiB
	==> vsphere-iso.fedora42srv:    replacing unbound-libs                   x86_64 1.22.0-14.fc42               anaconda     1.4 MiB
	==> vsphere-iso.fedora42srv:  usb_modeswitch                             x86_64 2.6.2-4.fc42                 updates    217.4 KiB
	==> vsphere-iso.fedora42srv:    replacing usb_modeswitch                 x86_64 2.6.2-2.fc42                 anaconda   217.2 KiB
	==> vsphere-iso.fedora42srv:  vim-common                                 x86_64 2:9.1.1818-1.fc42            updates     36.9 MiB
	==> vsphere-iso.fedora42srv:    replacing vim-common                     x86_64 2:9.1.1227-1.fc42            anaconda    37.8 MiB
	==> vsphere-iso.fedora42srv:  vim-data                                   noarch 2:9.1.1818-1.fc42            updates     10.2 KiB
	==> vsphere-iso.fedora42srv:    replacing vim-data                       noarch 2:9.1.1227-1.fc42            anaconda    10.3 KiB
	==> vsphere-iso.fedora42srv:  vim-default-editor                         noarch 2:9.1.1818-1.fc42            updates    505.0   B
	==> vsphere-iso.fedora42srv:    replacing vim-default-editor             noarch 2:9.1.1227-1.fc42            anaconda   505.0   B
	==> vsphere-iso.fedora42srv:  vim-enhanced                               x86_64 2:9.1.1818-1.fc42            updates      4.2 MiB
	==> vsphere-iso.fedora42srv:    replacing vim-enhanced                   x86_64 2:9.1.1227-1.fc42            anaconda     4.0 MiB
	==> vsphere-iso.fedora42srv:  vim-filesystem                             noarch 2:9.1.1818-1.fc42            updates     40.0   B
	==> vsphere-iso.fedora42srv:    replacing vim-filesystem                 noarch 2:9.1.1227-1.fc42            anaconda    40.0   B
	==> vsphere-iso.fedora42srv:  vim-minimal                                x86_64 2:9.1.1818-1.fc42            updates      1.7 MiB
	==> vsphere-iso.fedora42srv:    replacing vim-minimal                    x86_64 2:9.1.1227-1.fc42            anaconda     1.7 MiB
	==> vsphere-iso.fedora42srv:  wget2                                      x86_64 2.2.0-5.fc42                 updates      1.0 MiB
	==> vsphere-iso.fedora42srv:    replacing wget2                          x86_64 2.2.0-3.fc42                 anaconda     1.0 MiB
	==> vsphere-iso.fedora42srv:  wget2-libs                                 x86_64 2.2.0-5.fc42                 updates    365.6 KiB
	==> vsphere-iso.fedora42srv:    replacing wget2-libs                     x86_64 2.2.0-3.fc42                 anaconda   365.6 KiB
	==> vsphere-iso.fedora42srv:  wget2-wget                                 x86_64 2.2.0-5.fc42                 updates     42.0   B
	==> vsphere-iso.fedora42srv:    replacing wget2-wget                     x86_64 2.2.0-3.fc42                 anaconda    42.0   B
	==> vsphere-iso.fedora42srv:  which                                      x86_64 2.23-2.fc42                  updates     83.5 KiB
	==> vsphere-iso.fedora42srv:    replacing which                          x86_64 2.23-1.fc42                  anaconda    83.4 KiB
	==> vsphere-iso.fedora42srv:  whois                                      x86_64 5.6.5-1.fc42                 updates    173.0 KiB
	==> vsphere-iso.fedora42srv:    replacing whois                          x86_64 5.5.20-5.fc42                anaconda   174.2 KiB
	==> vsphere-iso.fedora42srv:  whois-nls                                  noarch 5.6.5-1.fc42                 updates    132.2 KiB
	==> vsphere-iso.fedora42srv:    replacing whois-nls                      noarch 5.5.20-5.fc42                anaconda   132.2 KiB
	==> vsphere-iso.fedora42srv:  wireless-regdb                             noarch 2025.10.07-1.fc42            updates     12.7 KiB
	==> vsphere-iso.fedora42srv:    replacing wireless-regdb                 noarch 2024.01.23-3.fc42            anaconda    11.3 KiB
	==> vsphere-iso.fedora42srv:  wpa_supplicant                             x86_64 1:2.11-6.fc42                updates      6.3 MiB
	==> vsphere-iso.fedora42srv:    replacing wpa_supplicant                 x86_64 1:2.11-4.fc42                anaconda     6.3 MiB
	==> vsphere-iso.fedora42srv:  xxd                                        x86_64 2:9.1.1818-1.fc42            updates     37.2 KiB
	==> vsphere-iso.fedora42srv:    replacing xxd                            x86_64 2:9.1.1227-1.fc42            anaconda    33.3 KiB
	==> vsphere-iso.fedora42srv:  xz                                         x86_64 1:5.8.1-2.fc42               updates      1.3 MiB
	==> vsphere-iso.fedora42srv:    replacing xz                             x86_64 1:5.6.3-3.fc42               anaconda     1.2 MiB
	==> vsphere-iso.fedora42srv:  xz-libs                                    x86_64 1:5.8.1-2.fc42               updates    217.8 KiB
	==> vsphere-iso.fedora42srv:    replacing xz-libs                        x86_64 1:5.6.3-3.fc42               anaconda   218.3 KiB
	==> vsphere-iso.fedora42srv:  zlib-ng-compat                             x86_64 2.2.5-2.fc42                 updates    137.6 KiB
	==> vsphere-iso.fedora42srv:    replacing zlib-ng-compat                 x86_64 2.2.4-3.fc42                 anaconda   137.6 KiB
	==> vsphere-iso.fedora42srv: Installing:
	==> vsphere-iso.fedora42srv:  kernel                                     x86_64 6.17.6-200.fc42              updates      0.0   B
	==> vsphere-iso.fedora42srv: Installing dependencies:
	==> vsphere-iso.fedora42srv:  cockpit-ws-selinux                         x86_64 347-1.fc42                   updates     44.9 KiB
	==> vsphere-iso.fedora42srv:  gnulib-l10n                                noarch 20241231-1.fc42              updates    655.0 KiB
	==> vsphere-iso.fedora42srv:  iwlwifi-mld-firmware                       noarch 20251021-1.fc42              updates      7.1 MiB
	==> vsphere-iso.fedora42srv:  kernel-core                                x86_64 6.17.6-200.fc42              updates     98.8 MiB
	==> vsphere-iso.fedora42srv:  kernel-modules                             x86_64 6.17.6-200.fc42              updates     95.6 MiB
	==> vsphere-iso.fedora42srv:  kernel-modules-core                        x86_64 6.17.6-200.fc42              updates     68.3 MiB
	==> vsphere-iso.fedora42srv:  libfyaml                                   x86_64 0.8-7.fc42                   fedora     549.3 KiB
	==> vsphere-iso.fedora42srv:  tpm2-tss-fapi                              x86_64 4.1.3-6.fc42                 fedora     878.0 KiB
	==> vsphere-iso.fedora42srv: Installing weak dependencies:
	==> vsphere-iso.fedora42srv:  libdnf5-plugin-expired-pgp-keys            x86_64 5.2.17.0-1.fc42              updates     86.5 KiB
	==> vsphere-iso.fedora42srv:  qcom-wwan-firmware                         noarch 20251021-1.fc42              updates    300.4 KiB
	==> vsphere-iso.fedora42srv:  rpm-plugin-systemd-inhibit                 x86_64 4.20.1-1.fc42                fedora      12.1 KiB
	==> vsphere-iso.fedora42srv:  tpm2-tools                                 x86_64 5.7-3.fc42                   fedora       1.5 MiB
	==> vsphere-iso.fedora42srv:
	==> vsphere-iso.fedora42srv: Transaction Summary:
	==> vsphere-iso.fedora42srv:  Installing:        13 packages
	==> vsphere-iso.fedora42srv:  Upgrading:        265 packages
	==> vsphere-iso.fedora42srv:  Replacing:        265 packages
	==> vsphere-iso.fedora42srv:
	==> vsphere-iso.fedora42srv: [  1/278] gnulib-l10n-0:20241231-1.fc42 100% | 240.9 KiB/s | 150.1 KiB |  00m01s
	==> vsphere-iso.fedora42srv: [  2/278] libfyaml-0:0.8-7.fc42.x86_64  100% | 368.5 KiB/s | 231.4 KiB |  00m01s
	==> vsphere-iso.fedora42srv: [  3/278] kernel-0:6.17.6-200.fc42.x86_ 100% |   1.0 MiB/s | 220.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [  4/278] iwlwifi-mld-firmware-0:202510 100% |   5.1 MiB/s |   7.1 MiB |  00m01s
	==> vsphere-iso.fedora42srv: [  5/278] kernel-core-0:6.17.6-200.fc42 100% |  11.4 MiB/s |  19.8 MiB |  00m02s
	==> vsphere-iso.fedora42srv: [  6/278] cockpit-ws-selinux-0:347-1.fc 100% | 479.9 KiB/s |  44.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [  7/278] rpm-plugin-systemd-inhibit-0: 100% |  57.9 KiB/s |  20.3 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [  8/278] libdnf5-plugin-expired-pgp-ke 100% |   1.2 MiB/s |  95.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [  9/278] tpm2-tools-0:5.7-3.fc42.x86_6 100% |   1.6 MiB/s | 812.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 10/278] tpm2-tss-fapi-0:4.1.3-6.fc42. 100% |   3.2 MiB/s | 338.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 11/278] qcom-wwan-firmware-0:20251021 100% |   3.1 MiB/s | 300.3 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 12/278] kernel-modules-core-0:6.17.6- 100% |  26.7 MiB/s |  69.9 MiB |  00m03s
	==> vsphere-iso.fedora42srv: [ 13/278] NetworkManager-1:1.52.1-1.fc4 100% |   4.7 MiB/s |   2.2 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 14/278] NetworkManager-libnm-1:1.52.1 100% |  14.0 MiB/s |   1.9 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 15/278] NetworkManager-wwan-1:1.52.1- 100% | 667.7 KiB/s |  58.1 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 16/278] glib2-0:2.84.4-1.fc42.x86_64  100% |  11.6 MiB/s |   3.1 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 17/278] NetworkManager-wifi-1:1.52.1- 100% |   1.1 MiB/s | 131.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 18/278] NetworkManager-team-1:1.52.1- 100% | 426.3 KiB/s |  30.3 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 19/278] kernel-modules-0:6.17.6-200.f 100% |  22.9 MiB/s |  97.5 MiB |  00m04s
	==> vsphere-iso.fedora42srv: [ 20/278] NetworkManager-bluetooth-1:1. 100% |  68.6 KiB/s |  51.1 KiB |  00m01s
	==> vsphere-iso.fedora42srv: [ 21/278] alternatives-0:1.33-1.fc42.x8 100% | 382.5 KiB/s |  40.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 22/278] linux-firmware-whence-0:20251 100% | 788.9 KiB/s |  61.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 23/278] amd-ucode-firmware-0:20251021 100% |   4.3 MiB/s | 397.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 24/278] alsa-sof-firmware-0:2025.05.1 100% |   8.0 MiB/s |   9.0 MiB |  00m01s
	==> vsphere-iso.fedora42srv: [ 25/278] appstream-0:1.1.0-1.fc42.x86_ 100% |   6.4 MiB/s | 874.1 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 26/278] at-0:3.2.5-16.fc42.x86_64     100% | 451.8 KiB/s |  61.9 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 27/278] appstream-data-0:42-8.fc42.no 100% |  25.8 MiB/s |  15.3 MiB |  00m01s
	==> vsphere-iso.fedora42srv: [ 28/278] audit-0:4.1.2-2.fc42.x86_64   100% |   2.4 MiB/s | 209.9 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 29/278] audit-libs-0:4.1.2-2.fc42.x86 100% |   1.6 MiB/s | 138.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 30/278] audit-rules-0:4.1.2-2.fc42.x8 100% | 838.0 KiB/s |  68.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 31/278] python3-audit-0:4.1.2-2.fc42. 100% | 890.9 KiB/s |  69.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 32/278] amd-gpu-firmware-0:20251021-1 100% |  16.2 MiB/s |  25.9 MiB |  00m02s
	==> vsphere-iso.fedora42srv: [ 33/278] bash-color-prompt-0:0.7.1-1.f 100% |  80.6 KiB/s |  21.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 34/278] bind-utils-32:9.18.41-1.fc42. 100% |   2.4 MiB/s | 223.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 35/278] bind-libs-32:9.18.41-1.fc42.x 100% |   7.0 MiB/s |   1.3 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 36/278] binutils-0:2.44-6.fc42.x86_64 100% |  21.9 MiB/s |   5.8 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 37/278] bluez-0:5.84-2.fc42.x86_64    100% |   6.6 MiB/s |   1.2 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 38/278] bluez-libs-0:5.84-2.fc42.x86_ 100% | 766.9 KiB/s |  83.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 39/278] atheros-firmware-0:20251021-1 100% |  22.0 MiB/s |  41.0 MiB |  00m02s
	==> vsphere-iso.fedora42srv: [ 40/278] btrfs-progs-0:6.16.1-1.fc42.x 100% |   3.5 MiB/s |   1.3 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 41/278] ca-certificates-0:2025.2.80_v 100% |   9.3 MiB/s | 973.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 42/278] c-ares-0:1.34.5-1.fc42.x86_64 100% | 573.6 KiB/s | 117.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 43/278] chrony-0:4.8-1.fc42.x86_64    100% |   3.2 MiB/s | 350.1 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 44/278] cockpit-0:347-1.fc42.x86_64   100% | 227.3 KiB/s |  32.3 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 45/278] cirrus-audio-firmware-0:20251 100% |  10.5 MiB/s |   2.1 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 46/278] cockpit-networkmanager-0:347- 100% |   4.5 MiB/s | 806.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 47/278] cockpit-bridge-0:347-1.fc42.n 100% |   2.9 MiB/s | 688.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 48/278] cockpit-packagekit-0:347-1.fc 100% |   6.2 MiB/s | 873.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 49/278] cockpit-selinux-0:347-1.fc42. 100% |   3.3 MiB/s | 432.9 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 50/278] brcmfmac-firmware-0:20251021- 100% |   7.2 MiB/s |   9.6 MiB |  00m01s
	==> vsphere-iso.fedora42srv: [ 51/278] cockpit-storaged-0:347-1.fc42 100% |   4.5 MiB/s | 815.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 52/278] cockpit-system-0:347-1.fc42.n 100% |   9.6 MiB/s |   3.0 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 53/278] cockpit-ws-0:347-1.fc42.x86_6 100% |   6.3 MiB/s |   1.1 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 54/278] coreutils-0:9.6-6.fc42.x86_64 100% |   6.5 MiB/s |   1.1 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 55/278] crypto-policies-scripts-0:202 100% |   1.4 MiB/s | 127.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 56/278] crypto-policies-0:20250707-1. 100% | 849.3 KiB/s |  96.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 57/278] coreutils-common-0:9.6-6.fc42 100% |  12.9 MiB/s |   2.1 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 58/278] cryptsetup-0:2.8.1-1.fc42.x86 100% |   3.4 MiB/s | 347.1 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 59/278] cryptsetup-libs-0:2.8.1-1.fc4 100% |   3.4 MiB/s | 575.3 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 60/278] curl-0:8.11.1-6.fc42.x86_64   100% |   1.5 MiB/s | 220.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 61/278] libcurl-0:8.11.1-6.fc42.x86_6 100% |   2.4 MiB/s | 371.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 62/278] libssh-config-0:0.11.3-1.fc42 100% | 100.1 KiB/s |   9.1 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 63/278] libssh-0:0.11.3-1.fc42.x86_64 100% |   2.2 MiB/s | 233.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 64/278] diffutils-0:3.12-1.fc42.x86_6 100% |   4.2 MiB/s | 392.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 65/278] dnf-data-0:4.24.0-1.fc42.noar 100% | 460.3 KiB/s |  37.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 66/278] dbus-broker-0:36-6.fc42.x86_6 100% |   1.5 MiB/s | 172.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 67/278] python3-hawkey-0:0.75.0-1.fc4 100% | 997.9 KiB/s | 101.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 68/278] python3-libdnf-0:0.75.0-1.fc4 100% |   7.3 MiB/s | 844.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 69/278] python3-dnf-0:4.24.0-1.fc42.n 100% |   4.9 MiB/s | 632.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 70/278] libdnf-0:0.75.0-1.fc42.x86_64 100% |   7.4 MiB/s | 727.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 71/278] dnf5-0:5.2.17.0-1.fc42.x86_64 100% |   9.3 MiB/s | 942.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 72/278] libdnf5-0:5.2.17.0-1.fc42.x86 100% |  11.7 MiB/s |   1.3 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 73/278] libdnf5-cli-0:5.2.17.0-1.fc42 100% |   4.0 MiB/s | 357.1 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 74/278] librepo-0:1.20.0-1.fc42.x86_6 100% |   1.0 MiB/s | 101.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 75/278] dnf5-plugins-0:5.2.17.0-1.fc4 100% |   3.9 MiB/s | 478.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 76/278] dnsmasq-0:2.90-6.fc42.x86_64  100% |   2.4 MiB/s | 361.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 77/278] dracut-config-rescue-0:107-4. 100% |  86.4 KiB/s |  11.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 78/278] dracut-0:107-4.fc42.x86_64    100% |   3.1 MiB/s | 629.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 79/278] elfutils-0:0.194-1.fc42.x86_6 100% |   5.9 MiB/s | 575.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 80/278] elfutils-debuginfod-client-0: 100% | 391.2 KiB/s |  46.9 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 81/278] elfutils-libs-0:0.194-1.fc42. 100% |   3.2 MiB/s | 271.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 82/278] elfutils-libelf-0:0.194-1.fc4 100% |   1.7 MiB/s | 205.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 83/278] elfutils-default-yama-scope-0 100% | 154.7 KiB/s |  12.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 84/278] ethtool-2:6.15-3.fc42.x86_64  100% |   3.2 MiB/s | 318.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 85/278] exfatprogs-0:1.3.0-1.fc42.x86 100% |   1.3 MiB/s | 114.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 86/278] expat-0:2.7.2-1.fc42.x86_64   100% |   1.2 MiB/s | 119.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 87/278] fedora-release-common-0:42-30 100% | 266.2 KiB/s |  24.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 88/278] fedora-release-server-0:42-30 100% | 126.4 KiB/s |  13.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 89/278] file-0:5.46-3.fc42.x86_64     100% | 640.1 KiB/s |  48.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 90/278] fedora-release-identity-serve 100% | 102.4 KiB/s |  16.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 91/278] file-libs-0:5.46-3.fc42.x86_6 100% |   6.5 MiB/s | 849.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 92/278] firewalld-0:2.3.1-1.fc42.noar 100% |   4.5 MiB/s | 526.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 93/278] filesystem-0:3.18-47.fc42.x86 100% |   6.8 MiB/s |   1.3 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 94/278] fonts-filesystem-1:2.0.5-22.f 100% | 114.8 KiB/s |   8.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 95/278] firewalld-filesystem-0:2.3.1- 100% |  43.5 KiB/s |  10.3 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 96/278] python3-firewall-0:2.3.1-1.fc 100% |   2.6 MiB/s | 509.1 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 97/278] fprintd-0:1.94.5-1.fc42.x86_6 100% | 669.1 KiB/s | 181.3 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 98/278] fprintd-pam-0:1.94.5-1.fc42.x 100% |  85.1 KiB/s |  22.1 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 99/278] fwupd-0:2.0.16-1.fc42.x86_64  100% |   8.9 MiB/s |   2.6 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [100/278] libxmlb-0:0.3.24-1.fc42.x86_6 100% | 930.5 KiB/s | 117.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [101/278] glibc-common-0:2.41-11.fc42.x 100% |   3.2 MiB/s | 385.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [102/278] glibc-langpack-en-0:2.41-11.f 100% |   5.0 MiB/s | 641.1 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [103/278] glibc-0:2.41-11.fc42.x86_64   100% |   8.4 MiB/s |   2.2 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [104/278] gdb-headless-0:16.3-1.fc42.x8 100% |  12.0 MiB/s |   5.1 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [105/278] glibc-gconv-extra-0:2.41-11.f 100% |  12.2 MiB/s |   1.6 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [106/278] gnutls-0:3.8.10-1.fc42.x86_64 100% |   6.3 MiB/s |   1.4 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [107/278] gpgme-0:1.24.3-1.fc42.x86_64  100% |   2.0 MiB/s | 219.1 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [108/278] gnutls-dane-0:3.8.10-1.fc42.x 100% | 198.3 KiB/s |  38.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [109/278] grub2-tools-minimal-1:2.12-32 100% |   4.4 MiB/s | 614.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [110/278] grub2-tools-1:2.12-32.fc42.x8 100% |   8.2 MiB/s |   1.8 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [111/278] grub2-pc-modules-1:2.12-32.fc 100% |   7.4 MiB/s |   1.1 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [112/278] grub2-common-1:2.12-32.fc42.n 100% |   3.4 MiB/s |   1.0 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [113/278] grub2-pc-1:2.12-32.fc42.x86_6 100% | 116.6 KiB/s |  15.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [114/278] hwdata-0:0.400-1.fc42.noarch  100% |  13.2 MiB/s |   1.7 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [115/278] inih-0:62-1.fc42.x86_64       100% | 125.7 KiB/s |  18.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [116/278] intel-audio-firmware-0:202510 100% |  17.9 MiB/s |   3.2 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [117/278] iptables-libs-0:1.8.11-9.fc42 100% |   4.3 MiB/s | 403.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [118/278] intel-gpu-firmware-0:20251021 100% |  24.4 MiB/s |   8.8 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [119/278] iptables-nft-0:1.8.11-9.fc42. 100% |   1.7 MiB/s | 184.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [120/278] iputils-0:20250605-1.fc42.x86 100% |   1.3 MiB/s | 209.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [121/278] iscsi-initiator-utils-0:6.2.1 100% |   2.2 MiB/s | 388.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [122/278] iwlegacy-firmware-0:20251021- 100% | 945.5 KiB/s | 148.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [123/278] iscsi-initiator-utils-iscsiui 100% | 378.9 KiB/s |  81.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [124/278] iwlwifi-dvm-firmware-0:202510 100% |  12.2 MiB/s |   1.8 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [125/278] intel-vsc-firmware-0:20251021 100% |   8.5 MiB/s |   7.7 MiB |  00m01s
	==> vsphere-iso.fedora42srv: [126/278] json-glib-0:1.10.8-1.fc42.x86 100% |   1.9 MiB/s | 172.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [127/278] kexec-tools-0:2.0.32-1.fc42.x 100% |   1.2 MiB/s | 102.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [128/278] less-0:679-1.fc42.x86_64      100% |   2.5 MiB/s | 195.3 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [129/278] krb5-libs-0:1.21.3-6.fc42.x86 100% |   3.3 MiB/s | 759.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [130/278] libarchive-0:3.8.1-1.fc42.x86 100% |   2.8 MiB/s | 421.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [131/278] libblockdev-0:3.3.1-2.fc42.x8 100% | 596.5 KiB/s | 111.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [132/278] libblockdev-utils-0:3.3.1-2.f 100% | 342.4 KiB/s |  38.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [133/278] libblockdev-swap-0:3.3.1-2.fc 100% | 291.1 KiB/s |  30.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [134/278] libblockdev-smart-0:3.3.1-2.f 100% | 313.5 KiB/s |  32.3 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [135/278] libblockdev-nvme-0:3.3.1-2.fc 100% | 342.2 KiB/s |  39.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [136/278] libblockdev-part-0:3.3.1-2.fc 100% | 298.1 KiB/s |  37.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [137/278] libblockdev-lvm-0:3.3.1-2.fc4 100% | 474.7 KiB/s |  51.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [138/278] libblockdev-loop-0:3.3.1-2.fc 100% | 228.4 KiB/s |  29.9 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [139/278] libblockdev-mdraid-0:3.3.1-2. 100% | 141.5 KiB/s |  35.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [140/278] libblockdev-fs-0:3.3.1-2.fc42 100% | 295.1 KiB/s |  60.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [141/278] libblockdev-crypto-0:3.3.1-2. 100% | 224.3 KiB/s |  47.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [142/278] libcomps-0:0.1.22-1.fc42.x86_ 100% | 582.1 KiB/s |  76.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [143/278] python3-libcomps-0:0.1.22-1.f 100% | 269.1 KiB/s |  47.9 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [144/278] libdrm-0:2.4.127-3.fc42.x86_6 100% |   1.8 MiB/s | 162.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [145/278] iwlwifi-mvm-firmware-0:202510 100% |  31.6 MiB/s |  60.6 MiB |  00m02s
	==> vsphere-iso.fedora42srv: [146/278] libeconf-0:0.7.6-2.fc42.x86_6 100% |  79.7 KiB/s |  35.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [147/278] libedit-0:3.1-56.20251016cvs. 100% | 260.0 KiB/s | 105.1 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [148/278] libgomp-0:15.2.1-3.fc42.x86_6 100% |   4.2 MiB/s | 374.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [149/278] libertas-firmware-0:20251021- 100% |  12.5 MiB/s |   1.3 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [150/278] libjcat-0:0.2.5-1.fc42.x86_64 100% |   1.1 MiB/s |  85.9 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [151/278] libldb-2:4.22.6-1.fc42.x86_64 100% |   2.3 MiB/s | 187.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [152/278] samba-common-2:4.22.6-1.fc42. 100% |   2.2 MiB/s | 177.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [153/278] libwbclient-2:4.22.6-1.fc42.x 100% | 586.6 KiB/s |  45.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [154/278] samba-client-libs-2:4.22.6-1. 100% |  24.3 MiB/s |   5.6 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [155/278] libgcc-0:15.2.1-3.fc42.x86_64 100% | 334.9 KiB/s | 133.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [156/278] samba-common-libs-2:4.22.6-1. 100% | 766.7 KiB/s | 106.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [157/278] libnfsidmap-1:2.8.4-0.fc42.x8 100% | 423.5 KiB/s |  62.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [158/278] libmodulemd-0:2.15.2-1.fc42.x 100% |   1.2 MiB/s | 234.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [159/278] libnvme-0:1.15-2.fc42.x86_64  100% |   1.1 MiB/s | 117.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [160/278] libselinux-utils-0:3.8-3.fc42 100% | 778.8 KiB/s | 119.9 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [161/278] python3-libselinux-0:3.8-3.fc 100% | 945.7 KiB/s | 200.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [162/278] libselinux-0:3.8-3.fc42.x86_6 100% | 367.6 KiB/s |  96.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [163/278] libsemanage-0:3.8.1-2.fc42.x8 100% |   1.3 MiB/s | 123.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [164/278] libsolv-0:0.7.35-1.fc42.x86_6 100% |   4.7 MiB/s | 446.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [165/278] libsss_certmap-0:2.11.1-2.fc4 100% |   1.0 MiB/s |  77.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [166/278] python3-libsemanage-0:3.8.1-2 100% | 658.9 KiB/s |  80.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [167/278] sssd-common-0:2.11.1-2.fc42.x 100% |  11.5 MiB/s |   1.5 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [168/278] sssd-proxy-0:2.11.1-2.fc42.x8 100% | 454.5 KiB/s |  66.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [169/278] sssd-kcm-0:2.11.1-2.fc42.x86_ 100% |   1.2 MiB/s |  99.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [170/278] sssd-krb5-common-0:2.11.1-2.f 100% | 391.7 KiB/s |  90.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [171/278] sssd-client-0:2.11.1-2.fc42.x 100% |   1.8 MiB/s | 147.3 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [172/278] sssd-nfs-idmap-0:2.11.1-2.fc4 100% | 196.0 KiB/s |  32.3 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [173/278] libsss_nss_idmap-0:2.11.1-2.f 100% | 528.4 KiB/s |  40.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [174/278] libsss_idmap-0:2.11.1-2.fc42. 100% | 249.3 KiB/s |  37.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [175/278] libsss_sudo-0:2.11.1-2.fc42.x 100% | 325.1 KiB/s |  29.9 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [176/278] libstdc++-0:15.2.1-3.fc42.x86 100% |   8.0 MiB/s | 919.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [177/278] libtirpc-0:1.3.7-1.fc42.x86_6 100% | 651.8 KiB/s |  95.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [178/278] libudisks2-0:2.10.91-1.fc42.x 100% |   1.6 MiB/s | 218.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [179/278] udisks2-0:2.10.91-1.fc42.x86_ 100% |   2.8 MiB/s | 547.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [180/278] udisks2-lvm2-0:2.10.91-1.fc42 100% |   1.6 MiB/s | 217.1 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [181/278] udisks2-iscsi-0:2.10.91-1.fc4 100% |   1.2 MiB/s | 202.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [182/278] libuv-1:1.51.0-1.fc42.x86_64  100% |   2.6 MiB/s | 266.3 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [183/278] libusb1-0:1.0.29-4.fc42.x86_6 100% | 163.7 KiB/s |  79.9 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [184/278] libxcrypt-0:4.4.38-7.fc42.x86 100% | 286.5 KiB/s | 127.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [185/278] mdadm-0:4.3-8.fc42.x86_64     100% |   3.6 MiB/s | 449.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [186/278] lua-libs-0:5.4.8-1.fc42.x86_6 100% | 955.9 KiB/s | 131.9 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [187/278] mpdecimal-0:4.0.1-1.fc42.x86_ 100% | 703.3 KiB/s |  97.1 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [188/278] linux-firmware-0:20251021-1.f 100% |  29.1 MiB/s |  41.7 MiB |  00m01s
	==> vsphere-iso.fedora42srv: [189/278] microcode_ctl-2:2.1-70.fc42.x 100% |  10.6 MiB/s |  10.5 MiB |  00m01s
	==> vsphere-iso.fedora42srv: [190/278] nfs-utils-1:2.8.4-0.fc42.x86_ 100% |   5.2 MiB/s | 476.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [191/278] nss-0:3.117.0-1.fc42.x86_64   100% |   7.3 MiB/s | 715.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [192/278] nspr-0:4.37.0-4.fc42.x86_64   100% |   1.2 MiB/s | 137.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [193/278] nss-util-0:3.117.0-1.fc42.x86 100% |   1.1 MiB/s |  86.1 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [194/278] nss-softokn-0:3.117.0-1.fc42. 100% |   4.6 MiB/s | 430.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [195/278] nss-softokn-freebl-0:3.117.0- 100% |   3.8 MiB/s | 329.1 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [196/278] nss-sysinit-0:3.117.0-1.fc42. 100% | 245.3 KiB/s |  18.9 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [197/278] ntfs-3g-libs-2:2022.10.3-9.fc 100% | 408.3 KiB/s | 175.1 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [198/278] ntfsprogs-2:2022.10.3-9.fc42. 100% |   2.1 MiB/s | 380.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [199/278] mt7xxx-firmware-0:20251021-1. 100% |   9.5 MiB/s |  17.7 MiB |  00m02s
	==> vsphere-iso.fedora42srv: [200/278] ntfs-3g-2:2022.10.3-9.fc42.x8 100% | 171.5 KiB/s | 127.8 KiB |  00m01s
	==> vsphere-iso.fedora42srv: [201/278] open-vm-tools-0:13.0.0-1.fc42 100% |   6.4 MiB/s | 844.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [202/278] openldap-0:2.6.10-1.fc42.x86_ 100% |   1.6 MiB/s | 258.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [203/278] opensc-0:0.26.1-3.fc42.x86_64 100% |   3.9 MiB/s | 414.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [204/278] opensc-libs-0:0.26.1-3.fc42.x 100% |   4.4 MiB/s | 917.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [205/278] openssh-0:9.9p1-11.fc42.x86_6 100% |   4.2 MiB/s | 353.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [206/278] openssh-server-0:9.9p1-11.fc4 100% |   5.3 MiB/s | 540.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [207/278] openssh-clients-0:9.9p1-11.fc 100% |   7.3 MiB/s | 767.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [208/278] openssl-1:3.2.6-2.fc42.x86_64 100% |  10.1 MiB/s |   1.1 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [209/278] openssl-libs-1:3.2.6-2.fc42.x 100% |  16.3 MiB/s |   2.3 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [210/278] nxpwireless-firmware-0:202510 100% | 776.4 KiB/s | 930.2 KiB |  00m01s
	==> vsphere-iso.fedora42srv: [211/278] p11-kit-0:0.25.8-1.fc42.x86_6 100% |   3.7 MiB/s | 503.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [212/278] pam-0:1.7.0-6.fc42.x86_64     100% |   5.0 MiB/s | 556.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [213/278] pam-libs-0:1.7.0-6.fc42.x86_6 100% | 587.1 KiB/s |  57.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [214/278] p11-kit-trust-0:0.25.8-1.fc42 100% | 467.1 KiB/s | 139.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [215/278] passim-libs-0:0.1.10-1.fc42.x 100% | 246.2 KiB/s |  33.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [216/278] pciutils-0:3.14.0-1.fc42.x86_ 100% | 580.1 KiB/s | 124.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [217/278] pciutils-libs-0:3.14.0-1.fc42 100% | 497.0 KiB/s |  52.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [218/278] pcre2-syntax-0:10.46-1.fc42.n 100% |   1.9 MiB/s | 162.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [219/278] pixman-0:0.46.2-1.fc42.x86_64 100% |   2.4 MiB/s | 292.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [220/278] pcre2-0:10.46-1.fc42.x86_64   100% | 854.0 KiB/s | 262.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [221/278] plymouth-0:24.004.60-19.fc42. 100% |   1.1 MiB/s | 127.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [222/278] plymouth-core-libs-0:24.004.6 100% |   1.2 MiB/s | 122.1 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [223/278] plymouth-scripts-0:24.004.60- 100% | 153.0 KiB/s |  18.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [224/278] polkit-libs-0:126-3.fc42.1.x8 100% | 585.9 KiB/s |  67.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [225/278] procps-ng-0:4.0.4-6.fc42.1.x8 100% |   4.1 MiB/s | 364.1 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [226/278] polkit-0:126-3.fc42.1.x86_64  100% | 658.5 KiB/s | 160.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [227/278] protobuf-c-0:1.5.1-1.fc42.x86 100% | 258.8 KiB/s |  32.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [228/278] publicsuffix-list-dafsa-0:202 100% | 435.0 KiB/s |  59.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [229/278] python-pip-wheel-0:24.3.1-5.f 100% |  10.9 MiB/s |   1.2 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [230/278] python3-0:3.13.9-1.fc42.x86_6 100% | 327.7 KiB/s |  30.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [231/278] python3-argcomplete-0:3.6.2-2 100% | 589.3 KiB/s |  97.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [232/278] python3-libs-0:3.13.9-1.fc42. 100% |  26.5 MiB/s |   9.2 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [233/278] python3-augeas-0:1.2.0-1.fc42 100% | 323.1 KiB/s |  47.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [234/278] python3-setools-0:4.5.1-6.fc4 100% |   5.1 MiB/s | 727.1 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [235/278] python3-requests-0:2.32.4-1.f 100% | 709.3 KiB/s | 158.9 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [236/278] python3-setuptools-0:74.1.3-7 100% |   8.5 MiB/s |   2.0 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [237/278] realmd-0:0.17.1-17.fc42.x86_6 100% | 511.3 KiB/s | 248.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [238/278] realtek-firmware-0:20251021-1 100% |  12.5 MiB/s |   5.3 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [239/278] rpcbind-0:1.2.8-0.fc42.x86_64 100% | 336.2 KiB/s |  58.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [240/278] rsyslog-0:8.2508.0-1.fc42.x86 100% |   4.4 MiB/s | 832.3 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [241/278] selinux-policy-0:42.13-1.fc42 100% | 422.4 KiB/s |  61.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [242/278] selinux-policy-targeted-0:42. 100% |  25.6 MiB/s |   6.8 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [243/278] smartmontools-selinux-1:7.5-3 100% | 166.6 KiB/s |  32.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [244/278] smartmontools-1:7.5-3.fc42.x8 100% |   1.2 MiB/s | 669.5 KiB |  00m01s
	==> vsphere-iso.fedora42srv: [245/278] sos-0:4.10.0-1.fc42.noarch    100% |   4.0 MiB/s |   1.3 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [246/278] sudo-0:1.9.17-2.p1.fc42.x86_6 100% |   8.6 MiB/s |   1.3 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [247/278] sqlite-libs-0:3.47.2-5.fc42.x 100% |   1.5 MiB/s | 753.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [248/278] systemd-0:257.10-1.fc42.x86_6 100% |  20.7 MiB/s |   4.0 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [249/278] systemd-pam-0:257.10-1.fc42.x 100% |   4.5 MiB/s | 410.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [250/278] systemd-shared-0:257.10-1.fc4 100% |  13.5 MiB/s |   1.8 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [251/278] systemd-udev-0:257.10-1.fc42. 100% |  16.9 MiB/s |   2.4 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [252/278] systemd-libs-0:257.10-1.fc42. 100% |   1.7 MiB/s | 809.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [253/278] systemd-resolved-0:257.10-1.f 100% |   3.4 MiB/s | 311.3 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [254/278] systemd-oomd-defaults-0:257.1 100% | 328.2 KiB/s |  28.9 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [255/278] systemd-sysusers-0:257.10-1.f 100% | 842.8 KiB/s |  66.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [256/278] tiwilink-firmware-0:20251021- 100% |  21.7 MiB/s |   4.6 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [257/278] unbound-libs-0:1.24.1-1.fc42. 100% |   5.2 MiB/s | 564.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [258/278] tcpdump-14:4.99.5-4.fc42.x86_ 100% |   1.2 MiB/s | 501.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [259/278] usb_modeswitch-0:2.6.2-4.fc42 100% | 836.2 KiB/s |  73.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [260/278] vim-data-2:9.1.1818-1.fc42.no 100% | 230.4 KiB/s |  17.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [261/278] vim-enhanced-2:9.1.1818-1.fc4 100% |  10.5 MiB/s |   2.0 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [262/278] vim-minimal-2:9.1.1818-1.fc42 100% |   8.0 MiB/s | 848.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [263/278] vim-default-editor-2:9.1.1818 100% | 139.2 KiB/s |  13.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [264/278] vim-filesystem-2:9.1.1818-1.f 100% | 195.7 KiB/s |  15.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [265/278] wget2-0:2.2.0-5.fc42.x86_64   100% |   2.5 MiB/s | 280.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [266/278] wget2-libs-0:2.2.0-5.fc42.x86 100% |   1.5 MiB/s | 147.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [267/278] wget2-wget-0:2.2.0-5.fc42.x86 100% |  95.4 KiB/s |   9.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [268/278] which-0:2.23-2.fc42.x86_64    100% | 535.1 KiB/s |  41.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [269/278] whois-0:5.6.5-1.fc42.x86_64   100% | 840.3 KiB/s |  66.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [270/278] whois-nls-0:5.6.5-1.fc42.noar 100% | 477.4 KiB/s |  37.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [271/278] wireless-regdb-0:2025.10.07-1 100% | 212.9 KiB/s |  16.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [272/278] wpa_supplicant-1:2.11-6.fc42. 100% |   6.3 MiB/s |   1.7 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [273/278] xxd-2:9.1.1818-1.fc42.x86_64  100% | 397.6 KiB/s |  31.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [274/278] xz-1:5.8.1-2.fc42.x86_64      100% |   4.3 MiB/s | 572.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [275/278] xz-libs-1:5.8.1-2.fc42.x86_64 100% | 801.3 KiB/s | 113.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [276/278] zlib-ng-compat-0:2.2.5-2.fc42 100% | 609.3 KiB/s |  79.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [277/278] vim-common-2:9.1.1818-1.fc42. 100% |   3.5 MiB/s |   8.1 MiB |  00m02s
	==> vsphere-iso.fedora42srv: [278/278] nvidia-gpu-firmware-0:2025102 100% |  10.9 MiB/s |  99.3 MiB |  00m09s
	==> vsphere-iso.fedora42srv: --------------------------------------------------------------------------------
	==> vsphere-iso.fedora42srv: [278/278] Total                         100% |  25.5 MiB/s | 709.9 MiB |  00m28s
	==> vsphere-iso.fedora42srv: Running transaction
	==> vsphere-iso.fedora42srv: [  1/545] Verify package files          100% |  82.0   B/s | 278.0   B |  00m03s
	==> vsphere-iso.fedora42srv: [  2/545] Prepare transaction           100% |   1.6 KiB/s | 543.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [  3/545] Upgrading libgcc-0:15.2.1-3.f 100% |  15.4 MiB/s | 268.3 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [  4/545] Upgrading filesystem-0:3.18-4 100% |   1.5 MiB/s | 212.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [  5/545] Upgrading glibc-langpack-en-0 100% |  82.6 MiB/s |   5.8 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [  6/545] Upgrading glibc-0:2.41-11.fc4 100% |  12.0 MiB/s |   6.7 MiB |  00m01s
	==> vsphere-iso.fedora42srv: [  7/545] Upgrading glibc-common-0:2.41 100% |  27.6 MiB/s |   1.0 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [  8/545] Upgrading glibc-gconv-extra-0 100% |  64.1 MiB/s |   7.3 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [  9/545] Upgrading systemd-libs-0:257. 100% | 117.7 MiB/s |   2.2 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 10/545] Upgrading zlib-ng-compat-0:2. 100% |  67.6 MiB/s | 138.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 11/545] Upgrading linux-firmware-when 100% | 170.0 MiB/s | 348.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 12/545] Upgrading audit-libs-0:4.1.2- 100% |  53.2 MiB/s | 381.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 13/545] Upgrading libstdc++-0:15.2.1- 100% | 128.9 MiB/s |   2.8 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 14/545] Upgrading xz-libs-1:5.8.1-2.f 100% |  21.4 MiB/s | 218.9 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 15/545] Upgrading crypto-policies-0:2 100% |   9.6 MiB/s | 167.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 16/545] Upgrading sqlite-libs-0:3.47. 100% | 189.1 MiB/s |   1.5 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 17/545] Upgrading alternatives-0:1.33 100% |   2.6 MiB/s |  63.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 18/545] Upgrading nspr-0:4.37.0-4.fc4 100% |  77.5 MiB/s | 317.3 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 19/545] Upgrading nss-util-0:3.117.0- 100% |  67.0 MiB/s | 205.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 20/545] Upgrading expat-0:2.7.2-1.fc4 100% |   8.2 MiB/s | 300.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 21/545] Upgrading libxcrypt-0:4.4.38- 100% |  70.1 MiB/s | 287.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 22/545] Upgrading p11-kit-0:0.25.8-1. 100% |  52.0 MiB/s |   2.3 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 23/545] Upgrading protobuf-c-0:1.5.1- 100% |   8.4 MiB/s |  51.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 24/545] Upgrading grub2-common-1:2.12 100% | 227.9 MiB/s |   6.2 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 25/545] Upgrading p11-kit-trust-0:0.2 100% |  10.9 MiB/s | 448.3 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 26/545] Upgrading gnutls-0:3.8.10-1.f 100% | 202.1 MiB/s |   3.8 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 27/545] Upgrading libsolv-0:0.7.35-1. 100% | 158.4 MiB/s | 973.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 28/545] Upgrading elfutils-libelf-0:0 100% | 101.9 MiB/s |   1.1 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 29/545] Upgrading gpgme-0:1.24.3-1.fc 100% |  20.6 MiB/s | 590.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 30/545] Upgrading libusb1-0:1.0.29-4. 100% |  42.2 MiB/s | 172.9 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 31/545] Upgrading libdrm-0:2.4.127-3. 100% |  78.9 MiB/s | 403.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 32/545] Upgrading libeconf-0:0.7.6-2. 100% |  10.8 MiB/s |  66.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 33/545] Upgrading pam-libs-0:1.7.0-6. 100% |  31.5 MiB/s | 129.1 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 34/545] Upgrading libedit-0:3.1-56.20 100% |  78.7 MiB/s | 241.9 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 35/545] Upgrading libsss_idmap-0:2.11 100% |  12.2 MiB/s |  75.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 36/545] Upgrading ntfs-3g-libs-2:2022 100% | 119.1 MiB/s | 366.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 37/545] Upgrading vim-data-2:9.1.1818 100% |  11.0 MiB/s |  11.3 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 38/545] Upgrading grub2-tools-minimal 100% |  78.1 MiB/s |   3.0 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 39/545] Upgrading grub2-pc-modules-1: 100% |  45.8 MiB/s |   3.2 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 40/545] Upgrading libcomps-0:0.1.22-1 100% |  50.4 MiB/s | 206.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 41/545] Upgrading nss-softokn-freebl- 100% |  59.3 MiB/s | 850.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 42/545] Upgrading nss-softokn-0:3.117 100% | 140.6 MiB/s |   2.0 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 43/545] Upgrading xz-1:5.8.1-2.fc42.x 100% |  29.6 MiB/s |   1.3 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 44/545] Installing iwlwifi-mld-firmwa 100% | 296.2 MiB/s |   7.1 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 45/545] Upgrading linux-firmware-0:20 100% | 211.9 MiB/s |  41.9 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 46/545] Upgrading file-libs-0:5.46-3. 100% | 395.2 MiB/s |  11.9 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 47/545] Upgrading file-0:5.46-3.fc42. 100% |   4.1 MiB/s | 101.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 48/545] Upgrading plymouth-core-libs- 100% |   8.7 MiB/s | 356.9 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 49/545] Upgrading procps-ng-0:4.0.4-6 100% |  26.6 MiB/s |   1.0 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 50/545] Installing libfyaml-0:0.8-7.f 100% |  19.3 MiB/s | 553.3 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 51/545] Upgrading bluez-libs-0:5.84-2 100% |  64.9 MiB/s | 199.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 52/545] Upgrading c-ares-0:1.34.5-1.f 100% |  52.9 MiB/s | 270.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 53/545] Upgrading iptables-libs-0:1.8 100% |  40.7 MiB/s |   1.5 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 54/545] Upgrading libsss_nss_idmap-0: 100% |  27.1 MiB/s |  83.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 55/545] Upgrading libsss_sudo-0:2.11. 100% |  26.7 MiB/s |  54.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 56/545] Upgrading libuv-1:1.51.0-1.fc 100% |  62.2 MiB/s | 573.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 57/545] Upgrading mpdecimal-0:4.0.1-1 100% | 106.8 MiB/s | 218.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 58/545] Upgrading pciutils-libs-0:3.1 100% |  32.7 MiB/s | 100.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 59/545] Upgrading xxd-2:9.1.1818-1.fc 100% |   1.7 MiB/s |  38.3 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 60/545] Upgrading whois-nls-0:5.6.5-1 100% |  26.3 MiB/s | 134.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 61/545] Upgrading vim-filesystem-2:9. 100% | 589.8 KiB/s |   4.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 62/545] Upgrading vim-common-2:9.1.18 100% |  96.0 MiB/s |  37.3 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 63/545] Upgrading pcre2-syntax-0:10.4 100% |  54.2 MiB/s | 277.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 64/545] Upgrading pcre2-0:10.46-1.fc4 100% |  66.7 KiB/s | 699.1 KiB |  00m10s
	==> vsphere-iso.fedora42srv: [ 65/545] Upgrading libselinux-0:3.8-3. 100% |   6.3 MiB/s | 194.3 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 66/545] Upgrading glib2-0:2.84.4-1.fc 100% | 151.6 MiB/s |  14.7 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 67/545] Upgrading libblockdev-utils-0 100% |  21.7 MiB/s |  44.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 68/545] Upgrading polkit-libs-0:126-3 100% |  65.6 MiB/s | 201.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 69/545] Upgrading libblockdev-0:3.3.1 100% |  90.9 MiB/s | 372.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 70/545] Upgrading json-glib-0:1.10.8- 100% |  32.8 MiB/s | 604.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 71/545] Upgrading libmodulemd-0:2.15. 100% |  23.4 MiB/s | 720.1 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 72/545] Upgrading libudisks2-0:2.10.9 100% | 200.5 MiB/s |   1.0 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 73/545] Upgrading libxmlb-0:0.3.24-1. 100% |   8.9 MiB/s | 282.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 74/545] Upgrading libselinux-utils-0: 100% |  10.2 MiB/s | 323.3 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 75/545] Upgrading libjcat-0:0.2.5-1.f 100% |   8.4 MiB/s | 216.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 76/545] Upgrading fprintd-0:1.94.5-1. 100% |  22.9 MiB/s | 845.3 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 77/545] Upgrading libblockdev-swap-0: 100% |   9.9 MiB/s |  20.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 78/545] Upgrading libblockdev-smart-0 100% |  19.6 MiB/s |  40.1 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 79/545] Upgrading libblockdev-part-0: 100% |   8.6 MiB/s |  44.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 80/545] Upgrading libblockdev-lvm-0:3 100% |  35.7 MiB/s |  73.1 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 81/545] Upgrading libblockdev-loop-0: 100% |   9.9 MiB/s |  20.3 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 82/545] Upgrading libblockdev-fs-0:3. 100% |  53.4 MiB/s | 109.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 83/545] Upgrading NetworkManager-libn 100% | 225.8 MiB/s |   9.9 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 84/545] Upgrading passim-libs-0:0.1.1 100% |  23.2 MiB/s |  71.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 85/545] Upgrading libsemanage-0:3.8.1 100% |  59.8 MiB/s | 306.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 86/545] Upgrading hwdata-0:0.400-1.fc 100% | 266.5 MiB/s |   9.6 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 87/545] Upgrading pciutils-0:3.14.0-1 100% |  10.0 MiB/s | 286.9 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 88/545] Upgrading firewalld-filesyste 100% | 857.4 KiB/s |   1.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 89/545] Upgrading fedora-release-iden 100% |   1.6 MiB/s |   3.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 90/545] Upgrading fedora-release-serv 100% | 121.1 KiB/s | 124.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [ 91/545] Upgrading fedora-release-comm 100% |   4.0 MiB/s |  24.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 92/545] Upgrading elfutils-default-ya 100% | 204.3 KiB/s |   2.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 93/545] Upgrading elfutils-libs-0:0.1 100% | 112.2 MiB/s | 689.3 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 94/545] Upgrading libssh-config-0:0.1 100% |  99.6 KiB/s | 816.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [ 95/545] Upgrading appstream-data-0:42 100% |  37.7 MiB/s |  15.7 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 96/545] Installing gnulib-l10n-0:2024 100% |  80.8 MiB/s | 661.9 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 97/545] Upgrading coreutils-common-0: 100% |  91.4 MiB/s |  11.2 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 98/545] Upgrading openssl-libs-1:3.2. 100% | 223.6 MiB/s |   7.8 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [ 99/545] Upgrading coreutils-0:9.6-6.f 100% |  82.6 MiB/s |   5.5 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [100/545] Upgrading ca-certificates-0:2 100% |   1.5 MiB/s |   2.5 MiB |  00m02s
	==> vsphere-iso.fedora42srv: [101/545] Upgrading krb5-libs-0:1.21.3- 100% | 143.2 MiB/s |   2.3 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [102/545] Upgrading openldap-0:2.6.10-1 100% | 128.8 MiB/s | 659.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [103/545] Upgrading libtirpc-0:1.3.7-1. 100% |  65.9 MiB/s | 202.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [104/545] Upgrading systemd-shared-0:25 100% | 257.9 MiB/s |   4.6 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [105/545] Upgrading which-0:2.23-2.fc42 100% |   3.5 MiB/s |  85.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [106/545] Upgrading cryptsetup-libs-0:2 100% | 203.4 MiB/s |   2.6 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [107/545] Upgrading pam-0:1.7.0-6.fc42. 100% |  17.5 MiB/s |   1.7 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [108/545] Upgrading libnfsidmap-1:2.8.4 100% |  27.9 MiB/s | 171.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [109/545] Upgrading selinux-policy-0:42 100% |   5.9 KiB/s |  33.1 KiB |  00m06s
	==> vsphere-iso.fedora42srv: [110/545] Upgrading selinux-policy-targ 100% |  82.8 MiB/s |  14.9 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [111/545] Upgrading libarchive-0:3.8.1- 100% | 155.8 MiB/s | 957.1 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [112/545] Upgrading libsss_certmap-0:2. 100% |  43.9 MiB/s | 134.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [113/545] Upgrading openssh-0:9.9p1-11. 100% |  37.3 MiB/s |   1.4 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [114/545] Installing cockpit-ws-selinux 100% |   4.2 KiB/s |  45.8 KiB |  00m11s
	==> vsphere-iso.fedora42srv: >>> Running pre-install scriptlet: smartmontools-selinux-1:7.5-3.fc42.noarch
	==> vsphere-iso.fedora42srv: >>> Finished pre-install scriptlet: smartmontools-selinux-1:7.5-3.fc42.noarch
	==> vsphere-iso.fedora42srv: >>> [RPM] libselinux: type 1: /etc/selinux/targeted/contexts/files/file_contexts
	==> vsphere-iso.fedora42srv: >>> [RPM] libselinux: type 1: /etc/selinux/targeted/contexts/files/file_contexts
	==> vsphere-iso.fedora42srv: [115/545] Upgrading smartmontools-selin 100% |   3.2 KiB/s |  34.1 KiB |  00m11s
	==> vsphere-iso.fedora42srv: [116/545] Upgrading sssd-nfs-idmap-0:2. 100% |  20.9 MiB/s |  42.9 KiB |  00m00s
	==> vsphere-iso.fedora42srv: >>> [RPM] libselinux: type 1: /etc/selinux/targeted/contexts/files/file_contexts
	==> vsphere-iso.fedora42srv: >>> [RPM] libselinux: type 1: /etc/selinux/targeted/contexts/files/file_contexts
	==> vsphere-iso.fedora42srv: [117/545] Upgrading vim-enhanced-2:9.1. 100% | 107.6 MiB/s |   4.2 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [118/545] Upgrading systemd-sysusers-0: 100% |   3.6 MiB/s |  84.9 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [119/545] Upgrading systemd-pam-0:257.1 100% |  33.4 MiB/s |   1.1 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [120/545] Upgrading systemd-0:257.10-1. 100% |  70.1 MiB/s |  12.3 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [121/545] Upgrading systemd-udev-0:257. 100% |  22.8 MiB/s |  12.3 MiB |  00m01s
	==> vsphere-iso.fedora42srv: [122/545] Upgrading dracut-0:107-4.fc42 100% |  20.7 MiB/s |   1.6 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [123/545] Installing kernel-modules-cor 100% |  86.3 MiB/s |  68.9 MiB |  00m01s
	==> vsphere-iso.fedora42srv: [124/545] Installing kernel-core-0:6.17 100% |  94.1 MiB/s |  29.5 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [125/545] Upgrading polkit-0:126-3.fc42 100% |  11.5 MiB/s | 470.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [126/545] Upgrading iscsi-initiator-uti 100% |   5.2 MiB/s | 164.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [127/545] Upgrading iscsi-initiator-uti 100% |  24.7 MiB/s |   1.4 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [128/545] Upgrading samba-common-2:4.22 100% |  14.8 MiB/s | 212.1 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [129/545] Upgrading libldb-2:4.22.6-1.f 100% |  29.7 MiB/s | 456.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [130/545] Upgrading libwbclient-2:4.22. 100% |  16.9 MiB/s |  69.3 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [131/545] Upgrading samba-client-libs-2 100% | 217.1 MiB/s |  19.5 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [132/545] Upgrading samba-common-libs-2 100% |  12.8 MiB/s | 261.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [133/545] Installing kernel-modules-0:6 100% |  12.6 MiB/s |  96.1 MiB |  00m08s
	==> vsphere-iso.fedora42srv: [134/545] Upgrading grub2-tools-1:2.12- 100% | 120.4 MiB/s |   7.7 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [135/545] Upgrading plymouth-0:24.004.6 100% |   8.7 MiB/s | 349.3 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [136/545] Upgrading plymouth-scripts-0: 100% |   1.4 MiB/s |  31.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [137/545] Upgrading wireless-regdb-0:20 100% | 600.9 KiB/s |  14.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [138/545] Upgrading bluez-0:5.84-2.fc42 100% |  58.8 MiB/s |   3.5 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [139/545] Upgrading rpcbind-0:1.2.8-0.f 100% |   2.4 MiB/s | 111.1 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [140/545] Upgrading wpa_supplicant-1:2. 100% | 109.1 MiB/s |   6.3 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [141/545] Upgrading bind-libs-32:9.18.4 100% | 211.6 MiB/s |   3.6 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [142/545] Upgrading libssh-0:0.11.3-1.f 100% | 139.0 MiB/s | 569.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [143/545] Upgrading libcurl-0:8.11.1-6. 100% |  74.1 MiB/s | 835.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [144/545] Upgrading NetworkManager-1:1. 100% |  17.3 MiB/s |   5.8 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [145/545] Upgrading elfutils-debuginfod 100% |   3.2 MiB/s |  86.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [146/545] Upgrading librepo-0:1.20.0-1. 100% |   1.5 MiB/s | 250.3 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [147/545] Upgrading libdnf5-0:5.2.17.0- 100% | 106.5 MiB/s |   3.8 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [148/545] Upgrading libdnf5-cli-0:5.2.1 100% | 100.4 MiB/s | 925.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [149/545] Upgrading libdnf-0:0.75.0-1.f 100% | 148.1 MiB/s |   2.2 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [150/545] Upgrading dnf5-0:5.2.17.0-1.f 100% |  54.1 MiB/s |   2.8 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [151/545] Upgrading dnf-data-0:4.24.0-1 100% |   1.9 MiB/s |  41.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [152/545] Upgrading binutils-0:2.44-6.f 100% |  85.6 MiB/s |  25.8 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [153/545] Upgrading NetworkManager-wwan 100% |  33.7 MiB/s | 138.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [154/545] Installing tpm2-tss-fapi-0:4. 100% |  57.2 MiB/s | 879.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [155/545] Upgrading sssd-client-0:2.11. 100% |   3.4 MiB/s | 340.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [156/545] Upgrading sssd-common-0:2.11. 100% |  69.2 MiB/s |   5.2 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [157/545] Upgrading sssd-krb5-common-0: 100% |  54.0 MiB/s | 221.3 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [158/545] Upgrading python-pip-wheel-0: 100% | 103.7 MiB/s |   1.2 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [159/545] Upgrading python3-libs-0:3.13 100% | 131.9 MiB/s |  40.5 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [160/545] Upgrading python3-0:3.13.9-1. 100% |   1.0 MiB/s |  30.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [161/545] Upgrading cockpit-bridge-0:34 100% |  26.0 MiB/s |   1.9 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [162/545] Upgrading cockpit-system-0:34 100% | 120.5 MiB/s |   3.0 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [163/545] Upgrading python3-libdnf-0:0. 100% | 233.5 MiB/s |   3.7 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [164/545] Upgrading python3-hawkey-0:0. 100% |  72.5 MiB/s | 297.1 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [165/545] Upgrading python3-firewall-0: 100% |  65.8 MiB/s |   2.8 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [166/545] Upgrading python3-libcomps-0: 100% |  46.2 MiB/s | 141.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [167/545] Upgrading python3-libselinux- 100% |  59.6 MiB/s | 610.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [168/545] Upgrading python3-setuptools- 100% |  67.9 MiB/s |   8.6 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [169/545] Upgrading unbound-libs-0:1.24 100% | 161.3 MiB/s |   1.5 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [170/545] Upgrading gnutls-dane-0:3.8.1 100% |  30.1 MiB/s |  61.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [171/545] Upgrading wget2-libs-0:2.2.0- 100% |  71.6 MiB/s | 366.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [172/545] Upgrading wget2-0:2.2.0-5.fc4 100% |  33.0 MiB/s |   1.1 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [173/545] Upgrading audit-rules-0:4.1.2 100% |   2.2 MiB/s | 120.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: >>> Running post-install scriptlet: audit-rules-0:4.1.2-2.fc42.x86_64
	==> vsphere-iso.fedora42srv: >>> Finished post-install scriptlet: audit-rules-0:4.1.2-2.fc42.x86_64
	==> vsphere-iso.fedora42srv: >>> Scriptlet output:
	==> vsphere-iso.fedora42srv: >>> No rules detected, adding default
	==> vsphere-iso.fedora42srv: >>> No rules
	==> vsphere-iso.fedora42srv: >>>
	==> vsphere-iso.fedora42srv: [174/545] Upgrading mdadm-0:4.3-8.fc42. 100% |  22.6 MiB/s |   1.0 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [175/545] Upgrading libblockdev-mdraid- 100% |  15.8 MiB/s |  32.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [176/545] Upgrading nss-0:3.117.0-1.fc4 100% | 117.8 MiB/s |   1.9 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [177/545] Upgrading nss-sysinit-0:3.117 100% | 767.7 KiB/s |  19.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [178/545] Upgrading libblockdev-crypto- 100% |  33.4 MiB/s |  68.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [179/545] Upgrading openssl-1:3.2.6-2.f 100% |  31.5 MiB/s |   1.7 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [180/545] Upgrading cockpit-ws-0:347-1. 100% |   6.1 MiB/s |   1.8 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [181/545] Upgrading libnvme-0:1.15-2.fc 100% |  59.3 MiB/s | 303.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [182/545] Upgrading libblockdev-nvme-0: 100% |  47.0 MiB/s |  48.1 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [183/545] Upgrading udisks2-0:2.10.91-1 100% |  20.3 MiB/s |   2.9 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [184/545] Upgrading opensc-libs-0:0.26. 100% | 162.8 MiB/s |   2.3 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [185/545] Upgrading opensc-0:0.26.1-3.f 100% |  26.4 MiB/s |   1.2 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [186/545] Upgrading cockpit-storaged-0: 100% |  11.8 MiB/s | 812.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [187/545] Upgrading udisks2-lvm2-0:2.10 100% | 124.4 MiB/s | 636.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [188/545] Upgrading udisks2-iscsi-0:2.1 100% | 142.5 MiB/s | 583.9 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [189/545] Upgrading cockpit-0:347-1.fc4 100% |  30.8 MiB/s |  63.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [190/545] Upgrading audit-0:4.1.2-2.fc4 100% |   5.6 KiB/s | 507.7 KiB |  01m30s
	==> vsphere-iso.fedora42srv: >>> Running post-install scriptlet: audit-0:4.1.2-2.fc42.x86_64
	==> vsphere-iso.fedora42srv: >>> Finished post-install scriptlet: audit-0:4.1.2-2.fc42.x86_64
	==> vsphere-iso.fedora42srv: >>> Scriptlet output:
	==> vsphere-iso.fedora42srv: >>> Warning: The unit file, source configuration file or drop-ins of auditd.serv
	==> vsphere-iso.fedora42srv: >>> Job for auditd.service failed because a timeout was exceeded.
	==> vsphere-iso.fedora42srv: >>> See "systemctl status auditd.service" and "journalctl -xeu auditd.service" f
	==> vsphere-iso.fedora42srv: >>>
	==> vsphere-iso.fedora42srv: [191/545] Upgrading wget2-wget-0:2.2.0- 100% |  17.3 KiB/s | 444.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [192/545] Upgrading python3-setools-0:4 100% |  88.6 MiB/s |   2.9 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [193/545] Upgrading python3-libsemanage 100% | 124.9 MiB/s | 383.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [194/545] Upgrading python3-dnf-0:4.24. 100% |  48.5 MiB/s |   2.7 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [195/545] Upgrading firewalld-0:2.3.1-1 100% |  23.9 MiB/s |   2.1 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [196/545] Upgrading cockpit-networkmana 100% |  98.5 MiB/s | 806.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [197/545] Upgrading cockpit-selinux-0:3 100% |  59.7 MiB/s | 428.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [198/545] Upgrading cockpit-packagekit- 100% |  70.5 MiB/s | 866.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [199/545] Upgrading python3-audit-0:4.1 100% |  93.8 MiB/s | 288.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [200/545] Upgrading crypto-policies-scr 100% |   8.5 MiB/s | 384.9 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [201/545] Upgrading nfs-utils-1:2.8.4-0 100% |   6.9 MiB/s |   1.3 MiB |  00m00s
	==> vsphere-iso.fedora42srv: >>> Running trigger-install scriptlet: nfs-utils-1:2.8.2-1.rc8.fc42.x86_64
	==> vsphere-iso.fedora42srv: >>> Finished trigger-install scriptlet: nfs-utils-1:2.8.2-1.rc8.fc42.x86_64
	==> vsphere-iso.fedora42srv: >>> Scriptlet output:
	==> vsphere-iso.fedora42srv: >>> Warning: The unit file, source configuration file or drop-ins of gssproxy.se
	==> vsphere-iso.fedora42srv: >>>
	==> vsphere-iso.fedora42srv: >>> Running trigger-install scriptlet: nfs-utils-1:2.8.4-0.fc42.x86_64
	==> vsphere-iso.fedora42srv: >>> Finished trigger-install scriptlet: nfs-utils-1:2.8.4-0.fc42.x86_64
	==> vsphere-iso.fedora42srv: >>> Scriptlet output:
	==> vsphere-iso.fedora42srv: >>> Warning: The unit file, source configuration file or drop-ins of gssproxy.se
	==> vsphere-iso.fedora42srv: >>>
	==> vsphere-iso.fedora42srv: >>> Running trigger-install scriptlet: nfs-utils-1:2.8.4-0.fc42.x86_64
	==> vsphere-iso.fedora42srv: >>> Finished trigger-install scriptlet: nfs-utils-1:2.8.4-0.fc42.x86_64
	==> vsphere-iso.fedora42srv: >>> Scriptlet output:
	==> vsphere-iso.fedora42srv: >>> Warning: The unit file, source configuration file or drop-ins of gssproxy.se
	==> vsphere-iso.fedora42srv: >>>
	==> vsphere-iso.fedora42srv: [202/545] Upgrading python3-argcomplete 100% |   9.5 MiB/s | 330.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [203/545] Upgrading python3-augeas-0:1. 100% |  43.0 MiB/s | 176.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [204/545] Upgrading python3-requests-0: 100% |  39.5 MiB/s | 485.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [205/545] Upgrading sos-0:4.10.0-1.fc42 100% |  26.3 MiB/s |   4.2 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [206/545] Upgrading gdb-headless-0:16.3 100% | 169.3 MiB/s |  15.7 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [207/545] Upgrading sssd-kcm-0:2.11.1-2 100% |  22.2 MiB/s | 227.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [208/545] Upgrading sssd-proxy-0:2.11.1 100% |   2.4 MiB/s | 163.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [209/545] Installing tpm2-tools-0:5.7-3 100% |  27.6 MiB/s |   1.5 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [210/545] Upgrading NetworkManager-blue 100% |  33.1 MiB/s | 101.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [211/545] Upgrading dnf5-plugins-0:5.2. 100% |  68.6 MiB/s |   1.4 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [212/545] Installing libdnf5-plugin-exp 100% |  42.8 MiB/s |  87.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [213/545] Upgrading elfutils-0:0.194-1. 100% |  79.2 MiB/s |   2.9 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [214/545] Upgrading NetworkManager-wifi 100% | 104.8 MiB/s | 321.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [215/545] Upgrading NetworkManager-team 100% |   4.7 MiB/s |  52.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [216/545] Upgrading appstream-0:1.1.0-1 100% |  98.4 MiB/s |   4.3 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [217/545] Upgrading curl-0:8.11.1-6.fc4 100% |  17.0 MiB/s | 453.1 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [218/545] Upgrading fwupd-0:2.0.16-1.fc 100% | 119.6 MiB/s |   9.1 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [219/545] Upgrading rsyslog-0:8.2508.0- 100% |  55.1 MiB/s |   2.8 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [220/545] Upgrading bind-utils-32:9.18. 100% |  21.9 MiB/s | 672.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [221/545] Upgrading grub2-pc-1:2.12-32. 100% | 277.3 KiB/s | 568.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [222/545] Installing kernel-0:6.17.6-20 100% | 121.1 KiB/s | 124.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [223/545] Upgrading realmd-0:0.17.1-17. 100% |  19.2 MiB/s | 847.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [224/545] Upgrading dracut-config-rescu 100% |   4.8 MiB/s |   5.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [225/545] Upgrading systemd-oomd-defaul 100% |  21.7 KiB/s | 976.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [226/545] Upgrading at-0:3.2.5-16.fc42. 100% |   2.2 MiB/s | 126.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [227/545] Upgrading chrony-0:4.8-1.fc42 100% |  12.3 MiB/s | 694.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [228/545] Upgrading dnsmasq-0:2.90-6.fc 100% |  20.8 MiB/s | 767.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [229/545] Upgrading iputils-0:20250605- 100% |  16.6 MiB/s | 835.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [230/545] Upgrading openssh-server-0:9. 100% |  23.7 MiB/s |   1.4 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [231/545] Upgrading systemd-resolved-0: 100% |  18.4 MiB/s | 677.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [232/545] Upgrading usb_modeswitch-0:2. 100% |   8.6 MiB/s | 219.9 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [233/545] Upgrading vim-default-editor- 100% |   1.2 MiB/s |   1.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [234/545] Upgrading smartmontools-1:7.5 100% |  56.9 MiB/s |   2.3 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [235/545] Upgrading openssh-clients-0:9 100% |  64.4 MiB/s |   2.7 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [236/545] Upgrading sudo-0:1.9.17-2.p1. 100% |  90.5 MiB/s |   5.1 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [237/545] Upgrading cryptsetup-0:2.8.1- 100% |  22.2 MiB/s | 772.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [238/545] Upgrading open-vm-tools-0:13. 100% |  47.4 MiB/s |   3.0 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [239/545] Upgrading iptables-nft-0:1.8. 100% |   6.8 MiB/s | 476.9 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [240/545] Upgrading tcpdump-14:4.99.5-4 100% |  40.5 MiB/s |   1.2 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [241/545] Upgrading fprintd-pam-0:1.94. 100% |   3.1 MiB/s |  31.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [242/545] Upgrading dbus-broker-0:36-6. 100% |  11.2 MiB/s | 389.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [243/545] Upgrading vim-minimal-2:9.1.1 100% |  55.3 MiB/s |   1.7 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [244/545] Upgrading whois-0:5.6.5-1.fc4 100% |   5.3 MiB/s | 174.9 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [245/545] Upgrading iwlwifi-mvm-firmwar 100% | 384.7 MiB/s |  62.7 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [246/545] Upgrading ntfs-3g-2:2022.10.3 100% |  11.9 MiB/s | 316.1 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [247/545] Upgrading ntfsprogs-2:2022.10 100% |  29.9 MiB/s |   1.0 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [248/545] Upgrading kexec-tools-0:2.0.3 100% |   9.4 MiB/s | 231.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [249/545] Installing qcom-wwan-firmware 100% |  73.6 MiB/s | 301.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [250/545] Upgrading amd-gpu-firmware-0: 100% | 184.4 MiB/s |  25.8 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [251/545] Upgrading amd-ucode-firmware- 100% |  68.9 MiB/s | 423.5 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [252/545] Upgrading atheros-firmware-0: 100% | 322.4 MiB/s |  40.9 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [253/545] Upgrading brcmfmac-firmware-0 100% | 265.4 MiB/s |   9.6 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [254/545] Upgrading cirrus-audio-firmwa 100% |  20.2 MiB/s |   2.1 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [255/545] Upgrading intel-audio-firmwar 100% | 236.1 MiB/s |   3.3 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [256/545] Upgrading intel-gpu-firmware- 100% | 243.9 MiB/s |   8.8 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [257/545] Upgrading intel-vsc-firmware- 100% | 350.8 MiB/s |   7.7 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [258/545] Upgrading iwlegacy-firmware-0 100% | 121.4 MiB/s | 124.3 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [259/545] Upgrading iwlwifi-dvm-firmwar 100% | 260.6 MiB/s |   1.8 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [260/545] Upgrading libertas-firmware-0 100% | 216.6 MiB/s |   1.3 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [261/545] Upgrading mt7xxx-firmware-0:2 100% | 369.3 MiB/s |  18.5 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [262/545] Upgrading nvidia-gpu-firmware 100% | 270.3 MiB/s | 101.1 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [263/545] Upgrading nxpwireless-firmwar 100% | 221.4 MiB/s | 906.9 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [264/545] Upgrading realtek-firmware-0: 100% | 227.9 MiB/s |   5.2 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [265/545] Upgrading tiwilink-firmware-0 100% | 286.6 MiB/s |   4.6 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [266/545] Upgrading btrfs-progs-0:6.16. 100% | 139.8 MiB/s |   6.3 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [267/545] Installing rpm-plugin-systemd 100% | 526.9 KiB/s |  13.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [268/545] Upgrading diffutils-0:3.12-1. 100% |  33.2 MiB/s |   1.6 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [269/545] Upgrading ethtool-2:6.15-3.fc 100% |   5.7 MiB/s | 998.9 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [270/545] Upgrading exfatprogs-0:1.3.0- 100% |   3.6 MiB/s | 297.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [271/545] Upgrading inih-0:62-1.fc42.x8 100% |  11.5 MiB/s |  23.6 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [272/545] Upgrading less-0:679-1.fc42.x 100% |  16.0 MiB/s | 409.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [273/545] Upgrading libgomp-0:15.2.1-3. 100% | 132.6 MiB/s | 543.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [274/545] Upgrading lua-libs-0:5.4.8-1. 100% |  91.8 MiB/s | 282.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [275/545] Upgrading pixman-0:0.46.2-1.f 100% | 173.7 MiB/s | 711.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [276/545] Upgrading publicsuffix-list-d 100% |  34.1 MiB/s |  69.8 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [277/545] Upgrading microcode_ctl-2:2.1 100% | 294.3 MiB/s |  14.4 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [278/545] Upgrading fonts-filesystem-1: 100% | 769.5 KiB/s | 788.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [279/545] Upgrading bash-color-prompt-0 100% |  16.2 MiB/s |  33.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [280/545] Upgrading alsa-sof-firmware-0 100% |  73.1 MiB/s |   9.9 MiB |  00m00s
	==> vsphere-iso.fedora42srv: [281/545] Removing fwupd-0:2.0.7-2.fc42 100% |   2.5 KiB/s | 139.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [282/545] Removing elfutils-0:0.192-9.f 100% |   2.5 KiB/s |  67.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [283/545] Removing gdb-headless-0:16.2- 100% |   3.1 KiB/s | 204.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [284/545] Removing nfs-utils-1:2.8.2-1. 100% |   2.7 KiB/s | 151.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [285/545] Removing binutils-0:2.44-3.fc 100% |  10.5 KiB/s | 247.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [286/545] Removing dnf5-plugins-0:5.2.1 100% |   5.7 KiB/s | 122.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [287/545] Removing dnf5-0:5.2.12.0-1.fc 100% |   2.9 KiB/s | 145.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [288/545] Removing open-vm-tools-0:12.4 100% |   3.4 KiB/s | 189.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [289/545] Removing openssh-server-0:9.9 100% | 815.0   B/s |  31.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [290/545] Removing sudo-0:1.9.15-7.p5.f 100% |   5.8 KiB/s | 160.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [291/545] Removing pam-0:1.7.0-4.fc42.x 100% |  17.8 KiB/s | 346.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [292/545] Removing libdnf5-cli-0:5.2.12 100% |   1.0 KiB/s |  24.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [293/545] Removing rsyslog-0:8.2412.0-3 100% |   2.7 KiB/s | 128.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [294/545] Removing audit-0:4.0.3-2.fc42 100% |   1.4 KiB/s |  47.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [295/545] Removing smartmontools-1:7.4- 100% | 977.0   B/s |  43.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [296/545] Removing dbus-broker-0:36-5.f 100% | 592.0   B/s |  16.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [297/545] Removing sssd-kcm-0:2.10.2-3. 100% | 419.0   B/s |  13.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [298/545] Removing appstream-0:1.0.4-2. 100% |   4.8 KiB/s |  73.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [299/545] Removing sssd-proxy-0:2.10.2- 100% | 391.0   B/s |   9.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [300/545] Removing chrony-0:4.6.1-2.fc4 100% | 744.0   B/s |  35.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [301/545] Removing rpcbind-0:1.2.7-1.rc 100% | 446.0   B/s |  21.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [302/545] Removing openssh-clients-0:9. 100% |   2.7 KiB/s |  41.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [303/545] Removing udisks2-iscsi-0:2.10 100% | 357.0   B/s |   5.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [304/545] Removing iscsi-initiator-util 100% |   1.6 KiB/s |  49.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [305/545] Removing elfutils-debuginfod- 100% |   1.1 KiB/s |  15.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [306/545] Removing elfutils-libs-0:0.19 100% |   5.4 KiB/s |  11.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [307/545] Removing udisks2-lvm2-0:2.10. 100% | 250.0   B/s |   5.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [308/545] Removing systemd-resolved-0:2 100% | 962.0   B/s |  26.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [309/545] Removing btrfs-progs-0:6.14-1 100% |   1.8 KiB/s |  58.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [310/545] Removing openssh-0:9.9p1-10.f 100% |   1.8 KiB/s |  29.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [311/545] Removing libarchive-0:3.7.7-4 100% | 928.0   B/s |  13.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [312/545] Removing libjcat-0:0.2.3-1.fc 100% | 600.0   B/s |  15.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [313/545] Removing bind-utils-32:9.18.3 100% |   3.4 KiB/s |  49.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [314/545] Removing bind-libs-32:9.18.33 100% |   1.6 KiB/s |  24.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [315/545] Removing iscsi-initiator-util 100% | 500.0   B/s |   8.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [316/545] Removing sssd-krb5-common-0:2 100% | 450.0   B/s |   9.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [317/545] Removing sssd-common-0:2.10.2 100% |   2.9 KiB/s | 213.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [318/545] Removing sssd-client-0:2.10.2 100% |   2.3 KiB/s |  49.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [319/545] Removing realmd-0:0.17.1-15.f 100% |   3.3 KiB/s |  90.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [320/545] Removing libuv-1:1.50.0-1.fc4 100% |   9.3 KiB/s |  19.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [321/545] Removing fprintd-pam-0:1.94.4 100% | 350.0   B/s |   7.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [322/545] Removing cryptsetup-0:2.7.5-2 100% |   8.0 KiB/s | 107.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [323/545] Removing libblockdev-lvm-0:3. 100% | 384.0   B/s |   5.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [324/545] Removing pciutils-0:3.13.0-7. 100% | 625.0   B/s |  15.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [325/545] Removing opensc-0:0.26.1-2.fc 100% |   5.6 KiB/s | 148.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [326/545] Removing kexec-tools-0:2.0.30 100% | 583.0   B/s |  14.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [327/545] Removing iputils-0:20240905-3 100% | 456.0   B/s |  42.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [328/545] Removing iptables-nft-0:1.8.1 100% |   2.5 KiB/s | 102.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [329/545] Removing vim-minimal-2:9.1.12 100% | 640.0   B/s |  16.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [330/545] Removing plymouth-0:24.004.60 100% |   7.6 KiB/s | 116.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [331/545] Removing plymouth-core-libs-0 100% | 736.0   B/s |  14.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [332/545] Removing at-0:3.2.5-14.fc42.x 100% |   1.2 KiB/s |  34.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [333/545] Removing iptables-libs-0:1.8. 100% |  16.2 KiB/s | 299.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [334/545] Removing tcpdump-14:4.99.5-3. 100% | 666.0   B/s |  16.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [335/545] Removing ntfsprogs-2:2022.10. 100% |   3.8 KiB/s | 101.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [336/545] Removing dnsmasq-0:2.90-4.fc4 100% | 956.0   B/s |  22.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [337/545] Removing NetworkManager-bluet 100% | 210.0   B/s |   4.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [338/545] Removing bluez-0:5.80-1.fc42. 100% |   2.2 KiB/s |  62.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [339/545] Removing NetworkManager-wifi- 100% | 210.0   B/s |   4.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [340/545] Removing wpa_supplicant-1:2.1 100% |   4.3 KiB/s |  66.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [341/545] Removing opensc-libs-0:0.26.1 100% |  13.2 KiB/s |  27.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [342/545] Removing c-ares-0:1.34.4-3.fc 100% | 769.0   B/s |  10.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [343/545] Removing libxmlb-0:0.3.22-1.f 100% | 441.0   B/s |  15.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [344/545] Removing audit-rules-0:4.0.3- 100% |   2.0 KiB/s |  50.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [345/545] Removing ntfs-3g-2:2022.10.3- 100% |   1.1 KiB/s |  27.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [346/545] Removing curl-0:8.11.1-4.fc42 100% |   1.3 KiB/s |  17.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [347/545] Removing NetworkManager-wwan- 100% | 538.0   B/s |   7.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [348/545] Removing fprintd-0:1.94.4-2.f 100% |   6.6 KiB/s | 101.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [349/545] Removing lua-libs-0:5.4.7-3.f 100% |   7.8 KiB/s |   8.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [350/545] Removing python3-libsemanage- 100% |   7.8 KiB/s |   8.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [351/545] Removing libsemanage-0:3.8-1. 100% |   5.9 KiB/s |  12.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [352/545] Removing python3-libselinux-0 100% |   1.6 KiB/s |  21.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [353/545] Removing ethtool-2:6.11-2.fc4 100% | 666.0   B/s |  16.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [354/545] Removing diffutils-0:3.10-9.f 100% |   4.4 KiB/s |  59.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [355/545] Removing ntfs-3g-libs-2:2022. 100% |   6.8 KiB/s |   7.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [356/545] Removing pciutils-libs-0:3.13 100% |   6.8 KiB/s |   7.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [357/545] Removing sssd-nfs-idmap-0:2.1 100% |   4.4 KiB/s |   9.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [358/545] Removing libnfsidmap-1:2.8.2- 100% |  10.7 KiB/s |  22.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [359/545] Removing samba-common-libs-2: 100% |   6.3 KiB/s |  13.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [360/545] Removing libldb-2:4.22.0-20.f 100% |   9.0 KiB/s |  37.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [361/545] Removing samba-client-libs-2: 100% |  29.2 KiB/s | 269.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [362/545] Removing libtirpc-0:1.3.6-1.r 100% |   5.9 KiB/s |  12.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [363/545] Removing libdrm-0:2.4.124-2.f 100% |  12.7 KiB/s |  26.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [364/545] Removing passim-libs-0:0.1.9- 100% | 500.0   B/s |   7.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [365/545] Removing whois-0:5.5.20-5.fc4 100% | 789.0   B/s |  15.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [366/545] Removing python3-setools-0:4. 100% |  18.0 KiB/s | 258.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [367/545] Removing exfatprogs-0:1.2.8-1 100% |   2.2 KiB/s |  29.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [368/545] Removing libsss_nss_idmap-0:2 100% |   7.8 KiB/s |   8.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [369/545] Removing libedit-0:3.1-55.202 100% | 846.0   B/s |  11.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [370/545] Removing usb_modeswitch-0:2.6 100% |   1.1 KiB/s |  16.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [371/545] Removing libusb1-0:1.0.28-2.f 100% | 846.0   B/s |  11.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [372/545] Removing less-0:668-2.fc42.x8 100% |   1.9 KiB/s |  23.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [373/545] Removing NetworkManager-team- 100% |   2.0 KiB/s |   4.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [374/545] Removing grub2-pc-1:2.12-28.f 100% | 333.0   B/s |   4.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [375/545] Removing python3-dnf-0:4.23.0 100% |   7.5 KiB/s | 276.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [376/545] Removing firewalld-0:2.3.0-4. 100% |  14.8 KiB/s | 439.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [377/545] Removing smartmontools-selinu 100% | 192.0   B/s |   5.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [378/545] Removing wireless-regdb-0:202 100% | 458.0   B/s |  11.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [379/545] Removing plymouth-scripts-0:2 100% | 333.0   B/s |   4.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [380/545] Removing cockpit-storaged-0:3 100% |  46.9 KiB/s |  48.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [381/545] Removing cockpit-networkmanag 100% |  49.8 KiB/s |  51.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [382/545] Removing cockpit-0:336.2-1.fc 100% |   2.9 KiB/s |   6.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [383/545] Removing fedora-release-commo 100% |   1.4 KiB/s |  29.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [384/545] Removing sos-0:4.8.2-2.fc42.n 100% |  32.6 KiB/s |   1.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [385/545] Removing python3-argcomplete- 100% |   3.0 KiB/s |  73.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [386/545] Removing crypto-policies-scri 100% |   6.2 KiB/s |  76.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [387/545] Removing cockpit-selinux-0:33 100% |  46.9 KiB/s |  48.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [388/545] Removing cockpit-system-0:336 100% | 202.1 KiB/s | 207.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [389/545] Removing cockpit-packagekit-0 100% |   7.7 KiB/s |  95.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [390/545] Removing cockpit-bridge-0:336 100% |  17.6 KiB/s | 253.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [391/545] Removing python3-firewall-0:2 100% |  89.8 KiB/s | 184.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [392/545] Removing dnf-data-0:4.23.0-1. 100% |  11.2 KiB/s |  23.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [393/545] Removing grub2-pc-modules-1:2 100% |  74.5 KiB/s | 305.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [394/545] Removing python3-setuptools-0 100% | 256.8 KiB/s |   1.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [395/545] Removing samba-common-2:4.22. 100% |   2.0 KiB/s |  27.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [396/545] Removing wget2-wget-0:2.2.0-3 100% | 166.0   B/s |   2.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [397/545] Removing vim-default-editor-2 100% |   3.9 KiB/s |   4.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [398/545] Removing tiwilink-firmware-0: 100% |  39.1 KiB/s |  40.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [399/545] Removing systemd-oomd-default 100% |   2.0 KiB/s |   4.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [400/545] Removing realtek-firmware-0:2 100% | 109.4 KiB/s | 112.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [401/545] Removing python3-requests-0:2 100% |  32.7 KiB/s |  67.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [402/545] Removing python3-augeas-0:1.1 100% |  10.7 KiB/s |  22.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [403/545] Removing nxpwireless-firmware 100% |   9.8 KiB/s |  10.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [404/545] Removing nvidia-gpu-firmware- 100% | 272.5 KiB/s | 558.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [405/545] Removing mt7xxx-firmware-0:20 100% |  46.9 KiB/s |  96.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [406/545] Removing linux-firmware-0:202 100% | 145.5 KiB/s |   1.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [407/545] Removing libertas-firmware-0: 100% |  27.3 KiB/s |  28.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [408/545] Removing iwlwifi-mvm-firmware 100% | 141.6 KiB/s | 145.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [409/545] Removing iwlwifi-dvm-firmware 100% |  13.7 KiB/s |  14.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [410/545] Removing iwlegacy-firmware-0: 100% |   3.9 KiB/s |   4.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [411/545] Removing intel-vsc-firmware-0 100% |  42.0 KiB/s |  43.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [412/545] Removing intel-gpu-firmware-0 100% | 127.9 KiB/s | 131.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [413/545] Removing intel-audio-firmware 100% |  56.6 KiB/s |  58.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [414/545] Removing dracut-config-rescue 100% |   2.0 KiB/s |   2.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [415/545] Removing cirrus-audio-firmwar 100% | 274.2 KiB/s |   1.1 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [416/545] Removing brcmfmac-firmware-0: 100% |  68.4 KiB/s | 140.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [417/545] Removing atheros-firmware-0:2 100% | 129.6 KiB/s | 398.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [418/545] Removing amd-ucode-firmware-0 100% |   9.3 KiB/s |  19.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [419/545] Removing amd-gpu-firmware-0:2 100% | 293.3 KiB/s | 901.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [420/545] Removing linux-firmware-whenc 100% |   0.0   B/s |   2.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [421/545] Removing fedora-release-ident 100% |   2.0 KiB/s |   6.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [422/545] Removing fedora-release-serve 100% |   0.0   B/s | 100.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [423/545] Removing firewalld-filesystem 100% |   9.8 KiB/s |  10.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [424/545] Removing whois-nls-0:5.5.20-5 100% |  15.6 KiB/s |  16.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [425/545] Removing hwdata-0:0.393-1.fc4 100% |  10.7 KiB/s |  11.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [426/545] Removing elfutils-default-yam 100% | 250.0   B/s |   1.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [427/545] Removing appstream-data-0:42- 100% | 301.0 KiB/s |   3.0 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [428/545] Removing publicsuffix-list-da 100% |   3.9 KiB/s |   4.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [429/545] Removing microcode_ctl-2:2.1- 100% |  73.7 KiB/s | 151.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [430/545] Removing fonts-filesystem-1:2 100% |   4.9 KiB/s |   5.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [431/545] Removing bash-color-prompt-0: 100% |   4.9 KiB/s |   5.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [432/545] Removing alsa-sof-firmware-0: 100% |  23.3 KiB/s | 502.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [433/545] Removing NetworkManager-1:1.5 100% | 302.0   B/s |  87.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [434/545] Removing libdnf5-0:5.2.12.0-1 100% |   5.3 KiB/s |  49.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [435/545] Removing cockpit-ws-0:336.2-1 100% |   4.7 KiB/s | 173.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [436/545] Removing udisks2-0:2.10.90-2. 100% |   3.6 KiB/s | 108.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [437/545] Removing libblockdev-crypto-0 100% |   4.9 KiB/s |   5.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [438/545] Removing nss-0:3.109.0-1.fc42 100% | 950.0   B/s |  19.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [439/545] Removing polkit-0:126-2.fc42. 100% |   2.4 KiB/s |  67.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [440/545] Removing nss-softokn-0:3.109. 100% |  12.2 KiB/s |  25.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [441/545] Removing python3-hawkey-0:0.7 100% |   8.3 KiB/s |  17.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [442/545] Removing NetworkManager-libnm 100% |  35.2 KiB/s |  72.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [443/545] Removing python3-libdnf-0:0.7 100% |  18.2 KiB/s |  56.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [444/545] Removing libdnf-0:0.74.0-1.fc 100% |  20.5 KiB/s |  63.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [445/545] Removing libstdc++-0:15.0.1-0 100% |   1.6 KiB/s |  31.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [446/545] Removing openssl-1:3.2.4-3.fc 100% |  11.6 KiB/s | 310.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [447/545] Removing vim-enhanced-2:9.1.1 100% | 291.0   B/s |   7.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [448/545] Removing wget2-0:2.2.0-3.fc42 100% |   3.0 KiB/s |  40.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [449/545] Removing wget2-libs-0:2.2.0-3 100% | 400.0   B/s |   8.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [450/545] Removing grub2-tools-1:2.12-2 100% | 650.0   B/s |  78.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [451/545] Removing dracut-0:105-2.fc42. 100% |  12.3 KiB/s | 452.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [452/545] Removing systemd-udev-0:257.3 100% |   5.4 KiB/s | 586.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [453/545] Removing systemd-0:257.3-7.fc 100% |  26.9 KiB/s | 990.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [454/545] Removing systemd-pam-0:257.3- 100% |   1.0 KiB/s |  13.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [455/545] Removing procps-ng-0:4.0.4-6. 100% |   3.3 KiB/s |  84.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [456/545] Removing xz-1:5.6.3-3.fc42.x8 100% |   9.3 KiB/s | 124.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [457/545] Removing cryptsetup-libs-0:2. 100% |  15.1 KiB/s |  31.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [458/545] Removing librepo-0:1.19.0-3.f 100% |   7.8 KiB/s |   8.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [459/545] Removing libcurl-0:8.11.1-4.f 100% |   3.4 KiB/s |   7.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [460/545] Removing libssh-0:0.11.1-4.fc 100% |   6.8 KiB/s |  14.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [461/545] Removing krb5-libs-0:1.21.3-5 100% |   4.5 KiB/s |  64.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [462/545] Removing libselinux-utils-0:3 100% |   3.6 KiB/s |  97.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [463/545] Removing systemd-sysusers-0:2 100% | 461.0   B/s |   6.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [464/545] Removing systemd-shared-0:257 100% |   3.4 KiB/s |   7.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [465/545] Removing libblockdev-fs-0:3.3 100% |   4.9 KiB/s |   5.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [466/545] Removing libblockdev-nvme-0:3 100% |   4.9 KiB/s |   5.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [467/545] Removing libnvme-0:1.12-1.fc4 100% |   6.3 KiB/s |  13.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [468/545] Removing pam-libs-0:1.7.0-4.f 100% |  15.6 KiB/s |  16.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [469/545] Removing openldap-0:2.6.9-3.f 100% |   2.0 KiB/s |  26.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [470/545] Removing gpgme-0:1.24.2-1.fc4 100% |   1.3 KiB/s |  17.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [471/545] Removing libsolv-0:0.7.31-5.f 100% |   5.4 KiB/s |  11.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [472/545] Removing libblockdev-loop-0:3 100% |   4.9 KiB/s |   5.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [473/545] Removing libblockdev-mdraid-0 100% | 263.0   B/s |   5.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [474/545] Removing mdadm-0:4.3-7.fc42.x 100% |   1.2 KiB/s |  46.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [475/545] Removing grub2-tools-minimal- 100% |   2.0 KiB/s |  27.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [476/545] Removing gnutls-dane-0:3.8.9- 100% |   4.9 KiB/s |   5.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [477/545] Removing unbound-libs-0:1.22. 100% |   7.3 KiB/s |  15.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [478/545] Removing libblockdev-swap-0:3 100% |   4.9 KiB/s |   5.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [479/545] Removing libblockdev-0:3.3.0- 100% |  10.7 KiB/s |  11.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [480/545] Removing libblockdev-part-0:3 100% | 416.0   B/s |   5.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [481/545] Removing libmodulemd-0:2.15.0 100% |   1.2 KiB/s |  16.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [482/545] Removing nss-softokn-freebl-0 100% |  13.7 KiB/s |  14.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [483/545] Removing polkit-libs-0:126-2. 100% | 846.0   B/s |  11.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [484/545] Removing nss-sysinit-0:3.109. 100% | 583.0   B/s |   7.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [485/545] Removing nss-util-0:3.109.0-1 100% |   5.9 KiB/s |   6.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [486/545] Removing nspr-0:4.36.0-5.fc42 100% |  11.7 KiB/s |  12.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [487/545] Removing libblockdev-smart-0: 100% |   4.9 KiB/s |   5.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [488/545] Removing libblockdev-utils-0: 100% |   4.9 KiB/s |   5.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [489/545] Removing libeconf-0:0.7.6-1.f 100% |  10.7 KiB/s |  11.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [490/545] Removing python3-libcomps-0:0 100% |  13.7 KiB/s |  14.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [491/545] Removing libcomps-0:0.1.21-5. 100% |   7.8 KiB/s |   8.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [492/545] Removing libwbclient-2:4.22.0 100% |   3.9 KiB/s |   4.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [493/545] Removing elfutils-libelf-0:0. 100% |  14.6 KiB/s |  15.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [494/545] Removing libxcrypt-0:4.4.38-6 100% |   1.5 KiB/s |  18.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [495/545] Removing file-0:5.46-1.fc42.x 100% | 833.0   B/s |  10.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [496/545] Removing file-libs-0:5.46-1.f 100% |   1.1 KiB/s |  15.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [497/545] Removing which-0:2.23-1.fc42. 100% |   1.2 KiB/s |  15.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [498/545] Removing json-glib-0:1.10.6-2 100% |  36.1 KiB/s |  74.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [499/545] Removing bluez-libs-0:5.80-1. 100% |   6.8 KiB/s |   7.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [500/545] Removing libsss_certmap-0:2.1 100% |  12.7 KiB/s |  13.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [501/545] Removing pixman-0:0.44.2-2.fc 100% |   6.8 KiB/s |   7.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [502/545] Removing libgomp-0:15.0.1-0.1 100% |   8.8 KiB/s |   9.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [503/545] Removing python3-audit-0:4.0. 100% |  11.7 KiB/s |  12.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [504/545] Removing audit-libs-0:4.0.3-2 100% |  13.7 KiB/s |  14.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [505/545] Removing libudisks2-0:2.10.90 100% | 500.0   B/s |   6.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [506/545] Removing glib2-0:2.84.0-1.fc4 100% |  10.8 KiB/s | 177.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [507/545] Removing gnutls-0:3.8.9-3.fc4 100% |  16.1 KiB/s |  33.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [508/545] Removing libsss_sudo-0:2.10.2 100% |   2.4 KiB/s |   5.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [509/545] Removing libsss_idmap-0:2.10. 100% | 500.0   B/s |   7.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [510/545] Removing python3-0:3.13.2-2.f 100% | 857.0   B/s |  12.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [511/545] Removing python3-libs-0:3.13. 100% | 180.8 KiB/s |   2.2 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [512/545] Removing sqlite-libs-0:3.47.2 100% | 538.0   B/s |   7.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [513/545] Removing expat-0:2.7.1-1.fc42 100% |   1.1 KiB/s |  14.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [514/545] Removing xz-libs-1:5.6.3-3.fc 100% |   6.8 KiB/s |   7.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [515/545] Removing mpdecimal-0:4.0.0-2. 100% |   9.8 KiB/s |  10.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [516/545] Removing protobuf-c-0:1.5.0-4 100% |   9.8 KiB/s |  10.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [517/545] Removing inih-0:58-3.fc42.x86 100% |   2.6 KiB/s |   8.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [518/545] Removing vim-common-2:9.1.122 100% | 143.7 KiB/s |   2.4 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [519/545] Removing selinux-policy-0:41. 100% |   1.5 KiB/s |  12.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [520/545] Removing selinux-policy-targe 100% | 132.1 KiB/s |   1.7 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [521/545] Removing python-pip-wheel-0:2 100% | 307.0   B/s |   4.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [522/545] Removing coreutils-0:9.6-2.fc 100% |  14.8 KiB/s | 304.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [523/545] Removing openssl-libs-1:3.2.4 100% |   2.2 KiB/s |  38.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [524/545] Removing ca-certificates-0:20 100% |  51.4 KiB/s | 789.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [525/545] Removing crypto-policies-0:20 100% |  61.8 KiB/s | 190.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [526/545] Removing coreutils-common-0:9 100% |  82.0 KiB/s | 252.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [527/545] Removing vim-data-2:9.1.1227- 100% |   0.0   B/s |   7.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [528/545] Removing vim-filesystem-2:9.1 100% |  16.1 KiB/s |  33.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [529/545] Removing grub2-common-1:2.12- 100% |  55.7 KiB/s |  57.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [530/545] Removing libssh-config-0:0.11 100% |   0.0   B/s |   3.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [531/545] Removing systemd-libs-0:257.3 100% |   1.2 KiB/s |  21.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [532/545] Removing p11-kit-trust-0:0.25 100% | 600.0   B/s |  12.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [533/545] Removing libselinux-0:3.8-1.f 100% | 615.0   B/s |   8.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [534/545] Removing p11-kit-0:0.25.5-5.f 100% |   3.7 KiB/s |  99.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [535/545] Removing alternatives-0:1.32- 100% | 923.0   B/s |  12.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [536/545] Removing pcre2-0:10.45-1.fc42 100% | 692.0   B/s |   9.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [537/545] Removing xxd-2:9.1.1227-1.fc4 100% | 583.0   B/s |   7.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [538/545] Removing zlib-ng-compat-0:2.2 100% |   4.9 KiB/s |   5.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [539/545] Removing pcre2-syntax-0:10.45 100% |   1.3 KiB/s |  16.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [540/545] Removing glibc-0:2.41-1.fc42. 100% |   6.2 KiB/s | 102.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [541/545] Removing glibc-langpack-en-0: 100% | 240.2 KiB/s | 492.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [542/545] Removing glibc-gconv-extra-0: 100% |  25.9 KiB/s | 637.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [543/545] Removing glibc-common-0:2.41- 100% |   1.3 KiB/s |  50.0   B |  00m00s
	==> vsphere-iso.fedora42srv: [544/545] Removing filesystem-0:3.18-36 100% | 352.0 KiB/s |  16.9 KiB |  00m00s
	==> vsphere-iso.fedora42srv: [545/545] Removing libgcc-0:15.0.1-0.11 100% |   0.0   B/s |  11.0   B |  01m04s
	==> vsphere-iso.fedora42srv: >>> Running post-transaction scriptlet: systemd-0:257.10-1.fc42.x86_64
	==> vsphere-iso.fedora42srv: >>> Finished post-transaction scriptlet: systemd-0:257.10-1.fc42.x86_64
	==> vsphere-iso.fedora42srv: >>> [RPM] libselinux: type 1: /etc/selinux/targeted/contexts/files/file_contexts
	==> vsphere-iso.fedora42srv: >>> [RPM] libselinux: type 1: /etc/selinux/targeted/contexts/files/file_contexts
	==> vsphere-iso.fedora42srv: Complete!
	==> vsphere-iso.fedora42srv: Removed 18 files, 11 directories (total of 97 MiB). 0 errors occurred.
	==> vsphere-iso.fedora42srv: Executing shutdown command...
	==> vsphere-iso.fedora42srv: Deleting Floppy drives...
	==> vsphere-iso.fedora42srv: Ejecting CD-ROM media...
	==> vsphere-iso.fedora42srv: Convert VM into template...
	==> vsphere-iso.fedora42srv: Exporting to Open Virtualization Format (OVF)...
	==> vsphere-iso.fedora42srv: Downloading Fedorasrv42_Demo-disk-0.vmdk...
	==> vsphere-iso.fedora42srv: Exporting Fedorasrv42_Demo-disk-0.vmdk...
	==> vsphere-iso.fedora42srv: Downloading Fedorasrv42_Demo-disk-1.nvram...
	==> vsphere-iso.fedora42srv: Exporting Fedorasrv42_Demo-disk-1.nvram...
	==> vsphere-iso.fedora42srv: Writing OVF descriptor Fedorasrv42_Demo.ovf...
	==> vsphere-iso.fedora42srv: Creating SHA256 manifest Fedorasrv42_Demo.mf...
	==> vsphere-iso.fedora42srv: Completed export to Open Virtualization Format (OVF).
	==> vsphere-iso.fedora42srv: Clear boot order...
	==> vsphere-iso.fedora42srv: Closing sessions ....
	==> vsphere-iso.fedora42srv: Running post-processor:  (type shell-local)
	==> vsphere-iso.fedora42srv (shell-local): Running local shell script: /var/folders/sw/fs5srh7d2g11p6q8bqbh0rnr0000gn/T/packer-shell1162813039
	==> vsphere-iso.fedora42srv (shell-local): Opening OVF source: ./output-artifacts/Fedorasrv42_Demo.ovf
	==> vsphere-iso.fedora42srv (shell-local): The manifest validates
	==> vsphere-iso.fedora42srv (shell-local): Opening OVA target: ./output-artifacts/Fedorasrv42_Demo-20251105224112.ova
	==> vsphere-iso.fedora42srv (shell-local): Writing OVA package: ./output-artifacts/Fedorasrv42_Demo-20251105224112.ova
	==> vsphere-iso.fedora42srv (shell-local): Transfer Completed
	==> vsphere-iso.fedora42srv (shell-local): Completed successfully
	Build 'vsphere-iso.fedora42srv' finished after 13 minutes 20 seconds.

	==> Wait completed after 13 minutes 20 seconds

	==> Builds finished. The artifacts of successful builds are:
	--> vsphere-iso.fedora42srv: Fedorasrv42_Demo
	--> vsphere-iso.fedora42srv: Fedorasrv42_Demo

## freebsd14srv\_vsphere.pkr.hcl ##

Variables:

 | Name                  | Description  | Type | Default | Required | Adjust for deployment environment |
 |:----------------------|:-------------|:-----|:--------|:--------:|:--------------------:|
 | remote\_username      | User name for login | string  | None  | Yes | Yes |
 | remote\_password      | User password for login  | string | None | Yes | Yes |
 | convert\_to\_template | Convert the virtual machine to a template after the build is complete. If set to true, the virtual machine can not be imported into a content library | bool | true | Yes | Yes |
 | datacenter            | vCenter datacenter to install VM | string | None | Yes | Yes |
 | esxi\_server          | esxi server IP/FQDN | string | None | Yes | Yes |
 | output\_directory     | Output directory for VM artifacts |string | ./output-artifacts | Yes | Yes |
 | root\_password\_enc   | VM's root password for login  | string | encypted string for the password 'packer' | Yes | Yes |
 | ssh\_password         | Plain text to for the ssh connection | string | packer | Yes | Yes |
 | ssh\_password_enc     | User name to for the ssh connection | string | packer | Yes | Yes |
 | ssh\_user             | User name to for the ssh connection | string | packer | Yes | Yes |
 | vcenter\_server       | vCenter Server IP/FQDN | string | None | Yes | Yes |
 | vm\_name              | Virtual Machine name to build  | string | Fedorasrv42\_Demo | Yes | Yes |

### Sample command line ###
The variables in the vcenter01.pkvars.pcl file is not set. They will
need to be configured for current environment.

    packer build -force -var-file=vcenter01.pkvars.hcl freebsd14srv_vsphere.pkr.hcl
