# A bastion in private subnets with NAT that can reach a private cluster VPC.

provider "aws" {
  region = "us-west-2"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.7"

  name               = "example-bastion"
  cidr               = "10.20.0.0/16"
  azs                = ["us-west-2a", "us-west-2b"]
  private_subnets    = ["10.20.0.0/20", "10.20.16.0/20"]
  public_subnets     = ["10.20.240.0/24", "10.20.241.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true
}

module "bastion" {
  source = "../.."

  name               = "example-bastion"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnets
  egress_cidr_blocks = ["10.30.0.0/16"]
  egress_tcp_ports   = [443, 5432]
}

output "start_session_command" {
  description = "Port-forwarding command to fill in."
  value       = module.bastion.start_session_command
}
