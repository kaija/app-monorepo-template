# Variables for LINE Commerce Infrastructure

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "line-commerce"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

# Database Configuration
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "RDS maximum allocated storage in GB"
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "linecommerce"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "postgres"
}

# Backend Configuration
variable "backend_image_tag" {
  description = "Docker image tag for backend deployment"
  type        = string
  default     = "latest"
}

variable "backend_cpu" {
  description = "CPU units for backend container (1024 = 1 vCPU)"
  type        = number
  default     = 512
}

variable "backend_memory" {
  description = "Memory for backend container in MB"
  type        = number
  default     = 1024
}

variable "backend_desired_count" {
  description = "Desired number of backend tasks"
  type        = number
  default     = 2
}

# Frontend Configuration
variable "domain_name" {
  description = "Custom domain name for frontend (optional)"
  type        = string
  default     = ""
}

# Security Configuration
variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the database"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

# Environment-specific configurations
variable "environment_configs" {
  description = "Environment-specific configuration overrides"
  type = map(object({
    db_instance_class     = string
    backend_desired_count = number
    backend_cpu           = number
    backend_memory        = number
  }))
  default = {
    dev = {
      db_instance_class     = "db.t3.micro"
      backend_desired_count = 1
      backend_cpu           = 256
      backend_memory        = 512
    }
    staging = {
      db_instance_class     = "db.t3.small"
      backend_desired_count = 2
      backend_cpu           = 512
      backend_memory        = 1024
    }
    prod = {
      db_instance_class     = "db.t3.medium"
      backend_desired_count = 3
      backend_cpu           = 1024
      backend_memory        = 2048
    }
  }
}
