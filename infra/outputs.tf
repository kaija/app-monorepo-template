# Outputs for LINE Commerce Infrastructure

# Database outputs
output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.postgres.endpoint
  sensitive   = true
}

output "database_port" {
  description = "RDS instance port"
  value       = aws_db_instance.postgres.port
}

output "database_name" {
  description = "Database name"
  value       = aws_db_instance.postgres.db_name
}

# Backend outputs
output "backend_load_balancer_dns" {
  description = "Load balancer DNS name for backend API"
  value       = aws_lb.backend.dns_name
}

output "backend_load_balancer_zone_id" {
  description = "Load balancer zone ID for backend API"
  value       = aws_lb.backend.zone_id
}

output "backend_api_url" {
  description = "Backend API URL"
  value       = "https://${aws_lb.backend.dns_name}"
}

# Frontend outputs
output "frontend_url" {
  description = "Frontend application URL"
  value       = vercel_deployment.frontend.url
}

output "frontend_domain" {
  description = "Frontend custom domain (if configured)"
  value       = var.domain_name != "" ? vercel_project_domain.custom[0].domain : ""
}

# ECR Repository
output "ecr_repository_url" {
  description = "ECR repository URL for backend images"
  value       = aws_ecr_repository.backend.repository_url
}

# VPC outputs
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

# Security Group outputs
output "backend_security_group_id" {
  description = "Backend security group ID"
  value       = aws_security_group.backend.id
}

output "database_security_group_id" {
  description = "Database security group ID"
  value       = aws_security_group.database.id
}

# Environment-specific outputs
output "environment_config" {
  description = "Current environment configuration"
  value = {
    environment           = var.environment
    db_instance_class     = local.env_config.db_instance_class
    backend_desired_count = local.env_config.backend_desired_count
    backend_cpu           = local.env_config.backend_cpu
    backend_memory        = local.env_config.backend_memory
  }
}
