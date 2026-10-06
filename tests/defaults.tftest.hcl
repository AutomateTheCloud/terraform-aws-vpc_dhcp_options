# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Offline tests: every provider is mocked, so no AWS account is used.
mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
}

variables {
  details = { scope = "Test", purpose = "Defaults", environment = "test" }
}

run "defaults" {
  command = apply

  assert {
    condition = alltrue([
      aws_vpc_dhcp_options.this.domain_name == "ec2.internal",
      aws_vpc_dhcp_options.this.domain_name_servers == tolist(["AmazonProvidedDNS"]),
      length(aws_vpc_dhcp_options.this.ntp_servers) == 0,
      length(aws_vpc_dhcp_options.this.netbios_name_servers) == 0,
      aws_vpc_dhcp_options.this.netbios_node_type == null,
      aws_vpc_dhcp_options.this.ipv6_address_preferred_lease_time == null,
    ])
    error_message = "The defaults must match the Region's default DHCP option set."
  }
  assert {
    condition = alltrue([
      output.metadata.vpc_dhcp_options.id == aws_vpc_dhcp_options.this.id,
      output.metadata.vpc_dhcp_options.domain_name == "ec2.internal",
      output.metadata.aws.region.name == "us-east-1",
      output.metadata.aws.region.abbr == "use1",
      output.metadata.aws.account.id == "111111111111",
    ])
    error_message = "Unexpected metadata output."
  }
}

run "tags" {
  command = plan
  variables {
    details = { scope = "Test", purpose = "Defaults", environment = "test", additional_tags = { CostCenter = "1234" } }
  }
  assert {
    condition = aws_vpc_dhcp_options.this.tags == tomap({
      Scope       = "Test"
      Purpose     = "Defaults"
      Environment = "test"
      CostCenter  = "1234"
      Name        = "test-defaults-test-use1"
    })
    error_message = "Unexpected tags."
  }
}

# Regression: an empty abbreviation override used to replace the generated one with "",
# so the Name tag started with a hyphen.
run "abbreviation_override" {
  command = plan
  variables {
    details = { scope = "Automate the Cloud", scope_abbr = "atc-org", purpose = "VPC DHCP Options", purpose_abbr = "", environment = "Production" }
  }
  assert {
    condition = alltrue([
      output.metadata.details.scope.abbr == "atc-org",
      output.metadata.details.scope.machine == "atcorg",
      output.metadata.details.purpose.abbr == "vpc_dhcp_options",
      output.metadata.details.purpose.machine == "vpcdhcpoptions",
      aws_vpc_dhcp_options.this.tags["Name"] == "atc-org-vpc_dhcp_options-production-use1",
    ])
    error_message = "Unexpected abbreviations."
  }
}

run "details_scope_required" {
  command = plan
  variables { details = { scope = " ", purpose = "p", environment = "e" } }
  expect_failures = [var.details]
}

run "details_purpose_required" {
  command = plan
  variables { details = { scope = "s", purpose = "", environment = "e" } }
  expect_failures = [var.details]
}

run "details_environment_required" {
  command = plan
  variables { details = { scope = "s", purpose = "p", environment = "" } }
  expect_failures = [var.details]
}
