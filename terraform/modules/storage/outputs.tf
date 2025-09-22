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
  description = "Bucket domain name"
  value       = aws_s3_bucket.artifacts.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Bucket regional domain name"
  value       = aws_s3_bucket.artifacts.bucket_regional_domain_name
}
