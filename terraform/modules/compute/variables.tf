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
  validation {
    condition     = contains(["t2.micro", "t2.small", "t2.medium", "t3.micro", "t3.small", "t3.medium"], var.instance_type)
    error_message = "Instance type must be a valid t2 or t3 instance type."
  }
}

variable "vpc_id" {
  description = "VPC ID where the instance will be launched"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be launched"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID to attach to the instance"
  type        = string
}

variable "iam_instance_profile" {
  description = "Name of the IAM instance profile to attach"
  type        = string
}

variable "s3_bucket_id" {
  description = "S3 bucket ID for user data script"
  type        = string
}

variable "key_algorithm" {
  description = "Algorithm for SSH key generation"
  type        = string
  default     = "RSA"
}

variable "key_rsa_bits" {
  description = "RSA key size in bits"
  type        = number
  default     = 4096
  validation {
    condition     = contains([2048, 4096], var.key_rsa_bits)
    error_message = "RSA key size must be either 2048 or 4096 bits."
  }
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Type of root volume"
  type        = string
  default     = "gp3"
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring for EC2 instance"
  type        = bool
  default     = false
}
