terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
}

data "google_projects" "all_projects" {
  # Optional: filter projects by name, labels, etc.
  # For example, to filter by a specific label:
  filter = "id:${var.project_filter} lifecycleState:ACTIVE"
}
