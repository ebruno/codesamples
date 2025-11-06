packer {
  required_version = ">= 1.14.0"
  required_plugins {
    vsphere-iso  = {
      version = "~> 1.2.7"
      source  = "github.com/hashicorp/vsphere"
    }
 }
}
source "vsphere-iso" "fedora42srv" {
   iso_url = "https://dl.fedoraproject.org/pub/fedora/linux/releases/42/Server/x86_64/iso/Fedora-Server-dvd-x86_64-42-1.1.iso"
   iso_checksum = "sha256:7fee9ac23b932c6a8be36fc1e830e8bba5f83447b0f4c81fe2425620666a7043"
   http_directory = "http/kickstart/files"
   ssh_username = "packer"
   ssh_password = "packer"
   ip_wait_timeout = "10m"
   ip_settle_timeout = "1m"
   vcenter_server = "${var.vcenter_server}"
   host = "${var.esxi_server}"
   username = "${var.remote_username}"
   password = "${var.remote_password}"
   datacenter = "${var.datacenter}"
   # Any firewalls must allow this port range.
   http_port_min = 8100
   http_port_max = 8400
   shutdown_command = "sudo shutdown -h now"
   insecure_connection = true   # This may need to set to true if using autogenrated certs.
   storage {
      disk_size = 40000
      disk_thin_provisioned = true
   }
   vm_name = "${var.vm_name}"
   vm_version = 20
   CPUs = 4
   RAM = 4096
# fedora64Guest Red Hat Fedora (64-bit)
# fedoraGuest   Red Hat Fedora (32-bit)
   guest_os_type = "fedora64Guest"
   convert_to_template = var.convert_to_template
   export {
      force = true
      output_directory = "./output-artifacts"
      image_files = true
   }
   network_adapters {
      network = "VM Network"
      network_card = "vmxnet3"
   }
   boot_wait = "35s"
   boot_command = [
    "<up>e<wait2><down><down><end> inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg <leftCtrlOn>x<leftCtrloff>"
  ]
}
build {
 sources = ["source.vsphere-iso.fedora42srv"]
 provisioner "shell" {
   inline = [
     "sudo dnf update -y",
     "sudo dnf clean all"
   ]
 }
 post-processor "shell-local" {
    inline = [
       "ovftool \"${var.output_directory}/${var.vm_name}.ovf\" \"${var.output_directory}/${local.artifact_name}\"",
    ]
 }
}
variable "remote_username" {
   type      = string
   description = "User name for login."
}
variable "remote_password" {
   type      = string
   description = "User password for login."
}
variable "convert_to_template" {
    type = bool
    default = true
    description = "Convert the virtual machine to a template after the build is complete. If set to true, the virtual machine can not be imported into a content library."
}
variable "datacenter" {
   type      = string
   description = "Remote esxi server."
}
variable "esxi_server" {
   type      = string
   description = "esxi server."
}
variable "output_directory" {
    type     = string
    default  = "./output-artifacts"
    description = "Output directory for VM artifacts"
}
variable "vcenter_server" {
   type      = string
   description = "vCenter server."
}
variable "vm_name" {
   type      = string
   default   = "Fedorasrv42_Demo"
   description = "Virtual Machine name to build"
}
locals {
  current_time = formatdate("YYYYMMDDhhmmss",timestamp())
  artifact_name = "${var.vm_name}-${local.current_time}.ova"
}
