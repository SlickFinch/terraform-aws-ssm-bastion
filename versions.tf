terraform {
  required_version = ">= 1.8.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # terraform-aws-modules/autoscaling 9.3 needs 6.56 or later.
      version = ">= 6.56"
    }
  }
}
