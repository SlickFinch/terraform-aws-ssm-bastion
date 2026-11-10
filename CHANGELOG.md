# Changelog

## v1.1.0

- Add `egress_tcp_ports`. When set, the bastion may reach `egress_cidr_blocks` only on those TCP ports, with one rule per pair of CIDR and port. The default, `null`, keeps the v1.0.0 rule that allows every protocol, so existing callers see no change.

## v1.0.0

- First release. Creates an SSM port-forwarding bastion: an Auto Scaling group of 0 or 1 from `terraform-aws-modules/autoscaling/aws`, a launch template with no public IP, no key pair and IMDSv2, an instance role with `AmazonSSMManagedInstanceCore`, and an egress-only security group.
- Needs AWS provider 6.56 or later, because the autoscaling module does.
