resource "aws_vpc_dhcp_options" "this" {
  domain_name          = var.domain_name
  domain_name_servers  = (length(var.domain_name_servers) > 0 ? var.domain_name_servers : null)
  ntp_servers          = (length(var.ntp_servers) > 0 ? var.ntp_servers : null)
  netbios_name_servers = (length(var.netbios_name_servers) > 0 ? var.netbios_name_servers : null)
  netbios_node_type    = (length(var.netbios_name_servers) > 0 ? var.netbios_node_type : null)

  tags = merge(
    local.tags,
    tomap({
      "Name" = "${local.scope.abbr}-${local.purpose.abbr}-${local.environment.abbr}-${local.aws.region.abbr}"
    })
  )
  provider = aws.this
}
