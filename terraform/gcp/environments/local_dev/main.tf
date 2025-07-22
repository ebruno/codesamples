terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

provider "docker" {}

resource "docker_image" "ebprettify_app_image" {
  name = "python:3.13-slim-bookworm"
  build {
    context = "../../eb_prettyjson"
  }
  keep_locally = false
}

# Create the Docker container
resource "docker_container" "ebprettify_container" {
  name  = "ebprettify-container"                 # Container name
  image = docker_image.ebprettify_app_image.name # Use the image built above
  # On MacOs Monterey and later Port 5000 is used by systems process
  # on Sequoia it is used by Console Control
  # Console Control
  # ControlCe 658    10u  IPv4 TCP *:commplex-main (LISTEN)
  # ControlCe 658    11u  IPv6 TCP *:commplex-main (LISTEN)
  ports {
    internal = var.internal_port # Internal port Flask runs on
    external = var.external_port # External port to access the app
  }
  env = [
    "PORT=${var.internal_port}"
  ]
}
