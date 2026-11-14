mock_provider "google-beta" {
  mock_data "google_compute_zones" {
    defaults = {
      names = ["europe-west1-b", "europe-west1-c", "europe-west1-d"]
    }
  }
}

mock_provider "google" {
  mock_data "google_compute_zones" {
    defaults = {
      names = ["europe-west1-b", "europe-west1-c", "europe-west1-d"]
    }
  }
}
mock_provider "random" {}

variables {
  context = {
    organization = "olensys"
    environment  = "test"
    application  = "example"
    owner        = "platform"
    cost_center  = "eng"
  }
  name              = "example"
  project_id        = "example-project"
  region            = "europe-west1"
  network_self_link = "projects/example-project/global/networks/main"
  databases         = ["app"]
  users             = { app = {} }
}

run "test_private_ip_only" {
  command = plan

  # SMOKE: asserts the ip_configuration this wrapper hands to the upstream module; it does not observe the created instance (complete.tftest.hcl asserts the applied ip_configuration in the nightly run).
  assert {
    condition     = output.ip_configuration.ipv4_enabled == false && output.ip_configuration.private_network == var.network_self_link
    error_message = "ipv4 must be disabled and the private network set."
  }
}

run "test_ssl_required" {
  command = plan

  # SMOKE: asserts the ssl_mode passed to the upstream module; it does not observe the created instance (complete.tftest.hcl asserts the applied ssl_mode in the nightly run).
  assert {
    condition     = output.ip_configuration.ssl_mode == "ENCRYPTED_ONLY"
    error_message = "ssl_mode must be ENCRYPTED_ONLY."
  }
}

run "test_ha_default_in_prod" {
  command = plan

  variables {
    context = {
      organization = "olensys"
      environment  = "prod"
      application  = "example"
      owner        = "platform"
      cost_center  = "eng"
    }
  }

  # SMOKE: asserts the availability_type passed to the upstream module, not the applied instance.
  assert {
    condition     = output.availability_type == "REGIONAL"
    error_message = "prod must default to REGIONAL."
  }
}

run "test_ha_default_off_in_dev" {
  command = plan

  variables {
    context = {
      organization = "olensys"
      environment  = "dev"
      application  = "example"
      owner        = "platform"
      cost_center  = "eng"
    }
  }

  # SMOKE: asserts the availability_type passed to the upstream module, not the applied instance.
  assert {
    condition     = output.availability_type == "ZONAL"
    error_message = "dev must default to ZONAL."
  }
}

run "test_ha_override_false_in_prod" {
  command = plan

  variables {
    context = {
      organization = "olensys"
      environment  = "prod"
      application  = "example"
      owner        = "platform"
      cost_center  = "eng"
    }
    high_availability = false
  }

  # SMOKE: asserts the availability_type passed to the upstream module, not the applied instance.
  assert {
    condition     = output.availability_type == "ZONAL"
    error_message = "high_availability = false must force ZONAL in prod."
  }
}

run "test_ha_requires_pitr_on_postgres" {
  command = plan

  variables {
    high_availability = true
    backup            = { pitr = false }
  }

  expect_failures = [output.connection_name]
}

run "test_ha_override_wins" {
  command = plan

  variables {
    high_availability = true
  }

  # SMOKE: asserts the availability_type passed to the upstream module, not the applied instance.
  assert {
    condition     = output.availability_type == "REGIONAL"
    error_message = "high_availability = true must force REGIONAL."
  }
}

run "test_edition_enterprise" {
  command = plan

  # SMOKE: asserts the edition value both module blocks receive (local.edition); the child module input is not addressable.
  assert {
    condition     = output.edition == "ENTERPRISE"
    error_message = "edition must be ENTERPRISE."
  }
}

run "test_edition_enterprise_mysql" {
  command = plan

  variables {
    engine           = "mysql"
    database_version = "MYSQL_8_0"
  }

  # SMOKE: asserts the edition value both module blocks receive (local.edition); the child module input is not addressable.
  assert {
    condition     = output.edition == "ENTERPRISE"
    error_message = "edition must be ENTERPRISE on mysql."
  }
}

run "test_edition_override_enterprise_plus" {
  command = plan

  variables {
    edition = "ENTERPRISE_PLUS"
    tier    = "db-perf-optimized-N-2"
  }

  assert {
    condition     = output.edition == "ENTERPRISE_PLUS"
    error_message = "edition must be passed through unchanged."
  }
}

run "test_edition_validation" {
  command = plan

  variables {
    edition = "STANDARD"
  }

  expect_failures = [var.edition]
}

run "test_edition_plus_rejects_custom_tier" {
  command = plan

  variables {
    edition = "ENTERPRISE_PLUS"
  }

  expect_failures = [output.connection_name]
}

run "test_deletion_protection_in_prod" {
  command = plan

  variables {
    context = {
      organization = "olensys"
      environment  = "prod"
      application  = "example"
      owner        = "platform"
      cost_center  = "eng"
    }
  }

  assert {
    condition     = output.deletion_protection == true
    error_message = "Deletion protection must be on in prod."
  }
}

