variable "app_route" {
  description = "flask app route"
  type        = string
  default     = "/ebprettify"
}

variable "baseurl" {
  description = "Base URL"
  type        = string
  default     = "http://localhost:"
}

variable "external_port" {
  description = "Value of the external port"
  type        = string
  default     = "5001"
}

variable "internal_port" {
  description = "Value of the internal port"
  type        = string
  default     = "8080"
}
