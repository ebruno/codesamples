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

resource "google_project" "cur_project" {
  name            = var.project_name
  project_id      = "${var.project_id_prefix}-${random_string.suffix.result}"
  billing_account = data.google_billing_account.acct.id
}

resource "random_string" "suffix" {
  length      = 6
  lower       = false
  min_numeric = 6
  numeric     = true
  special     = false
  upper       = false
}

resource "google_project_service" "apis" {
  for_each = toset(var.enabled_apis)
  project  = google_project.cur_project.project_id
  service  = each.value
}

resource "google_artifact_registry_repository" "demo_repo" {
  location      = var.region
  project       = "${var.project_id_prefix}-${random_string.suffix.result}"
  repository_id = "${var.repository}-${random_string.suffix.result}"
  description   = "Artifact Registry for ${var.project_name}"
  format        = "DOCKER"
  # format = "MAVEN", "NPM", "PYTHON", "UPSTREAM", "YUM", "APT"
  cleanup_policy_dry_run = false
  cleanup_policies {
    id     = "delete-untagged"
    action = "DELETE"
    condition {
      tag_state = "UNTAGGED"
    }
  }
  depends_on = [google_project.cur_project, google_project_service.apis]

}
