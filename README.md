# terraform-aws-ssm-bastion

OpenTofu and Terraform module that creates an AWS Systems Manager port-forwarding bastion. People reach private endpoints, such as a private EKS API, through Session Manager. Nobody logs into the instance, and it has no inbound access.

## Usage

Pin the module to a release tag:

```hcl
module "bastion" {
  source = "git::https://github.com/SlickFinch/terraform-aws-ssm-bastion.git?ref=v1.0.0"

  name               = "acme-bastion"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnets
  egress_cidr_blocks = ["10.30.0.0/16"]
}
```

See [examples/complete](examples/complete).

## Reach a private EKS cluster

You need the AWS CLI and the Session Manager plugin.

1. Find the instance: `aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names acme-bastion --query 'AutoScalingGroups[0].Instances[0].InstanceId'`.
2. Find the endpoint host: `aws eks describe-cluster --name <cluster> --query cluster.endpoint`, without `https://`.
3. Start the tunnel and leave it open:

   ```bash
   aws ssm start-session --target <instance-id> \
     --document-name AWS-StartPortForwardingSessionToRemoteHost \
     --parameters host=<host>,portNumber=443,localPortNumber=8443
   ```

4. In another terminal, point `kubectl` at the tunnel. Keep the real host name for TLS:

   ```bash
   aws eks update-kubeconfig --name <cluster>
   kubectl config set-cluster <cluster-arn> --server=https://<host>:8443
   echo "127.0.0.1 <host>" | sudo tee -a /etc/hosts
   ```

5. Remove the `/etc/hosts` line when you are done.

The cluster security group must allow 443 from the bastion's subnets or security group.

## How it behaves

- **Closed by default.** No public IP, no key pair, no ingress rules. IMDSv2 is required.
- **Egress.** Port 443 to `0.0.0.0/0` is always open, so the agent reaches Systems Manager through NAT. Each `egress_cidr_blocks` entry gets its own rule for any port.
- **Cost.** Set `desired_capacity = 0` to stop the instance when nobody needs it. The group never grows past 1.
- **Updates.** A new AMI in `ami_ssm_parameter` changes the launch template at the next apply, and an instance refresh replaces the instance.
- **Architecture.** The default is Graviton (`t4g.nano`, arm64 AMI). If you change `instance_type` to x86, change `ami_ssm_parameter` too.

## Testing

```bash
mise install
tofu test            # mocked provider, no AWS credentials needed
pre-commit run --all-files
```

## Versioning

Releases follow [semantic versioning](https://semver.org). Each release is a `vMAJOR.MINOR.PATCH` git tag with a GitHub release. [CHANGELOG.md](CHANGELOG.md) lists the changes in each release.

- **Patch:** bug fixes. No change to inputs, outputs or resources.
- **Minor:** new inputs or outputs with safe defaults.
- **Major:** anything that makes callers change code, raises a provider floor, or replaces resources.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.56 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.56 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_autoscaling"></a> [autoscaling](#module\_autoscaling) | terraform-aws-modules/autoscaling/aws | 9.3.2 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_instance_profile.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_launch_template.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.extra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_ssm_parameter.ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_name"></a> [name](#input\_name) | Name for the Auto Scaling group, launch template, role and security group. | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Private subnets for the bastion. They need NAT or SSM VPC endpoints to reach Systems Manager. | `list(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC the bastion runs in. | `string` | n/a | yes |
| <a name="input_ami_ssm_parameter"></a> [ami\_ssm\_parameter](#input\_ami\_ssm\_parameter) | SSM public parameter that holds the AMI ID. | `string` | `"/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"` | no |
| <a name="input_desired_capacity"></a> [desired\_capacity](#input\_desired\_capacity) | Number of bastion instances: 1 when in use, 0 to stop paying for it. | `number` | `1` | no |
| <a name="input_egress_cidr_blocks"></a> [egress\_cidr\_blocks](#input\_egress\_cidr\_blocks) | Extra IPv4 CIDRs the bastion may reach on any port, for example private cluster VPCs. Port 443 to the internet is always open for SSM. | `list(string)` | `[]` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type. It must match the AMI architecture. | `string` | `"t4g.nano"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for every taggable resource. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_autoscaling_group_desired_capacity"></a> [autoscaling\_group\_desired\_capacity](#output\_autoscaling\_group\_desired\_capacity) | Desired capacity of the Auto Scaling group. |
| <a name="output_autoscaling_group_max_size"></a> [autoscaling\_group\_max\_size](#output\_autoscaling\_group\_max\_size) | Maximum size of the Auto Scaling group. |
| <a name="output_autoscaling_group_min_size"></a> [autoscaling\_group\_min\_size](#output\_autoscaling\_group\_min\_size) | Minimum size of the Auto Scaling group. |
| <a name="output_autoscaling_group_name"></a> [autoscaling\_group\_name](#output\_autoscaling\_group\_name) | Name of the Auto Scaling group. |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of the bastion instance role. |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the bastion security group. Allow it on the target's security group. |
| <a name="output_start_session_command"></a> [start\_session\_command](#output\_start\_session\_command) | Example port-forwarding command. Replace the placeholders, then use https://localhost:8443. |
<!-- END_TF_DOCS -->
