output "autoscaling_group_name" {
  description = "Name of the Auto Scaling group."
  value       = module.autoscaling.autoscaling_group_name
}

output "autoscaling_group_min_size" {
  description = "Minimum size of the Auto Scaling group."
  value       = module.autoscaling.autoscaling_group_min_size
}

output "autoscaling_group_max_size" {
  description = "Maximum size of the Auto Scaling group."
  value       = module.autoscaling.autoscaling_group_max_size
}

output "autoscaling_group_desired_capacity" {
  description = "Desired capacity of the Auto Scaling group."
  value       = module.autoscaling.autoscaling_group_desired_capacity
}

output "role_arn" {
  description = "ARN of the bastion instance role."
  value       = aws_iam_role.this.arn
}

output "security_group_id" {
  description = "ID of the bastion security group. Allow it on the target's security group."
  value       = aws_security_group.this.id
}

output "start_session_command" {
  description = "Example port-forwarding command. Replace the placeholders, then use https://localhost:8443."
  value       = "aws ssm start-session --target <instance-id> --document-name AWS-StartPortForwardingSessionToRemoteHost --parameters host=<host>,portNumber=443,localPortNumber=8443"
}
