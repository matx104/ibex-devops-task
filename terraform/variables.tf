# variables.tf - Terraform Variables Configuration

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "ibex-devops-task-2025"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

# VPC and Networking Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

# EC2 Variables
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "allowed_ssh_ips" {
  description = "List of IP addresses allowed to SSH into EC2 instance"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Change to your IP for better security
}

# S3 Variables
variable "s3_bucket_name" {
  description = "Name of the S3 bucket for artifacts"
  type        = string
  default     = "ibex-devops-task-bucket-sept-2025"
}

# IAM Variables
variable "create_iam_user" {
  description = "Whether to create an IAM user for CI/CD"
  type        = bool
  default     = true
}

# Docker Variables
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
