# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_vpc_dhcp_options" "this" {
  region = var.region

  # Empty lists are passed as they are, not as null: the provider reads an option that
  # is not set back as [], and null would show as a change on the next plan.
  domain_name                       = local.domain_name
  domain_name_servers               = var.domain_name_servers
  ntp_servers                       = var.ntp_servers
  netbios_name_servers              = var.netbios_name_servers
  netbios_node_type                 = local.netbios_node_type
  ipv6_address_preferred_lease_time = var.ipv6_address_preferred_lease_time == null ? null : tostring(var.ipv6_address_preferred_lease_time)

  tags = merge(
    local.tags,
    {
      "Name" = "${local.scope.abbr}-${local.purpose.abbr}-${local.environment.abbr}-${local.aws.region.abbr}"
    }
  )

  # A DHCP option set cannot be changed, so any change to the options replaces it.
  # Creating the new set first lets a VPC association move to it in place, so the VPC
  # is never left on the Region's default option set in between.
  lifecycle {
    create_before_destroy = true
  }
}
