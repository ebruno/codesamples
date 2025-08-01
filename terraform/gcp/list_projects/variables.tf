variable "filter" {
  description = "Project Filter"
  type        = string
  default     = "*"
}

variable "lifecycle_state" {
  description = "Project lifecyle state"
  type        = string
  validation {
    condition     = contains(["ACTIVE", "DELETE_REQUESTED", "*"], var.lifecycle_state)
    error_message = "Current Environment must be one 'ACTIVE','DELETE_REQUESTED' or '*'."
  }
  default = "*"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-west4"
}
