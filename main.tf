locals {
  labels = merge(var.context.extra_tags, var.labels)

  is_postgres = var.engine == "postgres"
  is_mysql    = var.engine == "mysql"

  high_availability   = coalesce(var.high_availability, var.context.environment == "prod")
  availability_type   = local.high_availability ? "REGIONAL" : "ZONAL"
  deletion_protection = var.context.environment == "prod"

  ip_configuration = {
    ipv4_enabled       = false
    private_network    = var.network_self_link
    ssl_mode           = "ENCRYPTED_ONLY"
    allocated_ip_range = null
  }

  insights_config = {
    enhanced_query_insights_enabled = false
    query_plans_per_minute          = 5
    query_string_length             = 1024
    record_application_tags         = false
    record_client_address           = false
  }

  backup_start_time = "03:00"
  txlog_days        = 7

  # Postgres audit logging defaults; var.flags wins on conflict.
  postgres_default_flags = {
    log_checkpoints    = "on"
    log_connections    = "on"
    log_disconnections = "on"
    log_lock_waits     = "on"
    log_temp_files     = "0"
  }

  database_flags          = [for k, v in var.flags : { name = k, value = v }]
  postgres_database_flags = [for k, v in merge(local.postgres_default_flags, var.flags) : { name = k, value = v }]

  additional_databases = [for d in var.databases : { name = d, charset = null, collation = null }]

  generated_users = { for k, u in var.users : k => u if u.password_secret_id == null }
  supplied_users  = { for k, u in var.users : k => u if u.password_secret_id != null }

  passwords = merge(
    { for k, p in random_password.user : k => p.result },
    { for k, s in data.google_secret_manager_secret_version.user : k => s.secret_data },
  )

  postgres_users = [for k in keys(local.passwords) : { name = k, password = local.passwords[k], random_password = false }]
  mysql_users    = [for k in keys(local.passwords) : { name = k, password = local.passwords[k], random_password = false, type = "BUILT_IN", host = "%" }]

  instance_name   = var.create ? (local.is_postgres ? module.postgres[0].instance_name : module.mysql[0].instance_name) : null
  self_link       = var.create ? (local.is_postgres ? module.postgres[0].instance_self_link : module.mysql[0].instance_self_link) : null
  connection_name = var.create ? (local.is_postgres ? module.postgres[0].instance_connection_name : module.mysql[0].instance_connection_name) : null
  applied_ip_configuration = var.create ? try(
    local.is_postgres ? module.postgres[0].primary.settings[0].ip_configuration[0] : module.mysql[0].primary.settings[0].ip_configuration[0],
    null,
  ) : null
  private_ip = var.create ? (local.is_postgres ? module.postgres[0].private_ip_address : module.mysql[0].private_ip_address) : null
}

resource "random_password" "user" {
  for_each = var.create ? local.generated_users : {}

  length  = 32
  special = false
}

resource "google_secret_manager_secret" "user" {
  for_each = var.create ? local.generated_users : {}

  project   = var.project_id
  secret_id = "${var.name}-${each.key}-password"
  labels    = local.labels

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "user" {
  for_each = var.create ? local.generated_users : {}

  secret      = google_secret_manager_secret.user[each.key].id
  secret_data = random_password.user[each.key].result
}

data "google_secret_manager_secret_version" "user" {
  for_each = var.create ? local.supplied_users : {}

  secret  = each.value.password_secret_id
  version = "latest"
}

# trivy:ignore:AVD-GCP-0014
# trivy:ignore:AVD-GCP-0015
# trivy:ignore:AVD-GCP-0016
# trivy:ignore:AVD-GCP-0017
# trivy:ignore:AVD-GCP-0020
# trivy:ignore:AVD-GCP-0022
# trivy:ignore:AVD-GCP-0025
module "postgres" {
  source  = "terraform-google-modules/sql-db/google//modules/postgresql"
  version = "28.3.0"

  count = var.create && local.is_postgres ? 1 : 0

  project_id        = var.project_id
  name              = var.name
  region            = var.region
  database_version  = var.database_version
  edition           = "ENTERPRISE"
  tier              = var.tier
  availability_type = local.availability_type

  random_instance_name        = false
  enable_default_db           = false
  enable_default_user         = false
  deletion_protection         = local.deletion_protection
  deletion_protection_enabled = local.deletion_protection

  ip_configuration = local.ip_configuration
  insights_config  = local.insights_config

  backup_configuration = {
    enabled                        = var.backup.enabled
    point_in_time_recovery_enabled = var.backup.enabled && var.backup.pitr
    retained_backups               = var.backup.retained
    retention_unit                 = "COUNT"
    start_time                     = local.backup_start_time
    transaction_log_retention_days = tostring(local.txlog_days)
  }

  maintenance_window_day          = var.maintenance_window.day
  maintenance_window_hour         = var.maintenance_window.hour
  maintenance_window_update_track = "stable"

  database_flags       = local.postgres_database_flags
  additional_databases = local.additional_databases
  additional_users     = local.postgres_users

  user_labels = local.labels
}

# trivy:ignore:AVD-GCP-0014
# trivy:ignore:AVD-GCP-0015
# trivy:ignore:AVD-GCP-0016
# trivy:ignore:AVD-GCP-0017
# trivy:ignore:AVD-GCP-0020
# trivy:ignore:AVD-GCP-0022
# trivy:ignore:AVD-GCP-0025
module "mysql" {
  source  = "terraform-google-modules/sql-db/google//modules/mysql"
  version = "28.3.0"

  count = var.create && local.is_mysql ? 1 : 0

  project_id        = var.project_id
  name              = var.name
  region            = var.region
  database_version  = var.database_version
  tier              = var.tier
  availability_type = local.availability_type

  random_instance_name        = false
  enable_default_db           = false
  enable_default_user         = false
  deletion_protection         = local.deletion_protection
  deletion_protection_enabled = local.deletion_protection

  ip_configuration = local.ip_configuration
  insights_config  = local.insights_config

  backup_configuration = {
    enabled                        = var.backup.enabled
    binary_log_enabled             = var.backup.enabled && var.backup.pitr
    retained_backups               = var.backup.retained
    retention_unit                 = "COUNT"
    start_time                     = local.backup_start_time
    transaction_log_retention_days = tostring(local.txlog_days)
  }

  maintenance_window_day          = var.maintenance_window.day
  maintenance_window_hour         = var.maintenance_window.hour
  maintenance_window_update_track = "stable"

  database_flags       = local.database_flags
  additional_databases = local.additional_databases
  additional_users     = local.mysql_users

  user_labels = local.labels
}
