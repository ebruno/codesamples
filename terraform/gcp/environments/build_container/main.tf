terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.6.2"
    }
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

resource "null_resource" "auth_docker" {
  provisioner "local-exec" {
    command = "gcloud auth configure-docker ${var.region}-docker.pkg.dev"
  }
}

resource "null_resource" "build_image" {
  triggers = {
    # Ensure Dockerfile is updated before building.
    dockerfile_sha = sha1(file("../../eb_prettyjson/Dockerfile"))
  }
  provisioner "local-exec" {
    command = "docker build -t ${var.image_name}:${var.image_tag} -t ${var.region}-docker.pkg.dev/${var.project_id}/${var.repository_id}/${var.image_name}:${var.image_tag}_${var.cur_env}  ../../eb_prettyjson"
  }
}

resource "null_resource" "push_image" {
  depends_on = [null_resource.auth_docker, null_resource.build_image]
  provisioner "local-exec" {
    command = "docker push ${var.region}-docker.pkg.dev/${var.project_id}/${var.repository_id}/${var.image_name}:${var.image_tag}_${var.cur_env}"
  }
}

resource "null_resource" "current_images" {
  provisioner "local-exec" {
    command = "docker rmi ${var.image_name}:${var.image_tag} ${var.region}-docker.pkg.dev/${var.project_id}/${var.repository_id}/${var.image_name}:${var.image_tag}_${var.cur_env}"
  }
  depends_on = [null_resource.push_image]
}
