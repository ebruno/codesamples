packer {
  required_version = ">= 1.14.0"
  required_plugins {
    qemu = {
      version = "~> 1.1.4"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

source "qemu" "archlinux" {
  iso_url           = "${var.iso_url}"
  iso_checksum      = "${var.iso_checksum}"
  vm_name           = "${var.vm_name}.qcow2"
  disk_size         = "40G"
  format            = "qcow2" # Specify qcow2 as the desired disk format
  accelerator       = "kvm"
  headless          = "true"
  memory            = 2048
  net_device        = "virtio-net"
  disk_interface    = "virtio"
  boot_wait         = "10s"
  vtpm              = false
  machine_type      = "q35"
  use_pflash        = true
  efi_boot          = true
  efi_firmware_code = "${var.efi_firmware_code}"
  efi_firmware_vars = "${var.efi_firmware_vars}"
  efi_drop_efivars  = false
  boot_key_interval = "10ms" # Depending on the environment this value may need to be increased.
  boot_command = [
    "<enter>",
    "<wait30>",
    "echo \"${var.public_key}\" >> /root/.ssh/authorized_keys<enter>"
  ]
  output_directory     = local.output_directory
  ssh_username         = "root"
  ssh_private_key_file = "./assets/id_rsa"
  ssh_wait_timeout     = "20m"
}

build {
  name    = "runner-vm"
  sources = ["source.qemu.archlinux"]
  provisioner "shell" {
    inline = [
      "mkdir -p /tmp/install",
    ]
  }
  provisioner "file" {
    sources     = ["install_pkgs.sh", "setup_grub.sh", "setup_umount_fs.sh", "assets/id_rsa.pub", "setup_install_ssh_keys.sh","update_etc_issue.sh","show_ip_on_login.service"]
    destination = "/tmp/install/"
  }
  provisioner "shell" {
    # this script will move files above to chroot /root  directory.
    script = "./setup_phase_1.sh"
  }

  provisioner "shell" {
    inline = [
      "arch-chroot /mnt /root/install_pkgs.sh",
      "arch-chroot /mnt rm -f /root/install_pkgs.sh",
      "arch-chroot /mnt echo \"${var.hostname}\" > /etc/hostname",
      "echo \"[INFO] Setting password for root.\"",
      "arch-chroot /mnt usermod -p '${var.root_passwd}' root",
      "echo \"[INFO] Setting password for builduser.\"",
      "arch-chroot /mnt usermod -p '${var.builduser_passwd}' builduser",
      "arch-chroot /mnt /root/setup_install_ssh_keys.sh ${var.install_ssh_key}",
      "arch-chroot /mnt rm -f /root/setup_install_ssh_keys.sh",
      "arch-chroot /mnt /root/setup_grub.sh",
      "arch-chroot /mnt rm -f /root/setup_grub.sh",
      "/tmp/install/setup_umount_fs.sh",
    ]
  }
  post-processor "shell-local" {
    inline = [
      <<EOT
 #!/usr/bin/env bash
 cat << EOF > ./create_${var.vm_name}_vm.sh
# Sample commands to create the virtual machine xml file.
#!/usr/bin/env bash
echo "[INFO] Copying ${var.vm_name}.qcow2 to ${var.libvirt_vm_image_dir}";
sudo cp  ./${local.output_directory}/${var.vm_name}.qcow2 ${var.libvirt_vm_image_dir}/${var.vm_name}.qcow2;
sudo chown ${var.libvirt_owner}:${var.libvirt_group} ${var.libvirt_vm_image_dir}/${var.vm_name}.qcow2;
sudo chmod 664 ${var.libvirt_vm_image_dir}/${var.vm_name}.qcow2;
echo "[INFO] Copying efivars.fd to ${var.libvirt_nvram_dir}/${var.vm_name}_VARS.fd";
sudo cp ./${local.output_directory}/efivars.fd ${var.libvirt_nvram_dir}/${var.vm_name}_VARS.fd;
sudo chown ${var.nvram_owner}:${var.nvram_group} ${var.libvirt_nvram_dir}/${var.vm_name}_VARS.fd;
sudo chmod 664 ${var.libvirt_nvram_dir}/${var.vm_name}_VARS.fd;
sudo virt-install \
--name archlinux_test01 \
--memory 4086 \
--vcpus 4 \
--disk path=${var.libvirt_vm_image_dir}/${var.vm_name}.qcow2,format=qcow2 \
--disk device=cdrom,bus=sata \
--import \
--network bridge=bridge0 \
--os-variant archlinux \
--graphics vnc,listen=0.0.0.0 \
--boot uefi,loader=${var.efi_firmware_code},nvram=${var.libvirt_nvram_dir}/${var.vm_name}_VARS.fd \
--print-xml > ./${var.vm_name}.xml;
sudo virsh define ./${var.vm_name}.xml;
EOF
EOT
    ]
  }
  post-processor "shell-local" {
    inline = [
      "chmod a+x ./create_${var.vm_name}_vm.sh",
      "cat ./create_${var.vm_name}_vm.sh",
    ]
  }
  post-processor "checksum" {
    checksum_types = ["sha1", "sha256"]
    output         = "packer_{{.BuildName}}_{{.ChecksumType}}.txt"
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}

locals {
  output_directory = "output/${var.vm_name}"
}

variable "builduser_passwd" {
  type        = string
  description = "Password for builduser default is packer"
}

variable "efi_firmware_code" {
  type        = string
  default     = "/usr/share/OVMF/OVMF_CODE_4M.fd"
  description = "The location and name of this may vary accross operating systems."
}

variable "efi_firmware_vars" {
  type        = string
  default     = "/usr/share/OVMF/OVMF_VARS_4M.fd"
  description = "The location and name of this may vary accross operating systems."
}

variable "hostname" {
  type        = string
  default     = "archlinuxvmNN"
  description = "Hostname"
}

variable "install_ssh_key" {
  type        = string
  default     = "root builduser"
  description = "Indicates if the systems unique ssh should be installed for the default following users"
}

# Replace with the actual checksum for the specific iso.
variable "iso_checksum" {
  type = string
  #  default  = "sha256:4b1af44dbeed97acec0204a95f6393818bb8fd903b423a20b7ea141f80b27e59" # Replace with the actual checksum
  description = "Check sum for iso file"
}

# To use a local file use the relative or absolute path to iso.
variable "iso_url" {
  type = string
  # default = "archlinux-2025.08.01-x86_64.iso"
  description = "URL for iso file"
}

variable "libvirt_nvram_dir" {
  type        = string
  default     = "/var/lib/libvirt/qemu/nvram"
  description = "Location for virtural machine nvram files in your environment"
}

variable "libvirt_vm_image_dir" {
  type        = string
  default     = "/var/lib/libvirt/images"
  description = "Location for virtural machine images in your environment"
}

variable "libvirt_owner" {
      type = string
      default = "root"
      description = "Name of the owner of the images directory"
}

variable "libvirt_group" {
      type = string
      default = "libvirt"
      description = "Name of the group of the images directory"
}

variable "nvram_owner" {
      type = string
      default = "root"
      description = "Name of the owner of the nvram images directory"
}

variable "nvram_group" {
      type = string
      default = "libvirt"
      description = "Name of the group of the nvram images directory"
}

variable "public_key" {
  type        = string
  description = "Public ssh key for installation"
}

variable "root_passwd" {
  type        = string
  description = "Password for root default is packer"
}

variable "vm_name" {
  type        = string
  default     = "archlinux-2025.08.01-x86_64"
  description = "Name of qcow2 image file to be exported."
}
