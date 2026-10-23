terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.22, < 8.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 7.22, < 8.0"
    }
  }
}

variable "project_id" {
  description = "Project that hosts the instance."
  type        = string
}

variable "network_self_link" {
  description = "Self link of a VPC network with private service access configured."
  type        = string
}

module "this" {
  source = "../../"

  name       = "example"
  project_id = var.project_id
  region     = "europe-west1"
  context = {
    organization = "olensys"
    environment  = "test"
    application  = "example"
    owner        = "platform"
    cost_center  = "eng"
  }

  network_self_link = var.network_self_link
  databases         = ["app"]
  users             = { app = {} }
}

output "connection_name" {
  description = "Connection name of the instance."
  value       = module.this.connection_name
}

output "password_secret_id" {
  description = "Secret holding the generated app password."
  value       = module.this.user_password_secret_ids["app"]
}

output "ip_configuration" {
  description = "Applied ip_configuration of the instance."
  value       = module.this.applied_ip_configuration
}
