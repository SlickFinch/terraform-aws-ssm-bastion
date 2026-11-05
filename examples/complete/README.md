# Complete example

Creates a VPC with NAT and a bastion that can reach `10.30.0.0/16`, for example a private EKS cluster VPC reached through a Transit Gateway.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.56 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_bastion"></a> [bastion](#module\_bastion) | ../.. | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | ~> 6.7 |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_start_session_command"></a> [start\_session\_command](#output\_start\_session\_command) | Port-forwarding command to fill in. |
<!-- END_TF_DOCS -->
