packer {
  required_version = ">= 1.14.0"
  required_plugins {
    vmware-iso  = {
      version = "~> 1.2.0"
      source  = "github.com/hashicorp/vmware"
    }
 }
}
source "vmware-iso" "fedora42srv" {
   iso_url = "https://dl.fedoraproject.org/pub/fedora/linux/releases/42/Server/x86_64/iso/Fedora-Server-dvd-x86_64-42-1.1.iso"
   iso_checksum = "sha256:7fee9ac23b932c6a8be36fc1e830e8bba5f83447b0f4c81fe2425620666a7043"
   http_directory = "http/kickstart/files"
   # Account and password need to created in the ks.cfg file.
   ssh_username = "packer"
   ssh_password = "packer"
   ssh_timeout = "10m"
   shutdown_command = "sudo shutdown -h now"
   vnc_port_min = 5901
   vnc_port_max = 5999
   # Any firewalls must allow this port range.
   http_port_min = 8100
   http_port_max = 8400
   vnc_disable_password = true # Must be set to true for remote hypervisor builds with VNC enabled.
   vnc_over_websocket = true # Must be set to true for remote hypervisor builds with VNC enabled.
   insecure_connection = true # This may need to set to true if using autogenrated certs.
   disk_size = 40000
   version = 20
   cpus = 4
   memory = 4096
   vm_name = "${local.artifact_name}"
   guest_os_type = "fedora-64"
   format = "ova"
   iso_target_path = "${var.output_directory}/iso"
   output_directory = "${var.output_directory}"
   network_name = "VM Network"
   network_adapter_type = "vmxnet3"
   boot_wait = "35s"
#   The following are used when using desktop hyperviser"
#   The iso used in the example is intel based, it will not work on Apple Silicon Macs.
#   headless =  true
#   network = "bridged"
#   fusion_app_path = "/Applications/VMware Fusion.app"
   remote_type = "esxi"
   remote_host = "${var.esxi_server}"
   remote_username = "${var.remote_username}"
   remote_password = "${var.remote_password}"
   boot_key_interval = "20ms" # Depending on the environment this value may need to be increased.
   boot_command = [
    "<up>e<wait2><down><down><end> inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg <leftCtrlOn>x<leftCtrloff>"
  ]
}
build {
 sources = ["source.vmware-iso.fedora42srv"]
 provisioner "shell" {
   inline = [
     "sudo dnf update -y",
     "sudo dnf clean all"
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
variable "esxi_server" {
   type      = string
   description = "esxi server."
}
variable "output_directory" {
    type     = string
    default  = "./output-artifacts"
    description = "Output directory for VM artifacts"
}
variable "vm_name" {
   type      = string
   default   = "Fedorasrv42_Demo"
   description = "Virtual Machine name to build"
}
locals {
  current_time = formatdate("YYYYMMDDhhmmss",timestamp())
  artifact_name = "${var.vm_name}-${local.current_time}"
}
