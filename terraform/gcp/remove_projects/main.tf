terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  region = var.region
}

data "google_billing_account" "acct" {
  display_name = var.billing_account_name
  open         = true
}

data "google_projects" "all_projects" {
  # Optional: filter projects by name, labels, etc.
  # For example, to filter by a specific label:
  filter = "id:ebdemo-cldrun* lifecycleState:ACTIVE"
}
