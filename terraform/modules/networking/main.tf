# modules/networking/main.tf
# VPC and Networking Resources

# VPC Data Source (using default VPC for simplicity)
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Group for EC2
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security group for EC2 instance"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from allowed IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_ips
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-ec2-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# modules/networking/variables.tf
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "allowed_ssh_ips" {
  description = "List of IPs allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# modules/networking/outputs.tf
output "vpc_id" {
  description = "ID of the VPC"
  value       = data.aws_vpc.default.id
}

output "subnet_id" {
  description = "ID of the first subnet"
  value       = tolist(data.aws_subnets.default.ids)[0]
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.ec2_sg.id
}

output "all_subnet_ids" {
  description = "All subnet IDs"
  value       = data.aws_subnets.default.ids
}
