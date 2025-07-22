output "project_id" {
  value       = google_project.cur_project.project_id
  description = "The ID of the created Google Cloud project."
}

output "project_info" {
  value = "${google_project.cur_project.name}:${google_project.cur_project.id}:${google_project.cur_project.number}"
}

output "repository_id" {
  value       = google_artifact_registry_repository.demo_repo.repository_id
  description = "Project Repository ID"
}
