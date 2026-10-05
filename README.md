# Terraform module for Amazon VPC DHCP option sets

Creates a DHCP option set for an Amazon Virtual Private Cloud (VPC). A DHCP option set holds the network settings that instances in a VPC receive from the VPC's Dynamic Host Configuration Protocol (DHCP) server: the DNS servers, the domain name added to short host names, the time servers, and the NetBIOS settings for Windows.

The defaults are the same as the Region's own default option set, so a set created with only the required inputs changes nothing until you set an option. Every option is checked at plan time against the limits AWS sets.

## What it configures

| Setting | Default | Input |
|---|---|---|
| DNS servers | `AmazonProvidedDNS`, the Amazon DNS server | `domain_name_servers` |
| Domain name | The Region's: `ec2.internal` in `us-east-1`, `<region>.compute.internal` elsewhere | `domain_name` |
| Time (NTP) servers | None: instances use the Amazon Time Sync Service | `ntp_servers` |
| NetBIOS name servers | None | `netbios_name_servers` |
| NetBIOS node type | `2` when there are NetBIOS name servers, otherwise none | `netbios_node_type` |
| IPv6 address lease time | None: AWS uses 140 seconds | `ipv6_address_preferred_lease_time` |
| Association with a VPC | None: see [Using the option set](https://github.com/AutomateTheCloud/terraform-aws-vpc_dhcp_options#using-the-option-set) | Not in the module |

## Usage

```hcl
module "vpc_dhcp_options" {
  source  = "AutomateTheCloud/vpc_dhcp_options/aws"
  version = "~> 1.0"

  details = {
    scope       = "Automate the Cloud"
    purpose     = "Web Site"
    environment = "Production"
  }

  domain_name = "web.example.internal"
}

resource "aws_vpc_dhcp_options_association" "this" {
  vpc_id          = aws_vpc.this.id
  dhcp_options_id = module.vpc_dhcp_options.metadata.vpc_dhcp_options.id
}
```

`details` is the only required input. It sets the `Scope`, `Purpose` and `Environment` tags, and the `Name` tag, here `automate_the_cloud-web_site-production-use1`.

The module uses your default `aws` provider and creates the option set in that provider's Region. A VPC can use only an option set in its own Region. To create one somewhere else without configuring another provider, set `region`:

```hcl
module "vpc_dhcp_options_us_west_2" {
  source  = "AutomateTheCloud/vpc_dhcp_options/aws"
  version = "~> 1.0"

  region  = "us-west-2"
  details = { scope = "Automate the Cloud", purpose = "Web Site", environment = "Production" }
}
```

Because `region` is an ordinary input, one module block can create an option set in each of several Regions with `for_each`. In `us-west-2` the default domain name is `us-west-2.compute.internal`.

To use a provider configured for another account, pass it explicitly with `providers = { aws = aws.other_account }`.

## The `details` input

Most modules ask only for what the resource itself needs. This one also requires `details`: three names that say what the DHCP option set belongs to, what it is for, and which environment it is in. Every Automate the Cloud module takes the same input, and requiring it is deliberate.

```hcl
details = {
  scope       = "Automate the Cloud" # what it belongs to: an organization, team or project
  purpose     = "Web Site"           # what it is for
  environment = "Production"         # which environment
}
```

**Every resource can be traced.** The three names become the `Scope`, `Purpose` and `Environment` tags on every resource the module creates. Months later, anyone looking at a DHCP option set in the AWS console, or at a line on the bill, can see who it belongs to and why it exists. With cost allocation tags turned on in AWS Billing, the same tags split your bill by project and environment. Because the input is required and checked, no resource can be created without them.

**One definition for a whole stack.** Write `details` once and pass the same value to every module, so the DHCP option set, the VPC that uses it, its DNS zone and everything else are tagged alike. Tags you want everywhere, such as a cost center or the Terraform workspace, go in `additional_tags`:

```hcl
locals {
  details = {
    scope           = "Automate the Cloud"
    purpose         = "Web Site"
    environment     = "Production"
    additional_tags = { CostCenter = "1234", IaC = "true" }
  }
}

module "site_dhcp_options" {
  source  = "AutomateTheCloud/vpc_dhcp_options/aws"
  version = "~> 1.0"

  details     = local.details
  domain_name = "web.example.internal"
}
```

**Consistent names.** The module turns each name into two short forms other resources can be named with: `abbr`, lowercase with words joined by underscores (`Web Site` becomes `web_site`), and `machine`, lowercase letters and numbers only (`website`), for resources that allow no underscores. It also works out a short form of the Region, such as `use1` for `us-east-1`. Every module derives these the same way, so names stay consistent across a stack. To choose your own short forms, set `scope_abbr`, `purpose_abbr` or `environment_abbr`, for example `environment_abbr = "prd"`.

**One output to reach everything.** All of it comes back in the `metadata` output, along with everything the module created, so a configuration needs only one reference: `module.site_dhcp_options.metadata.vpc_dhcp_options.id` for the option set's ID, or `module.site_dhcp_options.metadata.aws.region.abbr` for the Region's short form.

## Examples

Each example is a complete configuration you can run with `terraform init` and `terraform apply`.

- [Basic option set](https://github.com/AutomateTheCloud/terraform-aws-vpc_dhcp_options/tree/main/examples/basic): a private domain name with the Amazon DNS server, used by a new VPC.
- [Complete](https://github.com/AutomateTheCloud/terraform-aws-vpc_dhcp_options/tree/main/examples/complete): your own DNS, time and NetBIOS servers, such as a Microsoft Active Directory's domain controllers, used by a new VPC.

## Things to know

### Using the option set

An option set does nothing until a VPC uses it. The module creates only the option set. Associate it with each VPC with an `aws_vpc_dhcp_options_association` resource, as in the [usage example](https://github.com/AutomateTheCloud/terraform-aws-vpc_dhcp_options#usage), or with the VPC module you use. A VPC uses one option set at a time, and one option set can be used by many VPCs in the same Region and account.

Instances pick up the new settings when they renew their DHCP lease, which can take a few hours. Renew the lease on an instance to apply them at once.

### Changing an option replaces the option set

AWS cannot change a DHCP option set after it is created, so changing any option, or `region`, replaces it. The module creates the new option set before it deletes the old one, so an `aws_vpc_dhcp_options_association` that refers to `metadata.vpc_dhcp_options.id` moves to the new set in place, and the VPC is never left without its settings in between. Changing only `details` updates the tags in place.

### The Amazon DNS server

`AmazonProvidedDNS` is the DNS server at the base of the VPC's IPv4 network plus two, and at `169.254.169.253`. It resolves public names, the names of instances in the VPC, and Amazon Route 53 private hosted zones associated with the VPC. It answers only when the VPC has DNS resolution (`enable_dns_support`) turned on, as it is by default.

To resolve names on another network, such as an on-premises domain, keep `AmazonProvidedDNS` and add Route 53 Resolver forwarding rules for those domains, rather than listing the other network's DNS servers here. Instances then still resolve private hosted zones and AWS service endpoints.

### Your own DNS servers

Give either `AmazonProvidedDNS` or your own servers' addresses, not both. An instance may ask any server in the list, and AWS warns that mixing them can cause unexpected behavior: a name may resolve one moment and not the next. Your servers must be reachable from the VPC, must resolve the `domain_name` you set, and should forward everything else to the Amazon DNS server, or instances lose private hosted zones and the names of AWS services' private endpoints.

### The domain name

The default is the domain of the Region's default option set, the domain in which the Amazon DNS server gives each instance a name, such as `ip-10-0-0-12.ec2.internal`. Set your own only for a domain you control and your DNS servers, or a private hosted zone, resolve. `domain_name = ""` sets none.

### Removing an option set from a VPC

Destroying an `aws_vpc_dhcp_options_association` leaves the VPC with no DHCP option set at all (`default` in the AWS API), not with the Region's default option set. So does destroying the option set while a VPC still uses it: AWS cannot delete an option set in use, so the AWS provider first takes it off each VPC. In a VPC with no option set, instances built on the AWS Nitro System use the DNS server at `169.254.169.253`, and older (Xen) instances have no DNS at all. To go back to the Region's default option set, associate it with the VPC (find its ID with `aws ec2 describe-dhcp-options`) before you remove this one.

## Contributing

Contributions are welcome, after review. Read [CONTRIBUTING.md](https://github.com/AutomateTheCloud/terraform-aws-vpc_dhcp_options/blob/main/CONTRIBUTING.md) before opening a pull request, and report security problems as described in [SECURITY.md](https://github.com/AutomateTheCloud/terraform-aws-vpc_dhcp_options/blob/main/SECURITY.md).

## Testing

The tests in `tests/` run offline against mocked AWS providers, so they need no AWS account:

```shell
terraform init
terraform test
```

## Reference

The sections below are generated from the code by [terraform-docs](https://terraform-docs.io). To update them, run `terraform-docs .`.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (>= 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_details"></a> [details](#input_details)

Description: Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-vpc_dhcp_options#the-details-input) explains why it is required.

- `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
- `purpose` - (Required) What the resource is for: `Web Site`.
- `environment` - (Required) The environment: `Production`.
- `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
- `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.

Type:

```hcl
object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
```

### Optional Inputs

The following input variables are optional (have default values):

#### <a name="input_domain_name"></a> [domain_name](#input_domain_name)

Description: The domain name that instances add to names that are not fully qualified, so that `web` is looked up as `web.example.internal`. Use only a domain you control.

- `null`, the default, uses the domain name of the Region's default DHCP option set: `ec2.internal` in `us-east-1`, and `<region>.compute.internal`, such as `us-west-2.compute.internal`, in every other Region. These are the names the Amazon DNS server gives instances.
- `""` sets no domain name.

Some Linux systems accept several domain names separated by spaces, but Windows and most Linux systems read the value as one name, so give only one.

Type: `string`

Default: `null`

#### <a name="input_domain_name_servers"></a> [domain_name_servers](#input_domain_name_servers)

Description: The DNS servers that instances use. The default, `["AmazonProvidedDNS"]`, is the Amazon DNS server, which resolves public names, the VPC's own names and Amazon Route 53 private hosted zones.

Give either `AmazonProvidedDNS` or your own servers' IP addresses, not both: AWS warns that mixing them can cause unexpected behavior, because an instance may ask either one and get different answers. Up to four IPv4 addresses (`AmazonProvidedDNS` counts as one of the four) and four IPv6 addresses.

An empty list sets no DNS servers. Instances built on the AWS Nitro System then use `169.254.169.253`; older (Xen) instances have no DNS at all and cannot reach the internet by name.

Type: `list(string)`

Default:

```json
[
  "AmazonProvidedDNS"
]
```

#### <a name="input_ipv6_address_preferred_lease_time"></a> [ipv6_address_preferred_lease_time](#input_ipv6_address_preferred_lease_time)

Description: How long, in seconds, a DHCPv6 lease for an instance's IPv6 address lasts. Instances usually renew it when half the time has passed. From 140 to 2147483647 (about 68 years). `null`, the default, leaves it unset, and AWS uses 140 seconds. A longer time means fewer renewal requests from instances with long-lived IPv6 addresses.

Type: `number`

Default: `null`

#### <a name="input_netbios_name_servers"></a> [netbios_name_servers](#input_netbios_name_servers)

Description: The IPv4 addresses of up to four NetBIOS name servers, used by Windows instances to look up NetBIOS computer names. An empty list, the default, sets none.

Type: `list(string)`

Default: `[]`

#### <a name="input_netbios_node_type"></a> [netbios_node_type](#input_netbios_node_type)

Description: How Windows instances look up NetBIOS names: `1` (broadcast), `2` (point-to-point), `4` (mixed) or `8` (hybrid). Broadcast and multicast do not work in a VPC, so AWS recommends `2`.

`null`, the default, sets `2` when `netbios_name_servers` is not empty, and nothing otherwise.

Type: `number`

Default: `null`

#### <a name="input_ntp_servers"></a> [ntp_servers](#input_ntp_servers)

Description: The Network Time Protocol (NTP) servers that instances get the time from: up to four IPv4 and four IPv6 addresses. An empty list, the default, sets none, and instances use the Amazon Time Sync Service, which is also reachable at `169.254.169.123` and, on Nitro instances, `fd00:ec2::123`.

Type: `list(string)`

Default: `[]`

#### <a name="input_region"></a> [region](#input_region)

Description: The AWS Region to create the DHCP option set in, such as `us-west-2`. Defaults to the Region of the AWS provider passed to the module. The option set can be used only by VPCs in the same Region.

Type: `string`

Default: `null`

### Outputs

The following outputs are exported:

#### <a name="output_metadata"></a> [metadata](#output_metadata)

Description: Everything the module created, in one object, so that other configurations need only one reference:

- `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
- `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`.
- `vpc_dhcp_options` - The DHCP option set's `id` (pass it to `aws_vpc_dhcp_options_association` as `dhcp_options_id`), `arn`, `owner_id`, `region`, the options as AWS stores them (`domain_name`, `domain_name_servers`, `ntp_servers`, `netbios_name_servers`, `netbios_node_type`, `ipv6_address_preferred_lease_time`), `tags` and `tags_all`.
<!-- END_TF_DOCS -->

## License

This module is licensed under the [Apache License 2.0](https://github.com/AutomateTheCloud/terraform-aws-vpc_dhcp_options/blob/main/LICENSE). See [NOTICE](https://github.com/AutomateTheCloud/terraform-aws-vpc_dhcp_options/blob/main/NOTICE) for the copyright notice.

The Automate the Cloud name and logo are not covered by this license.

---

Maintained by [Automate the Cloud](https://automatethe.cloud), a Kentucky 501(c)(3) that teaches cloud infrastructure and helps nonprofits run theirs.
