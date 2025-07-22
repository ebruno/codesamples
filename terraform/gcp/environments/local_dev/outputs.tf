output "container_id" {
  description = "ID of the Docker container"
  value       = docker_container.ebprettify_container.id
}

output "image_id" {
  description = "ID of the Docker image"
  value       = docker_image.ebprettify_app_image.id
}

output "localurl" {
  description = "Local URL to access service."
  value       = "${var.baseurl}${var.external_port}"
}

output "sample_query" {
  description = "Sample curl query"
  value       = <<EOT
    "curl -H 'Content-Type: application/json' -X POST -d '{"id":5,"name":"fred"}' ${var.baseurl}${var.external_port}${var.app_route}"
  EOT
}
