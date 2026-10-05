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

variables {
  details = { scope = "Test", purpose = "Region", environment = "test" }
}

# The module uses the default aws provider: no providers block is needed.
run "provider_region_by_default" {
  command = plan
  assert {
    condition     = output.metadata.aws.region.name == "us-east-1"
    error_message = "Expected the provider's Region."
  }
}

run "region_reaches_every_resource" {
  command = apply
  variables { region = "us-west-2" }
  assert {
    condition = alltrue([
      aws_vpc_dhcp_options.this.region == "us-west-2",
      output.metadata.vpc_dhcp_options.region == "us-west-2",
      output.metadata.aws.region.name == "us-west-2",
      output.metadata.aws.region.abbr == "usw2",
      aws_vpc_dhcp_options.this.tags["Name"] == "test-region-test-usw2",
    ])
    error_message = "region was not passed through to every resource."
  }
}

# Regression: domain_name defaulted to ec2.internal, which is right only in us-east-1.
run "domain_name_follows_region" {
  command = plan
  variables { region = "eu-west-1" }
  assert {
    condition     = aws_vpc_dhcp_options.this.domain_name == "eu-west-1.compute.internal"
    error_message = "Expected the Region's default domain name."
  }
}

# Regression: the old hard-coded Region table failed the plan in any Region missing
# from it, such as ca-west-1.
run "region_abbreviation_not_in_old_table" {
  command = plan
  variables { region = "ca-west-1" }
  assert {
    condition     = output.metadata.aws.region.abbr == "caw1"
    error_message = "Unexpected abbreviation."
  }
}

run "region_abbreviation_new_region" {
  command = plan
  variables { region = "ap-southeast-7" }
  assert {
    condition     = output.metadata.aws.region.abbr == "apse7"
    error_message = "Unexpected abbreviation."
  }
}

run "region_abbreviation_override" {
  command = plan
  variables { region = "us-gov-west-1" }
  assert {
    condition = alltrue([
      output.metadata.aws.region.abbr == "ugw1",
      aws_vpc_dhcp_options.this.domain_name == "us-gov-west-1.compute.internal",
    ])
    error_message = "Unexpected abbreviation or domain name."
  }
}
