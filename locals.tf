# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

locals {
  # The domain name of the Region's default DHCP option set: ec2.internal in us-east-1,
  # <region>.compute.internal everywhere else. null in the input means this value, and
  # "" means no domain name.
  region_domain_name = local.aws.region.name == "us-east-1" ? "ec2.internal" : "${local.aws.region.name}.compute.internal"
  domain_name        = var.domain_name == null ? local.region_domain_name : (var.domain_name == "" ? null : var.domain_name)

  # NetBIOS node type 2 (point-to-point) is the one AWS recommends, and the only one
  # that works without broadcast. It is set by default only when there are NetBIOS
  # name servers, as in the Region's default option set.
  netbios_node_type = var.netbios_node_type != null ? tostring(var.netbios_node_type) : (length(var.netbios_name_servers) > 0 ? "2" : null)
}
