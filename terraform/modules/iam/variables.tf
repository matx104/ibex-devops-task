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
  description = "ARN of the S3 bucket for IAM policy permissions"
  type        = string
}

variable "create_iam_user" {
  description = "Whether to create IAM user for CI/CD purposes"
  type        = bool
  default     = false
}

variable "additional_ec2_permissions" {
  description = "Additional permissions for EC2 role"
  type = list(object({
    sid       = string
    effect    = string
    actions   = list(string)
    resources = list(string)
  }))
  default = []
}
