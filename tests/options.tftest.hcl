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
  details = { scope = "Test", purpose = "Options", environment = "test" }
}

run "every_option" {
  command = plan
  variables {
    domain_name                       = "corp.example.internal"
    domain_name_servers               = ["10.0.0.10", "10.0.1.10", "fd00:ec2::10"]
    ntp_servers                       = ["169.254.169.123", "fd00:ec2::123"]
    netbios_name_servers              = ["10.0.0.10"]
    netbios_node_type                 = 8
    ipv6_address_preferred_lease_time = 86400
  }
  assert {
    condition = alltrue([
      aws_vpc_dhcp_options.this.domain_name == "corp.example.internal",
      aws_vpc_dhcp_options.this.domain_name_servers == tolist(["10.0.0.10", "10.0.1.10", "fd00:ec2::10"]),
      aws_vpc_dhcp_options.this.ntp_servers == tolist(["169.254.169.123", "fd00:ec2::123"]),
      aws_vpc_dhcp_options.this.netbios_name_servers == tolist(["10.0.0.10"]),
      aws_vpc_dhcp_options.this.netbios_node_type == "8",
      aws_vpc_dhcp_options.this.ipv6_address_preferred_lease_time == "86400",
    ])
    error_message = "Options were not applied."
  }
}

run "netbios_node_type_defaults_to_2_with_servers" {
  command = plan
  variables { netbios_name_servers = ["10.0.0.10", "10.0.1.10"] }
  assert {
    condition     = aws_vpc_dhcp_options.this.netbios_node_type == "2"
    error_message = "netbios_node_type must default to 2 when there are NetBIOS name servers."
  }
}

# Regression: an explicit netbios_node_type used to be dropped without a word when
# netbios_name_servers was empty.
run "netbios_node_type_kept_without_servers" {
  command = plan
  variables { netbios_node_type = 2 }
  assert {
    condition     = aws_vpc_dhcp_options.this.netbios_node_type == "2"
    error_message = "An explicit netbios_node_type must be set."
  }
}

run "no_domain_name" {
  command = plan
  variables { domain_name = "" }
  assert {
    condition     = aws_vpc_dhcp_options.this.domain_name == null
    error_message = "domain_name = \"\" must set no domain name."
  }
}

run "no_dns_servers" {
  command = plan
  variables { domain_name_servers = [] }
  assert {
    condition     = length(aws_vpc_dhcp_options.this.domain_name_servers) == 0
    error_message = "An empty domain_name_servers must set no DNS servers."
  }
}

run "only_ntp" {
  command = plan
  variables {
    domain_name         = ""
    domain_name_servers = []
    ntp_servers         = ["169.254.169.123"]
  }
  assert {
    condition     = aws_vpc_dhcp_options.this.ntp_servers == tolist(["169.254.169.123"])
    error_message = "One option on its own must be enough."
  }
}
