# Development Environment Configuration

environment = "dev"
aws_region  = "us-east-1"

# Database configuration for development
db_instance_class       = "db.t3.micro"
db_allocated_storage    = 20
db_max_allocated_storage = 50

# Backend configuration for development
backend_image_tag     = "dev"
backend_cpu          = 256
backend_memory       = 512
backend_desired_count = 1

# Security configuration
allowed_cidr_blocks = [
  "10.0.0.0/8",    # Private networks
  "172.16.0.0/12", # Private networks
  "192.168.0.0/16" # Private networks
]

# Domain configuration (optional)
domain_name = "" # Leave empty for default ALB domain
