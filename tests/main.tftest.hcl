# Runs without AWS credentials: `tofu test` (or `terraform test`).

mock_provider "aws" {
  override_data {
    target = data.aws_ssm_parameter.ami
    values = { value = "ami-0123456789abcdef0" }
  }
  override_resource {
    target = aws_iam_role.this
    values = { arn = "arn:aws:iam::111111111111:role/example-bastion" }
  }
  override_resource {
    target = aws_launch_template.this
    values = { id = "lt-0123456789abcdef0" }
  }
  override_resource {
    target = aws_iam_instance_profile.this
    values = { arn = "arn:aws:iam::111111111111:instance-profile/example-bastion" }
  }
}

variables {
  name       = "example-bastion"
  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
}

run "no_public_ip" {
  assert {
    condition     = aws_launch_template.this.network_interfaces[0].associate_public_ip_address == "false"
    error_message = "The bastion must not get a public IP."
  }
  assert {
    condition     = aws_launch_template.this.network_interfaces[0].security_groups == toset([aws_security_group.this.id])
    error_message = "The bastion must use only the module's security group."
  }
}

run "no_key_pair" {
  assert {
    condition     = aws_launch_template.this.key_name == null || aws_launch_template.this.key_name == ""
    error_message = "The bastion must not have an SSH key pair."
  }
}

run "sg_egress_only" {
  variables {
    egress_cidr_blocks = ["10.30.0.0/16", "10.40.0.0/16"]
  }
  assert {
    condition     = length(aws_security_group.this.ingress) == 0
    error_message = "The security group must have no ingress rules."
  }
  assert {
    condition     = aws_vpc_security_group_egress_rule.https.cidr_ipv4 == "0.0.0.0/0" && aws_vpc_security_group_egress_rule.https.from_port == 443 && aws_vpc_security_group_egress_rule.https.to_port == 443
    error_message = "The bastion needs 443 to 0.0.0.0/0 to reach SSM through NAT."
  }
  assert {
    condition     = toset([for r in aws_vpc_security_group_egress_rule.extra : r.cidr_ipv4]) == toset(["10.30.0.0/16", "10.40.0.0/16"])
    error_message = "Each egress_cidr_blocks entry must get its own egress rule."
  }
}

run "ssm_policy" {
  assert {
    condition     = aws_iam_role_policy_attachment.ssm.policy_arn == "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    error_message = "The instance role must have AmazonSSMManagedInstanceCore."
  }
  assert {
    condition     = aws_launch_template.this.iam_instance_profile[0].arn == aws_iam_instance_profile.this.arn
    error_message = "The launch template must use the module's instance profile."
  }
}

run "capacity" {
  variables {
    desired_capacity = 0
  }
  assert {
    condition     = output.autoscaling_group_min_size == 0 && output.autoscaling_group_max_size == 1 && output.autoscaling_group_desired_capacity == 0
    error_message = "The group must be min 0, max 1, desired from desired_capacity."
  }
}

run "capacity_too_big" {
  command = plan
  variables {
    desired_capacity = 2
  }
  expect_failures = [var.desired_capacity]
}

run "imdsv2" {
  assert {
    condition     = aws_launch_template.this.metadata_options[0].http_tokens == "required"
    error_message = "The bastion must require IMDSv2."
  }
}

run "ami_from_ssm" {
  variables {
    ami_ssm_parameter = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
  }
  assert {
    condition     = data.aws_ssm_parameter.ami.name == "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
    error_message = "The AMI must come from ami_ssm_parameter."
  }
  assert {
    condition     = aws_launch_template.this.image_id == "ami-0123456789abcdef0"
    error_message = "The launch template must use the AMI from SSM."
  }
}

run "start_session_command" {
  assert {
    condition     = strcontains(output.start_session_command, "--document-name AWS-StartPortForwardingSessionToRemoteHost") && strcontains(output.start_session_command, "portNumber=443")
    error_message = "start_session_command must show the port-forwarding command."
  }
}

run "egress_ports_default_all_protocols" {
  variables {
    egress_cidr_blocks = ["10.30.0.0/16", "10.40.0.0/16"]
  }
  assert {
    condition     = length(aws_vpc_security_group_egress_rule.extra) == 2 && alltrue([for r in aws_vpc_security_group_egress_rule.extra : r.ip_protocol == "-1"])
    error_message = "With egress_tcp_ports null, each CIDR must get one all-protocol rule."
  }
}

run "egress_ports_tcp_only" {
  variables {
    egress_cidr_blocks = ["10.30.0.0/16"]
    egress_tcp_ports   = [80, 443, 5432, 6379]
  }
  assert {
    condition     = length(aws_vpc_security_group_egress_rule.extra) == 4
    error_message = "Each pair of CIDR and port must get its own rule."
  }
  assert {
    condition     = alltrue([for r in aws_vpc_security_group_egress_rule.extra : r.ip_protocol == "tcp" && r.from_port == r.to_port && r.cidr_ipv4 == "10.30.0.0/16"])
    error_message = "Port rules must be TCP, one port each, to the given CIDR."
  }
  assert {
    condition     = toset([for r in aws_vpc_security_group_egress_rule.extra : r.from_port]) == toset([80, 443, 5432, 6379])
    error_message = "Every port in egress_tcp_ports must get a rule."
  }
}

run "egress_ports_invalid" {
  command = plan
  variables {
    egress_cidr_blocks = ["10.30.0.0/16"]
    egress_tcp_ports   = [0]
  }
  expect_failures = [var.egress_tcp_ports]
}
