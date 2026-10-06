# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Each validation rejects a value AWS would reject, at plan time.
mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
}

variables {
  details = { scope = "Test", purpose = "Validation", environment = "test" }
}

run "domain_name_rejects_bad_characters" {
  command = plan
  variables { domain_name = "example..internal" }
  expect_failures = [var.domain_name]
}

run "domain_name_rejects_leading_space" {
  command = plan
  variables { domain_name = " example.internal" }
  expect_failures = [var.domain_name]
}

run "no_options_at_all" {
  command = plan
  variables {
    domain_name         = ""
    domain_name_servers = []
  }
  expect_failures = [var.domain_name]
}

run "dns_server_not_an_address" {
  command = plan
  variables { domain_name_servers = ["dns.example.com"] }
  expect_failures = [var.domain_name_servers]
}

run "dns_server_misspelled_amazon" {
  command = plan
  variables { domain_name_servers = ["AmazonProvidedDns"] }
  expect_failures = [var.domain_name_servers]
}

run "dns_too_many_ipv4" {
  command = plan
  variables { domain_name_servers = ["10.0.0.1", "10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5"] }
  expect_failures = [var.domain_name_servers]
}

# AmazonProvidedDNS takes one of the four IPv4 places.
run "dns_too_many_with_amazon" {
  command = plan
  variables { domain_name_servers = ["AmazonProvidedDNS", "10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5"] }
  expect_failures = [var.domain_name_servers]
}

run "dns_too_many_ipv6" {
  command = plan
  variables { domain_name_servers = ["fd00::1", "fd00::2", "fd00::3", "fd00::4", "fd00::5"] }
  expect_failures = [var.domain_name_servers]
}

run "dns_repeated" {
  command = plan
  variables { domain_name_servers = ["10.0.0.1", "10.0.0.1"] }
  expect_failures = [var.domain_name_servers]
}

run "dns_four_ipv4_and_four_ipv6_allowed" {
  command = plan
  variables {
    domain_name_servers = ["10.0.0.1", "10.0.0.2", "10.0.0.3", "10.0.0.4", "fd00::1", "fd00::2", "fd00::3", "fd00::4"]
  }
  assert {
    condition     = length(aws_vpc_dhcp_options.this.domain_name_servers) == 8
    error_message = "Four IPv4 and four IPv6 DNS servers must be allowed."
  }
}

run "ntp_not_an_address" {
  command = plan
  variables { ntp_servers = ["time.example.com"] }
  expect_failures = [var.ntp_servers]
}

run "ntp_too_many_ipv4" {
  command = plan
  variables { ntp_servers = ["10.0.0.1", "10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5"] }
  expect_failures = [var.ntp_servers]
}

run "netbios_ipv6_rejected" {
  command = plan
  variables { netbios_name_servers = ["fd00::1"] }
  expect_failures = [var.netbios_name_servers]
}

run "netbios_too_many" {
  command = plan
  variables { netbios_name_servers = ["10.0.0.1", "10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5"] }
  expect_failures = [var.netbios_name_servers]
}

# Regression: any number used to reach AWS. Its API accepts 3, but only 1, 2, 4 and 8
# (the node types RFC 2132 defines) are documented or mean anything.
run "netbios_node_type_invalid" {
  command = plan
  variables { netbios_node_type = 3 }
  expect_failures = [var.netbios_node_type]
}

run "lease_time_too_short" {
  command = plan
  variables { ipv6_address_preferred_lease_time = 139 }
  expect_failures = [var.ipv6_address_preferred_lease_time]
}

run "lease_time_too_long" {
  command = plan
  variables { ipv6_address_preferred_lease_time = 2147483648 }
  expect_failures = [var.ipv6_address_preferred_lease_time]
}

run "lease_time_not_whole" {
  command = plan
  variables { ipv6_address_preferred_lease_time = 300.5 }
  expect_failures = [var.ipv6_address_preferred_lease_time]
}
