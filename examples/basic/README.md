# Basic option set

A DHCP option set with the private domain name `example.internal` and the Amazon DNS server, used by a new VPC. Instances in the VPC look up a short name such as `web` as `web.example.internal`. To make those names resolve, create a Route 53 private hosted zone for `example.internal` and associate it with the VPC.

The VPC has no subnets and no internet gateway, so nothing in it can be reached, and the example costs nothing to run.

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

### Outputs

The following outputs are exported:

#### <a name="output_dhcp_options"></a> [dhcp_options](#output_dhcp_options)

Description: ID and settings of the DHCP option set, and the VPC that uses it
<!-- END_TF_DOCS -->
