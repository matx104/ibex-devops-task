# terraform/outputs.tf - Root module outputs
output "application_url" {
  description = "URL to access the application"
  value       = module.compute.application_url
}

output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.compute.instance_public_ip
}

output "ec2_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = module.compute.instance_public_dns
}

output "ssh_connection_command" {
  description = "SSH command to connect to the instance"
  value       = module.compute.ssh_connection_command
}

output "ssh_private_key_path" {
  description = "Path to SSH private key"
  value       = module.compute.ssh_private_key_path
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.storage.bucket_id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.storage.bucket_arn
}

output "iam_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = module.iam.ec2_role_arn
}

output "security_group_id" {
  description = "ID of the security group"
  value       = module.networking.security_group_id
}

output "iam_user_access_key" {
  description = "Access key for CI/CD user"
  value       = module.iam.cicd_user_access_key
  sensitive   = true
}

output "iam_user_secret_key" {
  description = "Secret key for CI/CD user"
  value       = module.iam.cicd_user_secret_key
  sensitive   = true
}
