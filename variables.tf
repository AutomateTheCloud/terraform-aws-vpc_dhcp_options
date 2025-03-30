variable "domain_name" {
  description = "Suffix domain name to use by default when resolving non Fully Qualified Domain Names"
  type        = string
  default     = "ec2.internal"
}

variable "domain_name_servers" {
  description = "List of name servers to configure (Default AWS Nameserver: 'AmazonProvidedDNS')"
  type        = list(any)
  default     = ["AmazonProvidedDNS"]
}

variable "ntp_servers" {
  description = "List of NTP servers to configure"
  type        = list(any)
  default     = []
}

variable "netbios_name_servers" {
  description = "List of NETBIOS name servers"
  type        = list(any)
  default     = []
}

variable "netbios_node_type" {
  description = "The NetBIOS node type (1,2,4,8)"
  type        = number
  default     = 2
}