run "test_deletion_protection_off_outside_prod" {
  command = plan

  assert {
    condition     = output.deletion_protection == false
    error_message = "Deletion protection must be off outside prod."
  }
}

run "test_deletion_protection_override_on_outside_prod" {
  command = plan

  variables {
    deletion_protection = true
  }

  assert {
    condition     = output.deletion_protection == true
    error_message = "deletion_protection = true must override the environment rule."
  }
}

run "test_deletion_protection_override_off_in_prod" {
  command = plan

  variables {
    deletion_protection = false
    context = {
      organization = "olensys"
      environment  = "prod"
      application  = "example"
      owner        = "platform"
      cost_center  = "eng"
    }
  }

  assert {
    condition     = output.deletion_protection == false
    error_message = "deletion_protection = false must override the environment rule."
  }
}

run "test_engine_validation" {
  command = plan

  variables {
    engine = "oracle"
  }

  expect_failures = [var.engine]
}

run "test_database_version_matches_engine" {
  command = plan

  variables {
    engine           = "mysql"
    database_version = "POSTGRES_16"
  }

  expect_failures = [output.connection_name]
}

run "test_mysql_engine_plans" {
  command = plan

  variables {
    engine           = "mysql"
    database_version = "MYSQL_8_0"
  }

  assert {
    condition     = output.availability_type == "ZONAL"
    error_message = "mysql path must plan."
  }
}

run "test_user_password_goes_to_secret" {
  command = plan

  variables {
    users = {
      app      = {}
      existing = { password_secret_id = "projects/example-project/secrets/existing-password" }
    }
  }

  assert {
    condition     = google_secret_manager_secret.user["app"].secret_id == "example-app-password"
    error_message = "A user without password_secret_id must get a generated secret named <name>-<user>-password."
  }

  assert {
    condition     = !contains(keys(google_secret_manager_secret.user), "existing")
    error_message = "A user with password_secret_id must not get a generated secret."
  }
}

run "test_user_shapes" {
  command = plan

  variables {
    users = {
      app      = {}
      existing = { password_secret_id = "projects/example-project/secrets/existing-password" }
      external = { manage_password = false }
    }
  }

  assert {
    condition     = keys(google_secret_manager_secret.user) == ["app"] && keys(random_password.user) == ["app"]
    error_message = "Only the generated user gets a random password and a new secret."
  }

  assert {
    condition     = keys(data.google_secret_manager_secret_version.user) == ["existing"]
    error_message = "Only the user with password_secret_id has a secret read."
  }

  assert {
    condition     = keys(google_sql_user.unmanaged) == ["external"] && google_sql_user.unmanaged["external"].password == null && google_sql_user.unmanaged["external"].type == "BUILT_IN"
    error_message = "The unmanaged user is created by this module as a BUILT_IN user with no password."
  }

  assert {
    condition     = keys(output.user_password_secret_ids) == ["app"]
    error_message = "Secret ids must list the generated user only."
  }

  assert {
    condition     = length(output.unmanaged_user_names) == 1 && output.unmanaged_user_names[0] == "external"
    error_message = "unmanaged_user_names must list the unmanaged user."
  }
}

run "test_unmanaged_user_mysql" {
  command = plan

  variables {
    engine           = "mysql"
    database_version = "MYSQL_8_0"
    users            = { external = { manage_password = false } }
  }

  assert {
    condition     = google_sql_user.unmanaged["external"].host == "%" && google_sql_user.unmanaged["external"].type == "BUILT_IN" && google_sql_user.unmanaged["external"].password == null
    error_message = "On mysql the unmanaged user is a BUILT_IN user for host % with no password."
  }
}

run "test_unmanaged_user_rejects_secret_id" {
  command = plan

  variables {
    users = { external = { manage_password = false, password_secret_id = "projects/example-project/secrets/x" } }
  }

  expect_failures = [var.users]
}

run "test_name_length_validation" {
  command = plan

  variables {
    name = "a234567890123456789012345678901234567890123456789012345678901234"
  }

  expect_failures = [var.name]
}

run "test_create_false_plans_nothing" {
  command = plan

  variables {
    create = false
  }

  assert {
    condition     = output.id == null && output.name == null && output.self_link == null && output.connection_name == null && output.private_ip == null && output.user_password_secret_ids == null && output.labels == null && output.ip_configuration == null && output.availability_type == null && output.applied_ip_configuration == null && output.edition == null && output.deletion_protection == null && output.unmanaged_user_names == null
    error_message = "All outputs must be null when create is false."
  }

  assert {
    condition     = length(google_secret_manager_secret.user) == 0 && length(google_sql_user.unmanaged) == 0
    error_message = "No secrets or users may be planned when create is false."
  }
}

run "test_tags_contract" {
  command = plan

  variables {
    labels = { owner = "x" }
    context = {
      organization = "olensys"
      environment  = "test"
      application  = "example"
      owner        = "platform"
      cost_center  = "eng"
      extra_tags   = { Owner = "y", Team = "Core Team" }
    }
  }

  assert {
    condition     = output.labels.owner == "x"
    error_message = "var.labels must win over context.extra_tags."
  }

  assert {
    condition     = output.labels.team == "core-team"
    error_message = "context.extra_tags must be merged and normalised."
  }
}
