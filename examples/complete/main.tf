# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A DHCP option set for a VPC whose instances join a Microsoft Active Directory domain:
# the directory's domain controllers are the DNS and NetBIOS name servers, instances get
# the time from the Amazon Time Sync Service, and IPv6 address leases last a day.
#
# The addresses below are placeholders. Replace them with your domain controllers'
# addresses, which must be reachable from the VPC. Until then, instances in the VPC
# would have no working DNS; this VPC has no subnets, so there are none.

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "domain_controllers" {
  description = "IPv4 addresses of the Active Directory domain controllers"
  type        = list(string)
  default     = ["10.0.0.10", "10.0.1.10"]
}

module "vpc_dhcp_options" {
  source = "../../"

  details = {
    scope            = "Example"
    purpose          = "Directory DHCP Options"
    purpose_abbr     = "dir_dhcp"
    environment      = "Production"
    environment_abbr = "prd"
    additional_tags  = { CostCenter = "1234" }
  }

  domain_name                       = "corp.example.internal"
  domain_name_servers               = var.domain_controllers
  ntp_servers                       = ["169.254.169.123", "fd00:ec2::123"]
  netbios_name_servers              = var.domain_controllers
  netbios_node_type                 = 2
  ipv6_address_preferred_lease_time = 86400
}

# A VPC with no subnets or internet gateway, only to show the option set in use.
resource "aws_vpc" "this" {
  cidr_block                       = "10.0.0.0/16"
  assign_generated_ipv6_cidr_block = true
  enable_dns_support               = true
  enable_dns_hostnames             = true

  tags = merge(module.vpc_dhcp_options.metadata.details.tags, { Name = "example-complete-dhcp-options" })
}

resource "aws_vpc_dhcp_options_association" "this" {
  vpc_id          = aws_vpc.this.id
  dhcp_options_id = module.vpc_dhcp_options.metadata.vpc_dhcp_options.id
}

output "dhcp_options" {
  description = "The DHCP option set, as AWS stores it, and the VPC that uses it"
  value = {
    option_set = module.vpc_dhcp_options.metadata.vpc_dhcp_options
    vpc_id     = aws_vpc.this.id
  }
}
