#
# This template assumes that
# the following environment variables are defined.
# AWS_ACCESS_KEY_ID: Set the value to your AWS access key ID.
# AWS_SECRET_ACCESS_KEY: Set the value to your AWS secret access key.
#
packer {
  required_version = ">= 1.14.0"
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1.5.0"
    }
  }
}
variable "ami_id" {
  type    = string
  default = "ami-00271c85bf8a52b84"
}

variable "ami_name_prefix" {
  type = string
  default = "PACKER-DEMO"
}
variable "AWS_ACCESS_KEY_ID" {
  type        = string
  default     = env("AWS_ACCESS_KEY_ID")
  description = "This variable expects the value from the AWS_ACCESS_KEY_ID environment variable."

  validation {
    condition     = length(var.AWS_ACCESS_KEY_ID) > 0
    error_message = <<EOF
The 'AWS_ACCESS_KEY_ID' environment variable is not set or is empty.
Please set this environment variable before running Packer.
EOF
  }
}

variable "AWS_SECRET_ACCESS_KEY" {
  type        = string
  default     = env("AWS_SECRET_ACCESS_KEY")
  description = "This variable expects the value from the AWS_SECRET_ACCESS_KEY environment variable."

  validation {
    condition     = length(var.AWS_SECRET_ACCESS_KEY) > 0
    error_message = <<EOF
The 'AWS_SECRET_ACCESS_KEY' environment variable is not set or is empty.
Please set this environment variable before running Packer.
EOF
  }
}

locals {
  current_time = formatdate("YYYYMMDDhhmmss",timestamp())
  ami_name = "PACKER-DEMO-${local.app_name}-${local.current_time}"
}
variable "app_name" {
  type    = string
  default = "build_machine"
}

locals {
    app_name = "build_machine"
}

source "amazon-ebs" "build_machine" {
  ami_name      = "${local.ami_name}"
  instance_type = "t3.large"
  region        = "us-west-1"
  source_ami    = "${var.ami_id}"
  ssh_username  = "ubuntu"
  tags = {
    Env  = "build_enviroments"
    Name = "${local.ami_name}"
  }
}

build {
  sources = ["source.amazon-ebs.build_machine"]

  provisioner "shell" {
    script = "script/provision.sh"
  }

  post-processor "shell-local" {
    inline = ["echo ${local.ami_name} is now available."]
  }
}
