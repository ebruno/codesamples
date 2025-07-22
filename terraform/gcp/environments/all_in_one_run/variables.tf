variable "connector_cidr" {
  type        = string
  description = "Connection IP Address range"
  default     = "10.8.0.0/28"
}

variable "connector_name" {
  # connector name has a limit so need to use short prefix.
  type        = string
  description = "Name of the VPC connector"
  default     = "svrbo-clrun-conn"
}

variable "cur_env" {
  description = "Current Environment one of prod,qa,dev"
  type        = string
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
  default     = "demo-cloudrun-service-43134"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-west4"
}

variable "repository" {
  description = "Aritifact Registry Repository"
  type        = string
  default     = "demo-service"
}

variable "service_network_traffic" {
  type        = string
  description = "INGRESS_TRAFFIC_INTERNAL_ONLY" # or INGRESS_TRAFFIC_ALL", INGRESS_TRAFFIC_INTERNAL_AND_LOAD_BALANCER"
  default     = "INGRESS_TRAFFIC_INTERNAL_ONLY"
}

variable "service_vcp_traffic" {
  type        = string
  description = " ALL_TRAFFIC Or PRIVATE_RANGES_ONLY to send only traffic to internal IPs through the VPC"
  default     = "PRIVATE_RANGES_ONLY"
}

variable "subnet_ip_cidr_range" {
  type        = string
  description = "CIDR range for the subnet"
  default     = "10.10.10.0/24"
}

variable "subnet_name" {
  type        = string
  description = "Name of the subnet"
  default     = "svrbo-clrun-subnet"
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC network"
  default     = "svrbo-clrun-vpc"
}

variable "zone" {
  description = "zone to deploy instance"
  type        = string
  default     = "us-west4-a"
}
