variable "name" {
  description = "Name for the Auto Scaling group, launch template, role and security group."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9_-]{1,50}$", var.name))
    error_message = "name must be 2 to 51 letters, digits, hyphens or underscores."
  }
}

variable "vpc_id" {
  description = "VPC the bastion runs in."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets for the bastion. They need NAT or SSM VPC endpoints to reach Systems Manager."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "subnet_ids must name at least one subnet."
  }
}

variable "instance_type" {
  description = "EC2 instance type. It must match the AMI architecture."
  type        = string
  default     = "t4g.nano"
}

variable "ami_ssm_parameter" {
  description = "SSM public parameter that holds the AMI ID."
  type        = string
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

variable "desired_capacity" {
  description = "Number of bastion instances: 1 when in use, 0 to stop paying for it."
  type        = number
  default     = 1

  validation {
    condition     = contains([0, 1], var.desired_capacity)
    error_message = "desired_capacity must be 0 or 1."
  }
}

variable "egress_cidr_blocks" {
  description = "Extra IPv4 CIDRs the bastion may reach on any port, for example private cluster VPCs. Port 443 to the internet is always open for SSM."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags for every taggable resource."
  type        = map(string)
  default     = {}
}
