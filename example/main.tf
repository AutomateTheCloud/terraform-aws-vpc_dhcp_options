terraform {
  required_version = "~> 1.11.0"
}

##-----------------------------------------------------------------------------
# Providers
provider "aws" {
  alias  = "example"
  region = "us-east-1"
}

##-----------------------------------------------------------------------------
# Module: VPC DHCP Option Set
module "vpc_dhcp_options" {
  source    = "../"
  providers = { aws.this = aws.example }

  details = {
    scope               = "Demo"
    purpose             = "VPC DHCP Option Set"
    environment         = "dev"
    additional_tags = {
      "Project"         = "Project Name"
      "ProjectID"       = "123456789"
      "Contact"         = "David Singer - david.singer@example.com"
    }
  }

  # domain_name          = "example.com"
  domain_name_servers  = [
    "8.8.8.8",
    "8.8.4.4",
    "AmazonProvidedDNS"
  ]
  # ntp_servers          = [ "127.0.0.1" ]
  # netbios_name_servers = [ "127.0.0.1" ]
  # netbios_node_type    = 2
}

##-----------------------------------------------------------------------------
# Outputs
output "metadata" {
  description = "Metadata"
  value = module.vpc_dhcp_options.metadata
}
