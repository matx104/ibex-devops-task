# variables.tf - Terraform Variables Configuration

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "ibex-devops-task-sept-2025"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

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

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for artifacts"
  type        = string
  default     = "" # Will be generated if empty
}

variable "create_iam_user" {
  description = "Whether to create an IAM user for CI/CD"
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
  default     = ""
  sensitive   = true
}

variable "public_key" {
  description = "The SSH public key"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "The CIDR block to allow SSH access from"
  type        = string
  default     = "0.0.0.0/0"
}
