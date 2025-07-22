output "cloud_run_service_account" {
  value       = google_cloud_run_v2_service.default.template[0].service_account
  description = "The URL of the deployed Cloud Run service account"
}

#output "cloud_run_service_account_all" {
#  value       = google_cloud_run_v2_service.default
#  description = "The URL of the deployed Cloud Run service account"
#}
#output "cloud_run_service_all" {
#  value       = google_cloud_run_v2_service.default
#  description = "The URL of the deployed Cloud Run service"
#}
output "cloud_run_service_url" {
  value       = google_cloud_run_v2_service.default.uri
  description = "The URL of the deployed Cloud Run service"
}

output "connector_name" {
  value = google_vpc_access_connector.connector.name
}

output "sample_getting_the_access_token" {
  value = <<-EOT
Generate a JSON Key:

    In the Google Cloud console, go to the "Service accounts" page.
    Select the service account you want to create a key for.
    Go to the "Keys" tab.
    Click "Add key" and select "Create new key".
    Choose "JSON" as the key type and click "Create".
    A JSON file will be downloaded to your computer.

export ACCESS_TOKEN=$(gcloud auth print-identity-token --impersonate-service-account=${google_cloud_run_v2_service.default.template[0].service_account}   --audiences=${google_cloud_run_v2_service.default.uri}")
  EOT
}

output "sample_query_using_curl" {
  value = <<-EOT
curl -H "Authorization: Bearer $ACCESS_TOKEN" \
-H 'Content-Type: application/json'  \
-d '{"xxx": 5, "yyy":"four"}' \
-X POST \
${google_cloud_run_v2_service.default.uri}/ebprettify

  EOT
}

output "subnet_name" {
  value = google_compute_subnetwork.subnet.name
}

output "vm_internal_ip" {
  value = var.cur_env != "prod" ? "${google_compute_instance.vm_instance[0].network_interface.0.network_ip}" : null
}

output "vm_name" {
  value = var.cur_env != "prod" ? "${google_compute_instance.vm_instance[0].name}" : null
}

output "vm_zone" {
  value = var.cur_env != "prod" ? "${google_compute_instance.vm_instance[0].zone}" : null
}

# Output the connector name and VPC details
output "vpc_name" {
  value = google_compute_network.vpc_network.name
}
