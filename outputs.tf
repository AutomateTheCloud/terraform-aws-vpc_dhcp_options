# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

output "metadata" {
  description = <<-EOT
    Everything the module created, in one object, so that other configurations need only one reference:

    - `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
    - `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`.
    - `vpc_dhcp_options` - The DHCP option set's `id` (pass it to `aws_vpc_dhcp_options_association` as `dhcp_options_id`), `arn`, `owner_id`, `region`, the options as AWS stores them (`domain_name`, `domain_name_servers`, `ntp_servers`, `netbios_name_servers`, `netbios_node_type`, `ipv6_address_preferred_lease_time`), `tags` and `tags_all`.
  EOT
  value = {
    details = {
      scope = {
        name    = local.scope.name
        abbr    = local.scope.abbr
        machine = local.scope.machine
      }
      purpose = {
        name    = local.purpose.name
        abbr    = local.purpose.abbr
        machine = local.purpose.machine
      }
      environment = {
        name    = local.environment.name
        abbr    = local.environment.abbr
        machine = local.environment.machine
      }
      tags = local.tags
    }

    aws = {
      account = {
        id = local.aws.account.id
      }
      region = {
        name        = local.aws.region.name
        abbr        = local.aws.region.abbr
        description = local.aws.region.description
      }
    }

    # One entry per resource.
    vpc_dhcp_options = local.output_resources.vpc_dhcp_options
  }
}

locals {
  # Each resource's attributes are listed one by one. Referencing a whole resource
  # would also reference any attribute the provider deprecates later, and every
  # caller's plan would print deprecation warnings.
  output_resources = {
    vpc_dhcp_options = {
      arn                               = aws_vpc_dhcp_options.this.arn
      domain_name                       = aws_vpc_dhcp_options.this.domain_name
      domain_name_servers               = aws_vpc_dhcp_options.this.domain_name_servers
      id                                = aws_vpc_dhcp_options.this.id
      ipv6_address_preferred_lease_time = aws_vpc_dhcp_options.this.ipv6_address_preferred_lease_time
      netbios_name_servers              = aws_vpc_dhcp_options.this.netbios_name_servers
      netbios_node_type                 = aws_vpc_dhcp_options.this.netbios_node_type
      ntp_servers                       = aws_vpc_dhcp_options.this.ntp_servers
      owner_id                          = aws_vpc_dhcp_options.this.owner_id
      region                            = aws_vpc_dhcp_options.this.region
      tags                              = aws_vpc_dhcp_options.this.tags
      tags_all                          = aws_vpc_dhcp_options.this.tags_all
    }
  }
}
