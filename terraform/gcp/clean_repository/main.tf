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
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

data "google_projects" "all_projects" {
  # Optional: filter projects by name, labels, etc.
  # For example, to filter by a specific label:
  filter = "id:ebdemo-cldrun* lifecycleState:ACTIVE"
}

resource "random_id" "temp_filename" {
  byte_length = 8 # Generates a 16-character hexadecimal string
}

resource "local_file" "temp_file" {
  content  = "This is some temporary content.\n"
  filename = "${path.module}/tmp/${random_id.temp_filename.hex}.txt" 
  # Creates a file in a 'tmp' subdirectory within your module,
  # using the random ID for uniqueness.
}


resource "null_resource" "list_images" {
  provisioner "local-exec" {
    command = "gcloud artifacts docker tags list ${var.region}-docker.pkg.dev/${var.project_id}/${var.repository_id} > ${local_file.temp_file.filename}"
  }
  depends_on = [local_file.temp_file]
}

data "local_file" "command_result" {
  filename = local_file.temp_file.filename
  depends_on = [null_resource.list_images] # Ensures the file is created before reading
}

locals {
   lines = split("\n",data.local_file.command_result.content)
   depends_on = [null_resource.list_images] # Ensures the file is created before reading   
}

resource "null_resource" "line_processor" {
  for_each = toset(local.lines)
  triggers = {
    processed_line = each.value
  }
   depends_on = [null_resource.list_images] # Ensures the file is created before reading   
}
output "processed_lines" {
  value = [
    for line in local.lines :
    "Processed: ${line}"
  ]
}
output "file_name" {
 value = local_file.temp_file.filename
}


# gcloud artifacts docker tags list ${var.region}-docker.pkg.dev/${var.project_id}/${var.repository_id}/