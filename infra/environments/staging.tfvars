# Staging Environment Configuration

environment = "staging"
aws_region  = "us-east-1"

# Database configuration for staging
db_instance_class       = "db.t3.small"
db_allocated_storage    = 50
db_max_allocated_storage = 100

# Backend configuration for staging
backend_image_tag     = "staging"
backend_cpu          = 512
backend_memory       = 1024
backend_desired_count = 2

# Security configuration
allowed_cidr_blocks = [
  "10.0.0.0/8",    # Private networks
  "172.16.0.0/12", # Private networks
  "192.168.0.0/16" # Private networks
]

# Domain configuration (update with your staging domain)
domain_name = "staging.your-domain.com" # Update with your actual staging domain