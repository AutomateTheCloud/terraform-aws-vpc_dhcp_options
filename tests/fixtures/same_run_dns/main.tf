# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

# DNS and NetBIOS servers whose addresses are known only after apply, created in the same
# run as the DHCP option set, as with a directory service or a server on an instance.
# domain_name_servers is a list with an unknown element; netbios_name_servers is an
# unknown list whose length is unknown too, as with a directory's dns_ip_addresses.
resource "aws_network_interface" "dns" {
  subnet_id = "subnet-00000000000000000"
}

module "vpc_dhcp_options" {
  source = "../../.."

  details              = { scope = "Test", purpose = "Same Run", environment = "test" }
  domain_name          = "corp.example.internal"
  domain_name_servers  = [aws_network_interface.dns.private_ip]
  ntp_servers          = ["169.254.169.123"]
  netbios_name_servers = tolist(aws_network_interface.dns.private_ips)
}

output "metadata" {
  value = module.vpc_dhcp_options.metadata
}
