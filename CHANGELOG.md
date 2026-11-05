# Changelog

## v1.0.0

- First release. Creates an SSM port-forwarding bastion: an Auto Scaling group of 0 or 1 from `terraform-aws-modules/autoscaling/aws`, a launch template with no public IP, no key pair and IMDSv2, an instance role with `AmazonSSMManagedInstanceCore`, and an egress-only security group.
- Needs AWS provider 6.56 or later, because the autoscaling module does.
