# ==============================================================================
# Author: Mazen Monib
# Project: Advanced Database Architecture - Master's Research
# Component: Terraform Engine & AWS Provider Configuration (v6.x baseline)
# ==============================================================================

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # Updated to match your exact local v6.49.0 infrastructure baseline
      version = "~> 6.0" 
    }
  }

  # Remote State Management via AWS S3
  backend "s3" {
    bucket = "advanced-db-project"
    key    = "infrastructure/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region

  # Global Tagging Strategy for tracking and resource ownership
  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Project     = "Distributed-Systems-Research"
      Owner       = "Mazen Monib"
    }
  }
}