# Production Environment Configuration

environment = "prod"
aws_region  = "us-east-1"

# Database configuration for production
db_instance_class       = "db.t3.medium"
db_allocated_storage    = 100
db_max_allocated_storage = 500

# Backend configuration for production
backend_image_tag     = "latest"
backend_cpu          = 1024
backend_memory       = 2048
backend_desired_count = 3

# Security configuration (restrict to your office/VPN IPs)
allowed_cidr_blocks = [
  "10.0.0.0/8",    # Private networks
  "172.16.0.0/12", # Private networks
  "192.168.0.0/16", # Private networks
  # Add your office/VPN IP ranges here:
  # "203.0.113.0/24"  # Example office IP range
]

# Domain configuration (update with your production domain)
domain_name = "your-domain.com" # Update with your actual production domain
