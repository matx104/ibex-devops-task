# terraform/main.tf - Root module that orchestrates all components

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

# Networking Module
module "networking" {
  source = "./modules/networking"
  
  project_name      = var.project_name
  environment       = var.environment
  allowed_ssh_ips   = var.allowed_ssh_ips
}

# IAM Module
module "iam" {
  source = "./modules/iam"
  
  project_name     = var.project_name
  environment      = var.environment
  s3_bucket_arn    = module.storage.bucket_arn
  create_iam_user  = var.create_iam_user
}

# Storage Module
module "storage" {
  source = "./modules/storage"
  
  project_name    = var.project_name
  environment     = var.environment
  s3_bucket_name  = var.s3_bucket_name
}

# Compute Module
module "compute" {
  source = "./modules/compute"
  
  project_name           = var.project_name
  environment           = var.environment
  instance_type         = var.instance_type
  vpc_id               = module.networking.vpc_id
  subnet_id            = module.networking.subnet_id
  security_group_id    = module.networking.security_group_id
  iam_instance_profile = module.iam.instance_profile_name
  s3_bucket_id        = module.storage.bucket_id
  
  depends_on = [
    module.networking,
    module.iam,
    module.storage
  ]
}
