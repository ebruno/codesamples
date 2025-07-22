locals {
  image_url = "${var.region}-docker.pkg.dev/${var.project_id}/${var.repository_id}/${var.image_name}"
}

variable "cur_env" {
  description = "Current Environment"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "qa", "prod"], var.cur_env)
    error_message = "Current Environment must be one 'prod', 'qa' or 'dev'."
  }
}

variable "image_name" {
  description = "Image name"
  type        = string
  default     = "demo_srv_jp_eb"
}

variable "image_tag" {
  description = "Image tag"
  type        = string
  default     = "latest"
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-west4"
}

variable "repository_id" {
  description = "Aritifact Registry Repository"
  type        = string
}
