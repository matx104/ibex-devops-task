# variables.tf - Terraform Variables Configuration

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Ibex-DevOps-Project-Sept-2025"
  type        = string
  default     = "ibex-devops-project"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for artifacts"
  type        = string
  default     = "" 
}

variable "allowed_ssh_ips" {
  description = "List of IPs allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "create_iam_user" {
  description = "Whether to create IAM user for CI/CD"
  type        = bool
  default     = true
}

variable "docker_image" {
  description = "Docker image to deploy"
  type        = string
  default     = "nginx:latest"
}

variable "docker_hub_username" {
  description = "Docker Hub username"
  type        = string
  default     = "monarchxmat"
  sensitive   = true
}
