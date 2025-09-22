# modules/storage/main.tf
# S3 and Storage Resources

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

# Optional: S3 bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# modules/storage/variables.tf
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

# modules/storage/outputs.tf
output "bucket_id" {
  description = "ID of the S3 bucket"
  value       = aws_s3_bucket.artifacts.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.artifacts.arn
}

output "bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.artifacts.bucket_domain_name
}
