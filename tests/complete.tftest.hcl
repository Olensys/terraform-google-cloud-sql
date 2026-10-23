# Run only by the nightly integration workflow, against real cloud credentials.
# Requires TF_VAR_project_id and TF_VAR_network_self_link (a VPC with private service access).
run "apply_minimal" {
  command = apply

  module {
    source = "./examples/minimal"
  }
}
