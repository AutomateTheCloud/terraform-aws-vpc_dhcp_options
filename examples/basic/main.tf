# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A DHCP option set with a private domain name and the Amazon DNS server, used by a new
# VPC. Instances in the VPC look up short names such as `web` as `web.example.internal`.

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

module "vpc_dhcp_options" {
  source = "../../"

  details = {
    scope       = "Example"
    purpose     = "Basic DHCP Options"
    environment = "Development"
  }

  domain_name = "example.internal"
}

# A VPC with no subnets or internet gateway, only to show the option set in use.
resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(module.vpc_dhcp_options.metadata.details.tags, { Name = "example-basic-dhcp-options" })
}

resource "aws_vpc_dhcp_options_association" "this" {
  vpc_id          = aws_vpc.this.id
  dhcp_options_id = module.vpc_dhcp_options.metadata.vpc_dhcp_options.id
}

output "dhcp_options" {
  description = "ID and settings of the DHCP option set, and the VPC that uses it"
  value = {
    id                  = module.vpc_dhcp_options.metadata.vpc_dhcp_options.id
    domain_name         = module.vpc_dhcp_options.metadata.vpc_dhcp_options.domain_name
    domain_name_servers = module.vpc_dhcp_options.metadata.vpc_dhcp_options.domain_name_servers
    vpc_id              = aws_vpc.this.id
  }
}
