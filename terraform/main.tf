terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Create Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet"
    Type        = "Public"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Create Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name        = "${var.project_name}-private-subnet"
    Type        = "Private"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Create Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-nat-eip"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  depends_on = [aws_internet_gateway.main]
}

# Create NAT Gateway
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name        = "${var.project_name}-nat"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  depends_on = [aws_internet_gateway.main]
}

# Create Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Type        = "Public"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Create Route Table for Private Subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-private-rt"
    Type        = "Private"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Associate Public Subnet with Public Route Table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Associate Private Subnet with Private Route Table
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

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
  filename        = "${path.module}/keys/${var.project_name}-key.pem"
  file_permission = "0400"
}

# Security Group for EC2
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security group for EC2 instance"
  vpc_id      = aws_vpc.main.id  # Changed to use our VPC

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

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
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

# S3 Bucket for artifacts
resource "aws_s3_bucket" "artifacts" {
  bucket = var.s3_bucket_name

  tags = {
    Name        = "${var.project_name}-artifacts"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Block public access to S3 bucket
resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

# IAM Role for EC2 Instance
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-ec2-role"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# IAM Policy for S3 Access (Least Privilege)
resource "aws_iam_role_policy" "ec2_s3_policy" {
  name = "${var.project_name}-ec2-s3-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3BucketAccess"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*"
        ]
      },
      {
        Sid    = "S3ListBuckets"
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets"
        ]
        Resource = "*"
      }
    ]
  })
}

# Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# EC2 Instance in Public Subnet
resource "aws_instance" "docker_host" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  key_name              = aws_key_pair.ec2_key_pair.key_name
  subnet_id              = aws_subnet.public.id  # Deploy to public subnet
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  
  # User data script to install Docker
  user_data = base64encode(templatefile("${path.module}/scripts/user_data.sh", {
    s3_bucket = aws_s3_bucket.artifacts.id
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
    Subnet      = "Public"
  }

  # Create a provisioner to save instance details
  provisioner "local-exec" {
    command = "echo ${self.public_ip} > instance_ip.txt"
  }
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

 resource "aws_ec2_instance_state" "docker_host" {
   instance_id = aws_instance.docker_host.id
   state       = "stopped"
}

# Optional: Create IAM User with programmatic access
resource "aws_iam_user" "cicd_user" {
  count = var.create_iam_user ? 1 : 0
  name  = "${var.project_name}-cicd-user"

  tags = {
    Name        = "${var.project_name}-cicd-user"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_access_key" "cicd_user" {
  count = var.create_iam_user ? 1 : 0
  user  = aws_iam_user.cicd_user[0].name
}

# Least privilege policy for CI/CD user
resource "aws_iam_user_policy" "cicd_policy" {
  count = var.create_iam_user ? 1 : 0
  name  = "${var.project_name}-cicd-policy"
  user  = aws_iam_user.cicd_user[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2Management"
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "ec2:ResourceTag/ManagedBy" = "Terraform"
          }
        }
      },
      {
        Sid    = "S3Management"
        Effect = "Allow"
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      },
      {
        Sid    = "SecurityGroupManagement"
        Effect = "Allow"
        Action = [
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:DescribeSecurityGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

# Create a bastion host in public subnet for secure access to private resources
# Uncomment if you need a bastion/jump host
 resource "aws_instance" "bastion" {
   ami                    = data.aws_ami.amazon_linux_2.id
   instance_type          = "t2.micro"
   key_name              = aws_key_pair.ec2_key_pair.key_name
   subnet_id              = aws_subnet.public.id
   vpc_security_group_ids = [aws_security_group.bastion_sg.id]
   
   tags = {
     Name        = "${var.project_name}-bastion"
     Environment = var.environment
     ManagedBy   = "Terraform"
   }
 }

 resource "aws_ec2_instance_state" "bastion" {
   instance_id = aws_instance.bastion.id
   state       = "stopped"
}

# Security group for bastion host
 resource "aws_security_group" "bastion_sg" {
   name        = "${var.project_name}-bastion-sg"
   description = "Security group for bastion host"
   vpc_id      = aws_vpc.main.id

   ingress {
     description = "SSH from allowed IPs"
     from_port   = 22
     to_port     = 22
     protocol    = "tcp"
     cidr_blocks = var.allowed_ssh_ips
   }

   egress {
     description = "Allow all outbound"
     from_port   = 0
     to_port     = 0
     protocol    = "-1"
     cidr_blocks = ["0.0.0.0/0"]
   }

   tags = {
     Name        = "${var.project_name}-bastion-sg"
     Environment = var.environment
     ManagedBy   = "Terraform"
   }
 }
