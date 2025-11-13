packer {
  required_version = ">= 1.14.0"
  required_plugins {
    vsphere-iso = {
      version = "~> 1.2.7"
      source  = "github.com/hashicorp/vsphere"
    }
  }
}

source "vsphere-iso" "archlinux" {
  iso_url              = "${var.iso_url}"
  iso_checksum         = "${var.iso_checksum}"
  http_directory       = "http/archlinux/files"
  ssh_username         = "${var.ssh_user}"
  ssh_password         = "${var.ssh_password}"
  ssh_private_key_file = "${var.ssh_private_key_file}"

  ip_wait_timeout   = "10m"
  ip_settle_timeout = "1m"
  vcenter_server    = "${var.vcenter_server}"
  host              = "${var.esxi_server}"
  username          = "${var.remote_username}"
  password          = "${var.remote_password}"
  datacenter        = "${var.datacenter}"
  datastore         = "${var.vcenter_datastore}"
  # Any firewalls must allow this port range.
  http_port_min       = 8100
  http_port_max       = 8400
  shutdown_command    = "shutdown -f now"
  insecure_connection = true # This may need to set to true if using autogenrated certs.
  storage {
    disk_size             = 40000
    disk_thin_provisioned = true
  }
  vm_name    = "${var.vm_name}"
  vm_version = 20
  CPUs       = 4
  RAM        = 4096
  #  other6xLinux64Guest        Other 6.x or later Linux (64-bit)
  #  other6xLinuxGuest          Other 6.x or later Linux (32-bit)


  guest_os_type       = "other6xLinux64Guest"
  convert_to_template = var.convert_to_template
  export {
    force            = true
    output_directory = "./output-artifacts"
    image_files      = true
  }
  # If more than one network adapter is defined
  # The network configuration section will need to be modified
  # bsdinstall netconfig and the dhcpclient areas will need changes.
  network_adapters {
    network      = "VM Network"
    network_card = "vmxnet3"
  }
  boot_wait = "60s" # This may need to be adjusted based on the environment.
  # The bsdinstall sections are called manual, make sure the
  # default BSDINSTALL are set see the bsdinstall man page for more information.
  boot_command = [
    "<enter>",
    "<wait>echo \"${var.public_key}\" >> /root/.ssh/authorized_keys<enter>",
  ]
}

build {
  sources = ["source.vsphere-iso.archlinux"]
  provisioner "shell" {
    inline = [
      "mkdir -p /tmp/install",
    ]
  }
  provisioner "file" {
    sources = ["files/archlinux/setup_phase_1.sh",
      "files/archlinux/install_pkgs.sh",
      "files/archlinux/setup_grub.sh",
      "files/archlinux/setup_install_ssh_keys.sh",
      "files/archlinux/setup_phase_1.sh",
      "files/archlinux/setup_umount_fs.sh",
      "files/archlinux/update_etc_issue.sh",
      "assets/id_rsa.pub",
    ]
    destination = "/tmp/install/"
  }
  provisioner "shell" {
    execute_command = "/bin/sh \"{{ .Path }}\""
    inline = [
      "echo \"{INFO] Starting Configuration.\"",
    ]
  }
  provisioner "shell" {
    # this script will move files above to chroot /root  directory.
    script = "./files/archlinux/setup_phase_1.sh"
  }
  provisioner "shell" {
    inline = [
      "arch-chroot /mnt /root/install_pkgs.sh ${var.adminuser}",
      "arch-chroot /mnt rm -f /root/install_pkgs.sh",
      "arch-chroot /mnt echo \"${var.hostname}\" > /etc/hostname",
      "echo \"[INFO] Setting password for root.\"",
      "arch-chroot /mnt usermod -p '${var.root_password_enc}' root",
      "echo \"[INFO] Setting password for ${var.adminuser}.\"",
      "arch-chroot /mnt usermod -p '${var.adminuser_password_enc}' ${var.adminuser}",
      "arch-chroot /mnt /root/setup_install_ssh_keys.sh ${var.install_ssh_key} ${var.adminuser}",
      "arch-chroot /mnt rm -f /root/setup_install_ssh_keys.sh",
      "arch-chroot /mnt /root/setup_grub.sh",
      "arch-chroot /mnt rm -f /root/setup_grub.sh",
      "arch-chroot /mnt rm -f /root/install_disk_prefix.sh",
      "arch-chroot /mnt rm -f /root/setup_phase_1.sh",
      "arch-chroot /mnt rm -f /root/setup_umount_fs.sh",
      "arch-chroot /mnt ls -la /root",
      "/tmp/install/setup_umount_fs.sh",
    ]
  }
  post-processor "shell-local" {
    inline = [
      "ovftool \"${var.output_directory}/${var.vm_name}.ovf\" \"${var.output_directory}/${local.artifact_name}\"",
    ]
  }
}

