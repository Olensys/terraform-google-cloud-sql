output "id" {
  description = "Identifier of the instance (its name). Null when create is false."
  value       = local.instance_name
}

output "name" {
  description = "Name of the instance. Null when create is false."
  value       = local.instance_name
}

output "self_link" {
  description = "Self link of the instance. Null when create is false."
  value       = local.self_link
}

output "connection_name" {
  description = "Connection name (project:region:instance) for the Cloud SQL Auth Proxy and connectors. Null when create is false."
  value       = local.connection_name

  precondition {
    condition     = !var.create || startswith(var.database_version, local.is_postgres ? "POSTGRES_" : "MYSQL_")
    error_message = "database_version must start with POSTGRES_ for engine postgres and MYSQL_ for engine mysql."
  }

  precondition {
    condition     = !var.create || !local.is_mysql || var.backup.retained > local.txlog_days
    error_message = "On mysql, backup.retained must be greater than the 7-day transaction log retention."
  }

  precondition {
    condition     = !var.create || !local.is_postgres || !local.high_availability || (var.backup.enabled && var.backup.pitr)
    error_message = "A regional (high availability) postgres instance requires backup.enabled and backup.pitr."
  }
}

output "private_ip" {
  description = "Private IP address of the instance. Null when create is false."
  value       = local.private_ip
}

output "user_password_secret_ids" {
  description = "Map of user name to the id of the Secret Manager secret holding its generated password. Users with password_secret_id are not listed. Null when create is false."
  value       = var.create ? { for k, s in google_secret_manager_secret.user : k => s.id } : null
}

output "labels" {
  description = "Labels applied to every labelable resource, with context.extra_tags merged in. Null when create is false."
  value       = var.create ? local.labels : null
}

output "ip_configuration" {
  description = "ip_configuration passed to the upstream module: private IP only, TLS enforced. Null when create is false."
  value       = var.create ? local.ip_configuration : null
}

output "availability_type" {
  description = "Availability type passed to the upstream module: REGIONAL or ZONAL. Null when create is false."
  value       = var.create ? local.availability_type : null
}

output "applied_ip_configuration" {
  description = "ip_configuration of the created instance as reported by the provider (ipv4_enabled, ssl_mode, private_network). Null when create is false."
  value       = local.applied_ip_configuration
}

output "edition" {
  description = "Cloud SQL edition passed to the upstream module. Null when create is false."
  value       = var.create ? local.edition : null
}
