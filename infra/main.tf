# LINE Commerce Monorepo Infrastructure
# This Terraform configuration sets up production infrastructure for:
# - Frontend (Next.js) deployment to Vercel/AWS S3 + CloudFront
# - Backend (FastAPI) deployment to AWS ECS Fargate
# - Managed PostgreSQL database (AWS RDS)
# - Environment-specific configurations

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    vercel = {
      source  = "vercel/vercel"
      version = "~> 0.15"
    }
  }

  # Backend configuration for state management
  backend "s3" {
    # These values should be provided via backend config file or CLI
    # bucket = "your-terraform-state-bucket"
    # key    = "line-commerce/terraform.tfstate"
    # region = "us-east-1"
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "line-commerce"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Configure Vercel Provider (for frontend deployment)
provider "vercel" {
  # API token should be set via VERCEL_API_TOKEN environment variable
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# Local values for resource naming
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}