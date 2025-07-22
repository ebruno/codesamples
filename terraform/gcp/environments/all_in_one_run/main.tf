terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_account" "cloud_run_sa" {
  account_id   = "cloud-run-demosrv-${var.cur_env}"
  display_name = "Cloud Run Service Account for Demo Service"
  description  = "Service account for accessing Cloud Run Demo Service functions"
}

resource "google_project_iam_member" "cloud_run_sa_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_project_iam_member" "cloud_run_sa_token_creator" {
  project = var.project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_project_iam_member" "cloud_run_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Create a VPC network
resource "google_compute_network" "vpc_network" {
  name = "${var.vpc_name}-${var.cur_env}"
}

# Create a subnet within the VPC
resource "google_compute_subnetwork" "subnet" {
  name                     = "${var.subnet_name}-${var.cur_env}"
  ip_cidr_range            = var.subnet_ip_cidr_range
  region                   = var.region
  network                  = google_compute_network.vpc_network.id
  private_ip_google_access = true
}

# Enable the vpcaccess.googleapis.com API
resource "google_project_service" "vpcaccess" {
  service            = "vpcaccess.googleapis.com"
  disable_on_destroy = false
}

# Create a Serverless VPC Access connector
resource "google_vpc_access_connector" "connector" {
  name           = "${var.connector_name}-${var.cur_env}"
  network        = google_compute_network.vpc_network.name
  ip_cidr_range  = var.connector_cidr
  min_throughput = 200
  max_throughput = 300
  depends_on     = [google_project_service.vpcaccess, google_compute_subnetwork.subnet]
}

# Enable inbound SSH for test VM's
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.region}-${var.connector_name}-${var.cur_env}-allow-ssh"
  network = "${var.vpc_name}-${var.cur_env}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"] # Internal GCP SSH to VM.
  depends_on    = [google_compute_network.vpc_network]
}

resource "google_cloud_run_v2_service" "default" {
  name     = "sevrbo-json-pretty-service-${var.cur_env}"
  location = var.region
  ingress  = var.service_network_traffic
  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${var.repository}/${var.image_name}:${var.image_tag}_${var.cur_env}"
      ports {
        container_port = 8080
      }
      resources {
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
      }
    }
    vpc_access {
      connector = google_vpc_access_connector.connector.id # Connect to the connector
      egress    = var.service_vcp_traffic                  # "ALL_TRAFFIC" Or "PRIVATE_RANGES_ONLY" to send only traffic to internal IPs through the VPC
    }
    service_account = google_service_account.cloud_run_sa.email
  }
}

resource "google_compute_instance" "vm_instance" {
  count        = var.cur_env != "prod" ? 1 : 0 # Skip creation if environment is dev.
  name         = "prettify-testvm-${var.cur_env}"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }
  network_interface {
    network    = google_compute_network.vpc_network.name
    subnetwork = google_compute_subnetwork.subnet.name
  }
  #depends_on     = [google_compute_network.vpc_network]
}
