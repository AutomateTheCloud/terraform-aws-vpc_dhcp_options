# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
}

# The servers' addresses are unknown at plan, so the plan must not depend on them.
run "plan_with_unknown_dns_server" {
  command = plan
  module {
    source = "./tests/fixtures/same_run_dns"
  }
}

run "apply_with_same_run_dns_server" {
  command = apply
  module {
    source = "./tests/fixtures/same_run_dns"
  }
  override_resource {
    target = aws_network_interface.dns
    values = { private_ip = "10.0.0.10", private_ips = ["10.0.0.10"] }
  }
  assert {
    condition = alltrue([
      output.metadata.vpc_dhcp_options.domain_name_servers == tolist(["10.0.0.10"]),
      output.metadata.vpc_dhcp_options.netbios_name_servers == tolist(["10.0.0.10"]),
      output.metadata.vpc_dhcp_options.netbios_node_type == "2",
    ])
    error_message = "The same-run servers were not used."
  }
}
