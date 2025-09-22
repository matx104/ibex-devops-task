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
  description = "Name of the S3 bucket - must be globally unique"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9\\-]*[a-z0-9]$", var.s3_bucket_name))
    error_message = "S3 bucket name must be lowercase, start and end with alphanumeric characters."
  }
}

variable "enable_versioning" {
  description = "Enable versioning on S3 bucket"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Enable server-side encryption on S3 bucket"
  type        = bool
  default     = true
}
