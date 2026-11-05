data "aws_ssm_parameter" "ami" {
  name = var.ami_ssm_parameter
}

resource "aws_launch_template" "this" {
  name_prefix = "${var.name}-"
  description = "SSM bastion ${var.name}: no public IP, no key pair"
  image_id    = data.aws_ssm_parameter.ami.value

  instance_type          = var.instance_type
  update_default_version = true

  iam_instance_profile {
    arn = aws_iam_instance_profile.this.arn
  }

  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true
    security_groups             = [aws_security_group.this.id]
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = var.name })
  }

  tags = var.tags
}

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "9.3.2"

  name            = var.name
  use_name_prefix = false

  create_launch_template  = false
  launch_template_id      = aws_launch_template.this.id
  launch_template_version = "$Latest"

  vpc_zone_identifier = var.subnet_ids
  min_size            = 0
  max_size            = 1
  desired_capacity    = var.desired_capacity
  health_check_type   = "EC2"

  # Replace the instance when the launch template changes, for example a new AMI.
  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage = 0
    }
  }

  create_iam_instance_profile = false

  tags = var.tags
}
