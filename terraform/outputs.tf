# outputs.tf - Terraform Outputs Configuration

# VPC and Networking Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = aws_subnet.private.id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.main.id
}

# EC2 Instance Outputs
output "docker_host_instance_id" {
  description = "ID of the Docker host EC2 instance"
  value       = aws_instance.docker_host.id
}

output "docker_host_public_ip" {
  description = "Public IP address of the Docker host"
  value       = aws_instance.docker_host.public_ip
}

output "docker_host_private_ip" {
  description = "Private IP address of the Docker host"
  value       = aws_instance.docker_host.private_ip
}

output "docker_host_public_dns" {
  description = "Public DNS name of the Docker host"
  value       = aws_instance.docker_host.public_dns
}

output "bastion_instance_id" {
  description = "ID of the bastion host EC2 instance"
  value       = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "bastion_private_ip" {
  description = "Private IP address of the bastion host"
  value       = aws_instance.bastion.private_ip
}

# Security Group Outputs
output "ec2_security_group_id" {
  description = "ID of the EC2 security group"
  value       = aws_security_group.ec2_sg.id
}

output "bastion_security_group_id" {
  description = "ID of the bastion security group"
  value       = aws_security_group.bastion_sg.id
}

# S3 Bucket Outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.artifacts.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.artifacts.arn
}

output "s3_bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.artifacts.bucket_domain_name
}

# SSH Key Outputs
output "ssh_key_name" {
  description = "Name of the SSH key pair"
  value       = aws_key_pair.ec2_key_pair.key_name
}

output "ssh_private_key_path" {
  description = "Path to the private SSH key file"
  value       = local_file.private_key.filename
  sensitive   = true
}

# IAM Outputs
output "ec2_iam_role_name" {
  description = "Name of the EC2 IAM role"
  value       = aws_iam_role.ec2_role.name
}

output "ec2_iam_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = aws_iam_role.ec2_role.arn
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}

# IAM User Outputs (conditional)
output "cicd_user_name" {
  description = "Name of the CI/CD IAM user"
  value       = var.create_iam_user ? aws_iam_user.cicd_user[0].name : null
}

output "cicd_user_arn" {
  description = "ARN of the CI/CD IAM user"
  value       = var.create_iam_user ? aws_iam_user.cicd_user[0].arn : null
}

output "cicd_access_key_id" {
  description = "Access key ID for the CI/CD user"
  value       = var.create_iam_user ? aws_iam_access_key.cicd_user[0].id : null
  sensitive   = true
}

output "cicd_secret_access_key" {
  description = "Secret access key for the CI/CD user"
  value       = var.create_iam_user ? aws_iam_access_key.cicd_user[0].secret : null
  sensitive   = true
}

# Connection Information
output "ssh_connection_command" {
  description = "Command to SSH into the Docker host"
  value       = "ssh -i ${local_file.private_key.filename} ec2-user@${aws_instance.docker_host.public_ip}"
}

output "bastion_ssh_command" {
  description = "Command to SSH into the bastion host"
  value       = "ssh -i ${local_file.private_key.filename} ec2-user@${aws_instance.bastion.public_ip}"
}

# Web Application URLs
output "application_url_http" {
  description = "HTTP URL to access the application"
  value       = "http://${aws_instance.docker_host.public_ip}"
}

output "application_url_https" {
  description = "HTTPS URL to access the application"
  value       = "https://${aws_instance.docker_host.public_ip}"
}

# Resource Summary
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    project_name    = var.project_name
    environment     = var.environment
    region          = var.aws_region
    vpc_id          = aws_vpc.main.id
    docker_host_ip  = aws_instance.docker_host.public_ip
    bastion_ip      = aws_instance.bastion.public_ip
    s3_bucket       = aws_s3_bucket.artifacts.id
    key_pair        = aws_key_pair.ec2_key_pair.key_name
  }
}
