# modules/iam/outputs.tf
output "ec2_role_name" {
  description = "Name of the EC2 IAM role"
  value       = aws_iam_role.ec2_role.name
}

output "ec2_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = aws_iam_role.ec2_role.arn
}

output "instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "instance_profile_arn" {
  description = "ARN of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_profile.arn
}

output "cicd_user_name" {
  description = "Name of the CI/CD IAM user (if created)"
  value       = var.create_iam_user ? aws_iam_user.cicd_user[0].name : null
}

output "cicd_user_arn" {
  description = "ARN of the CI/CD IAM user (if created)"
  value       = var.create_iam_user ? aws_iam_user.cicd_user[0].arn : null
}

output "cicd_user_access_key" {
  description = "Access key ID for CI/CD user (if created)"
  value       = var.create_iam_user ? aws_iam_access_key.cicd_user[0].id : null
  sensitive   = true
}

output "cicd_user_secret_key" {
  description = "Secret access key for CI/CD user (if created)"
  value       = var.create_iam_user ? aws_iam_access_key.cicd_user[0].secret : null
  sensitive   = true
}
