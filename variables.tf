variable "name" {
  description = "Instance name. Lowercase letters, digits and hyphens, 2 to 63 characters, starting with a letter. Cloud SQL reserves a deleted instance name for about a week."
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,61}[a-z0-9]$", var.name))
    error_message = "name must match ^[a-z][a-z0-9-]{0,61}[a-z0-9]$."
  }
}

variable "context" {
  description = "Deployment context used for naming, tagging and environment-dependent defaults."
  type = object({
    organization = string
    environment  = string
    application  = string
    component    = optional(string)
    owner        = string
    cost_center  = string
    extra_tags   = optional(map(string), {})
  })
  validation {
    condition     = contains(["dev", "staging", "prod", "test", "shared"], var.context.environment)
    error_message = "context.environment must be one of dev, staging, prod, test, shared."
  }
}

variable "project_id" {
  description = "Project that hosts the instance."
  type        = string
}

variable "create" {
  description = "Whether to create any resources. Set false to create nothing."
  type        = bool
  default     = true
}

variable "region" {
  description = "Region of the instance."
  type        = string
}

variable "engine" {
  description = "Database engine: postgres or mysql."
  type        = string
  default     = "postgres"
  validation {
    condition     = contains(["postgres", "mysql"], var.engine)
    error_message = "engine must be one of postgres, mysql."
  }
}

variable "database_version" {
  description = "Cloud SQL database version, for example POSTGRES_16 or MYSQL_8_0. Must start with the prefix of the chosen engine."
  type        = string
  default     = "POSTGRES_16"
}

variable "tier" {
  description = "Machine tier of the instance."
  type        = string
  default     = "db-custom-2-7680"
}

variable "network_self_link" {
  description = "Self link of the VPC network the instance gets its private IP in. The network needs private service access configured."
  type        = string
}

variable "databases" {
  description = "Names of the databases to create on the instance."
  type        = list(string)
  default     = []
}

variable "users" {
  description = "Database users keyed by user name. With password_secret_id null a password is generated and stored in a new Secret Manager secret named <name>-<user>-password. With password_secret_id set, the latest version of that existing secret (a secret id or resource name) is read and used as the password."
  type = map(object({
    password_secret_id = optional(string)
  }))
  default = {}
}

variable "high_availability" {
  description = "Regional (HA) availability. Null resolves to true when context.environment is prod and false otherwise."
  type        = bool
  default     = null
}

variable "backup" {
  description = "Automated backup settings. retained is a count of backups; pitr enables point-in-time recovery (binary logging on mysql)."
  type = object({
    enabled  = optional(bool, true)
    retained = optional(number, 14)
    pitr     = optional(bool, true)
  })
  default = {}
  validation {
    condition     = var.backup.retained >= 1 && var.backup.retained <= 365
    error_message = "backup.retained must be between 1 and 365."
  }
}

variable "maintenance_window" {
  description = "Maintenance window: day of week (1 = Monday to 7 = Sunday) and hour of day (0 to 23, UTC)."
  type = object({
    day  = number
    hour = number
  })
  default = { day = 7, hour = 3 }
  validation {
    condition     = var.maintenance_window.day >= 1 && var.maintenance_window.day <= 7 && var.maintenance_window.hour >= 0 && var.maintenance_window.hour <= 23
    error_message = "maintenance_window.day must be 1 to 7 and maintenance_window.hour 0 to 23."
  }
}

variable "flags" {
  description = "Database flags applied to the instance, as name to value."
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "Labels merged onto every labelable resource, applied last. Keys must already be valid GCP label keys."
  type        = map(string)
  default     = {}
}
