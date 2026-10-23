# Run only by the nightly integration workflow, against real cloud credentials.
# Requires TF_VAR_project_id and TF_VAR_network_self_link (a VPC with private service access).
run "apply_minimal_assertions" {
  command = apply

  module {
    source = "./examples/minimal"
  }

  assert {
    condition     = output.ip_configuration.ipv4_enabled == false
    error_message = "The applied instance must not have a public IPv4 address."
  }

  assert {
    condition     = output.ip_configuration.ssl_mode == "ENCRYPTED_ONLY"
    error_message = "The applied instance must require encrypted connections."
  }
}
