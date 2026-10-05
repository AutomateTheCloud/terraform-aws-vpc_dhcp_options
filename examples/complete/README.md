# Complete

Every option of the module, for a VPC whose Windows and Linux instances join a Microsoft Active Directory domain, `corp.example.internal`:

- The directory's domain controllers are the DNS servers and the NetBIOS name servers, with NetBIOS node type 2 (point-to-point), the one AWS recommends.
- Instances get the time from the Amazon Time Sync Service, over IPv4 and, on Nitro instances, IPv6.
- Leases for instances' IPv6 addresses last a day, instead of 140 seconds.
- `purpose_abbr` and `environment_abbr` shorten the `Name` tag to `example-dir_dhcp-prd-use1`, and a `CostCenter` tag is added.

The domain controllers' addresses, `10.0.0.10` and `10.0.1.10`, are placeholders: set `domain_controllers` to your own. They must be reachable from the VPC, and should forward names they do not hold to the Amazon DNS server. The VPC in the example has no subnets and no internet gateway, so nothing runs in it, and the example costs nothing to run.

With AWS Directory Service, pass the directory's addresses directly: `domain_name_servers = aws_directory_service_directory.this.dns_ip_addresses`. The module plans even though those addresses are known only after the directory is created.

## Run it

```shell
terraform init
terraform apply
```

Remove it with `terraform destroy`.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Optional Inputs

The following input variables are optional (have default values):

#### <a name="input_domain_controllers"></a> [domain_controllers](#input_domain_controllers)

Description: IPv4 addresses of the Active Directory domain controllers

Type: `list(string)`

Default:

```json
[
  "10.0.0.10",
  "10.0.1.10"
]
```

### Outputs

The following outputs are exported:

#### <a name="output_dhcp_options"></a> [dhcp_options](#output_dhcp_options)

Description: The DHCP option set, as AWS stores it, and the VPC that uses it
<!-- END_TF_DOCS -->
