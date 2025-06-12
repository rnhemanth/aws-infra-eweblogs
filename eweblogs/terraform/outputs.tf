# EC2 Instance Outputs
output "ec2_instance_ids" {
  description = "IDs of the EC2 instances"
  value       = { for k, v in module.ec2 : k => v.id }
}

output "ec2_instance_private_ips" {
  description = "Private IP addresses of the EC2 instances"
  value       = { for k, v in module.ec2 : k => v.private_ip }
}

output "ec2_instance_names" {
  description = "Names of the EC2 instances"
  value       = { for k, v in var.servers : k => "${upper(var.ec2_name_prefix)}${upper(var.region_prefix)}${upper(local.instance_service_name)}${upper(v.name)}" }
}

# KMS Key Outputs
output "kms_key_id" {
  description = "The globally unique identifier for the key"
  value       = module.kms.key_id
}

output "kms_key_arn" {
  description = "The Amazon Resource Name (ARN) of the key"
  value       = module.kms.key_arn
}

# IAM Role Outputs
output "ec2_iam_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = aws_iam_role.ec2_role.arn
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}

# Resource Group Output
output "resource_group_arn" {
  description = "ARN of the EWebLogs resource group"
  value       = aws_resourcegroups_group.web.arn
}