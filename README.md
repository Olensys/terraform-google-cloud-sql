# terraform-google-cloud-sql

Cloud SQL instance with private IP only, enforced TLS, backups with PITR, HA in prod and generated passwords stored in Secret Manager

## Opinions

- Engine is `postgres` or `mysql`; the matching upstream submodule is used. `database_version` must carry the engine prefix (`POSTGRES_` or `MYSQL_`), checked as a precondition on `connection_name`.
- Private IP only: `ipv4_enabled = false`, no authorised networks, attached to `network_self_link` (which needs private service access).
- TLS enforced: `ssl_mode = ENCRYPTED_ONLY`.
- Query insights on, without application tags or client addresses.
- Backups on by default, 14 retained, point-in-time recovery on (binary logging on mysql), started at 03:00 with 7 days of transaction logs. On mysql `backup.retained` must exceed 7.
- High availability (`REGIONAL`) defaults to on when `context.environment` is `prod`, otherwise `ZONAL`; `high_availability` overrides.
- `deletion_protection` and the instance-level `deletion_protection_enabled` are on in prod only.
- Postgres sets `log_checkpoints`, `log_connections`, `log_disconnections`, `log_lock_waits` to `on` and `log_temp_files` to `0`; entries in `flags` override them. The upstream module also pulls in the `google-beta` provider.
- Maintenance on the `stable` track, default Sunday 03:00 UTC.
- No default database or default user is created. Databases come from `databases`, users from `users`.
- Passwords: a user without `password_secret_id` gets a 32-character generated password stored in a new secret named `<name>-<user>-password` (ids in `user_password_secret_ids`). A user with `password_secret_id` has the latest version of that existing secret read and used; the caller must grant the identity running Terraform access to it. Passwords are held in Terraform state, so protect the state.
- Instance names are reserved by Cloud SQL for about a week after deletion; reuse of a name right after destroy fails.

## Usage

```hcl
module "this" {
  source = "git::https://github.com/Olensys/terraform-google-cloud-sql.git?ref=v1.0.0"

  name       = "example"
  project_id = "my-project"
  region     = "europe-west1"
  context = {
    organization = "olensys"
    environment  = "dev"
    application  = "example"
    owner        = "platform"
    cost_center  = "eng"
  }

  network_self_link = "projects/my-project/global/networks/main"
  databases         = ["app"]
  users             = { app = {} }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.0, < 8.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.5, < 4.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.0, < 8.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.5, < 4.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_mysql"></a> [mysql](#module\_mysql) | terraform-google-modules/sql-db/google//modules/mysql | 28.3.0 |
| <a name="module_postgres"></a> [postgres](#module\_postgres) | terraform-google-modules/sql-db/google//modules/postgresql | 28.3.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [google_secret_manager_secret.user](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_secret_manager_secret_version.user](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_version) | resource |
| [random_password.user](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [google_secret_manager_secret_version.user](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/secret_manager_secret_version) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_context"></a> [context](#input\_context) | Deployment context used for naming, tagging and environment-dependent defaults. | <pre>object({<br/>    organization = string<br/>    environment  = string<br/>    application  = string<br/>    component    = optional(string)<br/>    owner        = string<br/>    cost_center  = string<br/>    extra_tags   = optional(map(string), {})<br/>  })</pre> | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Instance name. Lowercase letters, digits and hyphens, 2 to 63 characters, starting with a letter. Cloud SQL reserves a deleted instance name for about a week. | `string` | n/a | yes |
| <a name="input_network_self_link"></a> [network\_self\_link](#input\_network\_self\_link) | Self link of the VPC network the instance gets its private IP in. The network needs private service access configured. | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Project that hosts the instance. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Region of the instance. | `string` | n/a | yes |
| <a name="input_backup"></a> [backup](#input\_backup) | Automated backup settings. retained is a count of backups; pitr enables point-in-time recovery (binary logging on mysql). | <pre>object({<br/>    enabled  = optional(bool, true)<br/>    retained = optional(number, 14)<br/>    pitr     = optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_create"></a> [create](#input\_create) | Whether to create any resources. Set false to create nothing. | `bool` | `true` | no |
| <a name="input_database_version"></a> [database\_version](#input\_database\_version) | Cloud SQL database version, for example POSTGRES\_16 or MYSQL\_8\_0. Must start with the prefix of the chosen engine. | `string` | `"POSTGRES_16"` | no |
| <a name="input_databases"></a> [databases](#input\_databases) | Names of the databases to create on the instance. | `list(string)` | `[]` | no |
| <a name="input_engine"></a> [engine](#input\_engine) | Database engine: postgres or mysql. | `string` | `"postgres"` | no |
| <a name="input_flags"></a> [flags](#input\_flags) | Database flags applied to the instance, as name to value. | `map(string)` | `{}` | no |
| <a name="input_high_availability"></a> [high\_availability](#input\_high\_availability) | Regional (HA) availability. Null resolves to true when context.environment is prod and false otherwise. | `bool` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels merged onto every labelable resource, applied last. Keys must already be valid GCP label keys. | `map(string)` | `{}` | no |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | Maintenance window: day of week (1 = Monday to 7 = Sunday) and hour of day (0 to 23, UTC). | <pre>object({<br/>    day  = number<br/>    hour = number<br/>  })</pre> | <pre>{<br/>  "day": 7,<br/>  "hour": 3<br/>}</pre> | no |
| <a name="input_tier"></a> [tier](#input\_tier) | Machine tier of the instance. | `string` | `"db-custom-2-7680"` | no |
| <a name="input_users"></a> [users](#input\_users) | Database users keyed by user name. With password\_secret\_id null a password is generated and stored in a new Secret Manager secret named <name>-<user>-password. With password\_secret\_id set, the latest version of that existing secret (a secret id or resource name) is read and used as the password. | <pre>map(object({<br/>    password_secret_id = optional(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_availability_type"></a> [availability\_type](#output\_availability\_type) | Availability type passed to the upstream module: REGIONAL or ZONAL. Null when create is false. |
| <a name="output_connection_name"></a> [connection\_name](#output\_connection\_name) | Connection name (project:region:instance) for the Cloud SQL Auth Proxy and connectors. Null when create is false. |
| <a name="output_id"></a> [id](#output\_id) | Identifier of the instance (its name). Null when create is false. |
| <a name="output_ip_configuration"></a> [ip\_configuration](#output\_ip\_configuration) | ip\_configuration passed to the upstream module: private IP only, TLS enforced. Null when create is false. |
| <a name="output_labels"></a> [labels](#output\_labels) | Labels applied to every labelable resource, with context.extra\_tags merged in. Null when create is false. |
| <a name="output_name"></a> [name](#output\_name) | Name of the instance. Null when create is false. |
| <a name="output_private_ip"></a> [private\_ip](#output\_private\_ip) | Private IP address of the instance. Null when create is false. |
| <a name="output_self_link"></a> [self\_link](#output\_self\_link) | Self link of the instance. Null when create is false. |
| <a name="output_user_password_secret_ids"></a> [user\_password\_secret\_ids](#output\_user\_password\_secret\_ids) | Map of user name to the id of the Secret Manager secret holding its generated password. Users with password\_secret\_id are not listed. Null when create is false. |
<!-- END_TF_DOCS -->
