output "project_info" {
  value = [for project in data.google_projects.all_projects.projects : {
    lifecyle_state = project.lifecycle_state
    name           = project.name
    project        = project.project_id
    }
  ]
}

