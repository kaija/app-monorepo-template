# Terraform configuration file for backend state management

terraform {
  # Uncomment and configure the backend after creating your S3 bucket and DynamoDB table
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "line-commerce/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}

# Example backend configuration files for different environments
# Create these files when setting up remote state:

# backend-dev.hcl
# bucket         = "your-terraform-state-bucket"
# key            = "line-commerce/dev/terraform.tfstate"
# region         = "us-east-1"
# dynamodb_table = "terraform-state-lock"
# encrypt        = true

# backend-staging.hcl
# bucket         = "your-terraform-state-bucket"
# key            = "line-commerce/staging/terraform.tfstate"
# region         = "us-east-1"
# dynamodb_table = "terraform-state-lock"
# encrypt        = true

# backend-prod.hcl
# bucket         = "your-terraform-state-bucket"
# key            = "line-commerce/prod/terraform.tfstate"
# region         = "us-east-1"
# dynamodb_table = "terraform-state-lock"
# encrypt        = true