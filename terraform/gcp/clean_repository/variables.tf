variable "billing_account_name" {
  description = "Billing account to use for the project"
  type        = string
  default     = "My Billing Account"
}

variable "enabled_apis" {
  type = list(string)
  default = [
    "artifactregistry.googleapis.com",
    "compute.googleapis.com",
    "iamcredentials.googleapis.com",
    "iap.googleapis.com",
    "run.googleapis.com",
    "storage.googleapis.com"
  ]
}

variable "project_id_prefix" {
  description = "GCP Project ID"
  type        = string
  default     = "ebdemo-cldrun-srv"
}

variable "project_name" {
  description = "GCP Project Name"
  type        = string
  default     = "Demo Cloudrun Service"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-west4"
}

variable "repository_id" {
  description = "Aritifact Registry Repository ID"
  type        = string
}
