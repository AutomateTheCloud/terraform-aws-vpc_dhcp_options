# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

variable "details" {
  description = <<-EOT
    Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-vpc_dhcp_options#the-details-input) explains why it is required.

    - `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
    - `purpose` - (Required) What the resource is for: `Web Site`.
    - `environment` - (Required) The environment: `Production`.
    - `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
    - `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.
  EOT
  type = object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
  nullable = false

  validation {
    condition     = trimspace(var.details.scope) != ""
    error_message = "Scope not specified."
  }

  validation {
    condition     = trimspace(var.details.purpose) != ""
    error_message = "Purpose not specified."
  }

  validation {
    condition     = trimspace(var.details.environment) != ""
    error_message = "Environment not specified."
  }
}

variable "domain_name" {
  description = <<-EOT
    The domain name that instances add to names that are not fully qualified, so that `web` is looked up as `web.example.internal`. Use only a domain you control.

    - `null`, the default, uses the domain name of the Region's default DHCP option set: `ec2.internal` in `us-east-1`, and `<region>.compute.internal`, such as `us-west-2.compute.internal`, in every other Region. These are the names the Amazon DNS server gives instances.
    - `""` sets no domain name.

    Some Linux systems accept several domain names separated by spaces, but Windows and most Linux systems read the value as one name, so give only one.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.domain_name == null || var.domain_name == "" || can(regex("^[A-Za-z0-9_-]+(\\.[A-Za-z0-9_-]+)*\\.?( [A-Za-z0-9_-]+(\\.[A-Za-z0-9_-]+)*\\.?)*$", var.domain_name))
    error_message = "domain_name must be a domain name such as example.internal: letters, numbers, hyphens and underscores, with single periods between labels, and single spaces between names."
  }

  validation {
    condition = !(
      var.domain_name == "" && length(var.domain_name_servers) == 0 && length(var.ntp_servers) == 0 &&
      length(var.netbios_name_servers) == 0 && var.netbios_node_type == null && var.ipv6_address_preferred_lease_time == null
    )
    error_message = "A DHCP option set needs at least one option: domain_name is \"\" and every other option is empty."
  }
}

variable "domain_name_servers" {
  description = <<-EOT
    The DNS servers that instances use. The default, `["AmazonProvidedDNS"]`, is the Amazon DNS server, which resolves public names, the VPC's own names and Amazon Route 53 private hosted zones.

    Give either `AmazonProvidedDNS` or your own servers' IP addresses, not both: AWS warns that mixing them can cause unexpected behavior, because an instance may ask either one and get different answers. Up to four IPv4 addresses (`AmazonProvidedDNS` counts as one of the four) and four IPv6 addresses.

    An empty list sets no DNS servers. Instances built on the AWS Nitro System then use `169.254.169.253`; older (Xen) instances have no DNS at all and cannot reach the internet by name.
  EOT
  type        = list(string)
  default     = ["AmazonProvidedDNS"]
  nullable    = false

  validation {
    condition     = alltrue([for s in var.domain_name_servers : s == "AmazonProvidedDNS" || can(cidrnetmask("${s}/32")) || can(cidrhost("${s}/128", 0))])
    error_message = "domain_name_servers must contain IPv4 or IPv6 addresses, or AmazonProvidedDNS (spelled exactly so)."
  }

  validation {
    condition     = length([for s in var.domain_name_servers : s if s == "AmazonProvidedDNS" || can(cidrnetmask("${s}/32"))]) <= 4
    error_message = "domain_name_servers can have at most four IPv4 addresses, counting AmazonProvidedDNS as one."
  }

  validation {
    condition     = length([for s in var.domain_name_servers : s if can(cidrhost("${s}/128", 0))]) <= 4
    error_message = "domain_name_servers can have at most four IPv6 addresses."
  }

  validation {
    condition     = length(distinct(var.domain_name_servers)) == length(var.domain_name_servers)
    error_message = "domain_name_servers must not repeat an entry."
  }
}

variable "ipv6_address_preferred_lease_time" {
  description = <<-EOT
    How long, in seconds, a DHCPv6 lease for an instance's IPv6 address lasts. Instances usually renew it when half the time has passed. From 140 to 2147483647 (about 68 years). `null`, the default, leaves it unset, and AWS uses 140 seconds. A longer time means fewer renewal requests from instances with long-lived IPv6 addresses.
  EOT
  type        = number
  default     = null

  validation {
    condition     = var.ipv6_address_preferred_lease_time == null || try(var.ipv6_address_preferred_lease_time >= 140 && var.ipv6_address_preferred_lease_time <= 2147483647 && floor(var.ipv6_address_preferred_lease_time) == var.ipv6_address_preferred_lease_time, false)
    error_message = "ipv6_address_preferred_lease_time must be a whole number of seconds from 140 to 2147483647."
  }
}

variable "netbios_name_servers" {
  description = <<-EOT
    The IPv4 addresses of up to four NetBIOS name servers, used by Windows instances to look up NetBIOS computer names. An empty list, the default, sets none.
  EOT
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition     = alltrue([for s in var.netbios_name_servers : can(cidrnetmask("${s}/32"))])
    error_message = "netbios_name_servers must contain IPv4 addresses."
  }

  validation {
    condition     = length(var.netbios_name_servers) <= 4 && length(distinct(var.netbios_name_servers)) == length(var.netbios_name_servers)
    error_message = "netbios_name_servers can have at most four addresses, with no repeats."
  }
}

variable "netbios_node_type" {
  description = <<-EOT
    How Windows instances look up NetBIOS names: `1` (broadcast), `2` (point-to-point), `4` (mixed) or `8` (hybrid). Broadcast and multicast do not work in a VPC, so AWS recommends `2`.

    `null`, the default, sets `2` when `netbios_name_servers` is not empty, and nothing otherwise.
  EOT
  type        = number
  default     = null

  validation {
    condition     = var.netbios_node_type == null || try(contains([1, 2, 4, 8], var.netbios_node_type), false)
    error_message = "netbios_node_type must be 1, 2, 4 or 8 (2 is the one AWS recommends)."
  }
}

variable "ntp_servers" {
  description = <<-EOT
    The Network Time Protocol (NTP) servers that instances get the time from: up to four IPv4 and four IPv6 addresses. An empty list, the default, sets none, and instances use the Amazon Time Sync Service, which is also reachable at `169.254.169.123` and, on Nitro instances, `fd00:ec2::123`.
  EOT
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition     = alltrue([for s in var.ntp_servers : can(cidrnetmask("${s}/32")) || can(cidrhost("${s}/128", 0))])
    error_message = "ntp_servers must contain IPv4 or IPv6 addresses."
  }

  validation {
    condition = (
      length([for s in var.ntp_servers : s if can(cidrnetmask("${s}/32"))]) <= 4 &&
      length([for s in var.ntp_servers : s if can(cidrhost("${s}/128", 0))]) <= 4 &&
      length(distinct(var.ntp_servers)) == length(var.ntp_servers)
    )
    error_message = "ntp_servers can have at most four IPv4 and four IPv6 addresses, with no repeats."
  }
}

variable "region" {
  description = <<-EOT
    The AWS Region to create the DHCP option set in, such as `us-west-2`. Defaults to the Region of the AWS provider passed to the module. The option set can be used only by VPCs in the same Region.
  EOT
  type        = string
  default     = null
}
