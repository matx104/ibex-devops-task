# outputs.tf - Terraform Output Values

output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.docker_host.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.docker_host.public_dns
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.artifacts.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.artifacts.arn
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.ec2_sg.id
}

output "ssh_private_key_path" {
  description = "Path to the SSH private key"
  value       = local_file.private_key.filename
}

output "iam_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = aws_iam_role.ec2_role.arn
}

output "iam_user_access_key" {
  description = "Access key ID for CI/CD user"
  value       = var.create_iam_user ? aws_iam_access_key.cicd_user[0].id : "N/A"
  sensitive   = true
}

output "iam_user_secret_key" {
  description = "Secret access key for CI/CD user"
  value       = var.create_iam_user ? aws_iam_access_key.cicd_user[0].secret : "N/A"
  sensitive   = true
}

output "application_url" {
  description = "URL to access the deployed application"
  value       = "http://${aws_instance.docker_host.public_ip}"
}

output "ssh_connection_command" {
  description = "Command to SSH into the EC2 instance"
  value       = "ssh -i ${local_file.private_key.filename} ec2-user@${aws_instance.docker_host.public_ip}"
}