locals {
  artifact_name = "${var.vm_name}-${local.current_time}.ova"
  current_time  = formatdate("YYYYMMDDhhmmss", timestamp())
}

variable "adminuser" {
  type        = string
  default     = "packer"
  description = "Admin User acccount to set in the VM."
}

variable "adminuser_password" {
  type        = string
  default     = "packer"
  description = "Password to set in the VM for adminuser."
}

variable "adminuser_password_enc" {
  type        = string
  default     = "$1$packer$zBicTzVGZp3.RqEuQUnd1/"
  description = "Encrypted password to set in the VM for adminuser."
}

variable "convert_to_template" {
  type        = bool
  default     = true
  description = "Convert the virtual machine to a template after the build is complete. If set to true, the virtual machine can not be imported into a content library."
}

variable "datacenter" {
  type        = string
  description = "Remote esxi server."
}

variable "esxi_server" {
  type        = string
  description = "esxi server."
}

variable "hostname" {
  type        = string
  default     = "archlinux3_001"
  description = "Hostname to use for the system."
}

variable "install_ssh_key" {
  type        = string
  default     = "root"
  description = "Indicates if the systems unique ssh should be installed for the default following users"
}

# Replace with the actual checksum for the specific iso.
variable "iso_checksum" {
  type        = string
  default     = "sha256:86bde4fa571579120190a0946d54cd2b3a8bf834ef5c95ed6f26fbb59104ea1d" # Replace with the actual checksum
  description = "Check sum for iso file"
}

# To use a local file use the relative or absolute path to iso.
# Check the base url https://dfw.mirror.rackspace.com/archlinux/iso
# only the past three months are normally available.
variable "iso_url" {
  type        = string
  default     = "https://dfw.mirror.rackspace.com/archlinux/iso/2025.10.01/archlinux-2025.10.01-x86_64.iso"
  description = "URL for iso file"
}

variable "output_directory" {
  type        = string
  default     = "./output-artifacts"
  description = "Output directory for VM artifacts"
}

variable "public_key" {
  type        = string
  description = "Public key for ssh login."
}
variable "remote_password" {
  type        = string
  description = "User password for login."
}

variable "remote_username" {
  type        = string
  description = "User name for login."
}
# openssl passwd -1 -salt xxxxxxxx password
# $1$xxxxxxxx$UYCIxa628.9qXjpQCjM4a.
# To generate an encypted password.
# The use the entire genrated string.
# The salt may be anything you wish, it will be
# included in the generated string.
# Use -1 for MD5 -6 for SHA512

variable "root_password_enc" {
  type        = string
  default     = "$1$packer$zBicTzVGZp3.RqEuQUnd1/"
  description = "Root password to set in the VM."
}

variable "ssh_password" {
  type        = string
  default     = "packer"
  description = "ssh password to set in the VM."
}

variable "ssh_password_enc" {
  type        = string
  default     = "$1$packer$zBicTzVGZp3.RqEuQUnd1/"
  description = "ssh password to set in the VM."
}

variable "ssh_private_key_file" {
  type        = string
  default     = "./assets/id_rsa"
  description = "Private key for to allow login via ssh"
}

variable "ssh_user" {
  type        = string
  default     = "root"
  description = "ssh user to set in the VM."
}

variable "vcenter_datastore" {
  type        = string
  default     = "datastore1"
  description = "Datastore to create the VM."
}

variable "vcenter_server" {
  type        = string
  description = "vCenter server."
}

variable "vm_name" {
  type        = string
  default     = "Archlinux3_Demo"
  description = "Virtual Machine name to build"
}
