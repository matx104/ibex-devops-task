# modules/networking/variables.tf
variable "project_name" {
  description = "Name of the project"
  type        = string
  validation {
    condition     = length(var.project_name) > 0
    error_message = "Project name cannot be empty."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "allowed_ssh_ips" {
  description = "List of CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
  validation {
    condition     = length(var.allowed_ssh_ips) > 0
    error_message = "At least one IP range must be specified for SSH access."
  }
}

variable "additional_ingress_rules" {
  description = "Additional ingress rules for security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}
