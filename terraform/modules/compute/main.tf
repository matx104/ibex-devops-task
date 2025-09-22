# modules/compute/main.tf
# EC2 Compute Resources

# Generate SSH Key Pair
resource "tls_private_key" "ec2_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.ec2_ssh_key.public_key_openssh

  tags = {
    Name        = "${var.project_name}-keypair"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Store private key locally
resource "local_file" "private_key" {
  content         = tls_private_key.ec2_ssh_key.private_key_pem
  filename        = "${path.root}/keys/${var.project_name}-key.pem"
  file_permission = "0400"
}

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Instance
resource "aws_instance" "docker_host" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  key_name              = aws_key_pair.ec2_key_pair.key_name
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = var.iam_instance_profile
  subnet_id             = var.subnet_id
  
  # User data script to install Docker
  user_data = base64encode(templatefile("${path.module}/scripts/user_data.sh", {
    s3_bucket = var.s3_bucket_id
  }))

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name        = "${var.project_name}-docker-host"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  # Create a provisioner to save instance details
  provisioner "local-exec" {
    command = "echo ${self.public_ip} > ${path.root}/instance_ip.txt"
  }
}

# modules/compute/variables.tf
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the instance"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for the instance"
  type        = string
}

variable "iam_instance_profile" {
  description = "IAM instance profile name"
  type        = string
}

variable "s3_bucket_id" {
  description = "S3 bucket ID for user data script"
  type        = string
}

# modules/compute/outputs.tf
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.docker_host.id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.docker_host.public_ip
}

output "instance_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.docker_host.public_dns
}

output "ssh_private_key_path" {
  description = "Path to the SSH private key"
  value       = local_file.private_key.filename
}

output "ssh_connection_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${local_file.private_key.filename} ec2-user@${aws_instance.docker_host.public_ip}"
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_instance.docker_host.public_ip}"
}
