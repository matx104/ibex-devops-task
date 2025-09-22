# modules/iam/main.tf
# IAM Resources - Roles, Policies, Users

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
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
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
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
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

# modules/iam/variables.tf
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket for permissions"
  type        = string
}

variable "create_iam_user" {
  description = "Whether to create IAM user for CI/CD"
  type        = bool
  default     = false
}

# modules/iam/outputs.tf
output "ec2_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = aws_iam_role.ec2_role.arn
}

output "instance_profile_name" {
  description = "Name of the instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "cicd_user_access_key" {
  description = "Access key for CI/CD user"
  value       = var.create_iam_user ? aws_iam_access_key.cicd_user[0].id : null
  sensitive   = true
}

output "cicd_user_secret_key" {
  description = "Secret key for CI/CD user"
  value       = var.create_iam_user ? aws_iam_access_key.cicd_user[0].secret : null
  sensitive   = true
}
