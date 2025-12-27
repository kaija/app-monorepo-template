# LINE Commerce Infrastructure Makefile

.PHONY: help setup init plan apply destroy output validate fmt clean

# Default environment
ENV ?= dev

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "LINE Commerce Infrastructure Management"
	@echo ""
	@echo "Usage: make <target> [ENV=<environment>]"
	@echo ""
	@echo "Environments:"
	@echo "  dev      - Development (default)"
	@echo "  staging  - Staging"
	@echo "  prod     - Production"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(BLUE)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "Examples:"
	@echo "  make plan ENV=dev"
	@echo "  make apply ENV=staging"
	@echo "  make output ENV=prod"

setup: ## Setup Terraform remote state backend
	@echo "$(BLUE)[INFO]$(NC) Setting up Terraform remote state backend..."
	@./scripts/setup-state-backend.sh

init: ## Initialize Terraform for the specified environment
	@echo "$(BLUE)[INFO]$(NC) Initializing Terraform for $(ENV) environment..."
	@if [ ! -f "backend-$(ENV).hcl" ]; then \
		echo "$(RED)[ERROR]$(NC) Backend configuration file backend-$(ENV).hcl not found"; \
		echo "$(YELLOW)[INFO]$(NC) Run 'make setup' first to create backend configuration"; \
		exit 1; \
	fi
	@terraform init -backend-config=backend-$(ENV).hcl -reconfigure

validate: ## Validate Terraform configuration
	@echo "$(BLUE)[INFO]$(NC) Validating Terraform configuration..."
	@terraform validate

fmt: ## Format Terraform configuration files
	@echo "$(BLUE)[INFO]$(NC) Formatting Terraform configuration files..."
	@terraform fmt -recursive

plan: init validate ## Plan Terraform deployment
	@echo "$(BLUE)[INFO]$(NC) Planning Terraform deployment for $(ENV) environment..."
	@if [ ! -f "environments/$(ENV).tfvars" ]; then \
		echo "$(RED)[ERROR]$(NC) Environment file environments/$(ENV).tfvars not found"; \
		exit 1; \
	fi
	@terraform workspace select $(ENV) || terraform workspace new $(ENV)
	@terraform plan -var-file=environments/$(ENV).tfvars -out=terraform-$(ENV).tfplan

apply: ## Apply Terraform configuration
	@echo "$(BLUE)[INFO]$(NC) Applying Terraform configuration for $(ENV) environment..."
	@if [ -f "terraform-$(ENV).tfplan" ]; then \
		terraform apply terraform-$(ENV).tfplan; \
	else \
		echo "$(YELLOW)[WARNING]$(NC) No plan file found. Running plan first..."; \
		$(MAKE) plan ENV=$(ENV); \
		terraform apply terraform-$(ENV).tfplan; \
	fi
	@echo "$(GREEN)[SUCCESS]$(NC) Deployment completed for $(ENV) environment"

destroy: ## Destroy infrastructure (use with caution)
	@echo "$(RED)[WARNING]$(NC) This will destroy all infrastructure for $(ENV) environment!"
	@read -p "Are you sure? Type 'yes' to continue: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		terraform workspace select $(ENV); \
		terraform destroy -var-file=environments/$(ENV).tfvars; \
	else \
		echo "$(BLUE)[INFO]$(NC) Destroy cancelled"; \
	fi

output: ## Show Terraform outputs
	@echo "$(BLUE)[INFO]$(NC) Showing Terraform outputs for $(ENV) environment..."
	@terraform workspace select $(ENV) 2>/dev/null || (echo "$(RED)[ERROR]$(NC) Workspace $(ENV) not found" && exit 1)
	@terraform output

clean: ## Clean up temporary files
	@echo "$(BLUE)[INFO]$(NC) Cleaning up temporary files..."
	@rm -f terraform-*.tfplan
	@rm -f .terraform.lock.hcl
	@echo "$(GREEN)[SUCCESS]$(NC) Cleanup completed"

# Environment-specific shortcuts
dev-plan: ## Plan development environment
	@$(MAKE) plan ENV=dev

dev-apply: ## Apply development environment
	@$(MAKE) apply ENV=dev

dev-destroy: ## Destroy development environment
	@$(MAKE) destroy ENV=dev

staging-plan: ## Plan staging environment
	@$(MAKE) plan ENV=staging

staging-apply: ## Apply staging environment
	@$(MAKE) apply ENV=staging

staging-destroy: ## Destroy staging environment
	@$(MAKE) destroy ENV=staging

prod-plan: ## Plan production environment
	@$(MAKE) plan ENV=prod

prod-apply: ## Apply production environment
	@$(MAKE) apply ENV=prod

prod-destroy: ## Destroy production environment
	@$(MAKE) destroy ENV=prod

# Docker and deployment helpers
build-backend: ## Build backend Docker image
	@echo "$(BLUE)[INFO]$(NC) Building backend Docker image..."
	@cd ../backend && docker build -t line-commerce-backend:$(ENV) .

push-backend: ## Push backend Docker image to ECR
	@echo "$(BLUE)[INFO]$(NC) Pushing backend Docker image to ECR..."
	@$(eval ECR_URL := $(shell terraform output -raw ecr_repository_url 2>/dev/null))
	@if [ -z "$(ECR_URL)" ]; then \
		echo "$(RED)[ERROR]$(NC) ECR repository URL not found. Deploy infrastructure first."; \
		exit 1; \
	fi
	@aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(ECR_URL)
	@docker tag line-commerce-backend:$(ENV) $(ECR_URL):$(ENV)
	@docker push $(ECR_URL):$(ENV)
	@echo "$(GREEN)[SUCCESS]$(NC) Backend image pushed to ECR"

deploy-backend: build-backend push-backend ## Build and deploy backend
	@echo "$(BLUE)[INFO]$(NC) Updating ECS service..."
	@aws ecs update-service --cluster line-commerce-$(ENV)-backend-cluster --service line-commerce-$(ENV)-backend --force-new-deployment
	@echo "$(GREEN)[SUCCESS]$(NC) Backend deployment initiated"

# Health checks
health-check: ## Check backend health
	@echo "$(BLUE)[INFO]$(NC) Checking backend health for $(ENV) environment..."
	@$(eval BACKEND_URL := $(shell terraform output -raw backend_api_url 2>/dev/null))
	@if [ -z "$(BACKEND_URL)" ]; then \
		echo "$(RED)[ERROR]$(NC) Backend URL not found. Deploy infrastructure first."; \
		exit 1; \
	fi
	@if curl -f -s "$(BACKEND_URL)/healthz" > /dev/null; then \
		echo "$(GREEN)[SUCCESS]$(NC) Backend health check passed"; \
	else \
		echo "$(RED)[ERROR]$(NC) Backend health check failed"; \
		exit 1; \
	fi

# Logs
logs-backend: ## Tail backend logs
	@echo "$(BLUE)[INFO]$(NC) Tailing backend logs for $(ENV) environment..."
	@aws logs tail /aws/ecs/line-commerce-$(ENV)-backend --follow

logs-db: ## Tail database logs
	@echo "$(BLUE)[INFO]$(NC) Tailing database logs for $(ENV) environment..."
	@aws logs tail /aws/rds/instance/line-commerce-$(ENV)-postgres/postgresql --follow

# Status checks
status: ## Show infrastructure status
	@echo "$(BLUE)[INFO]$(NC) Infrastructure status for $(ENV) environment:"
	@echo ""
	@echo "Terraform Workspace:"
	@terraform workspace show 2>/dev/null || echo "Not initialized"
	@echo ""
	@echo "ECS Service Status:"
	@aws ecs describe-services --cluster line-commerce-$(ENV)-backend-cluster --services line-commerce-$(ENV)-backend --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount}' --output table 2>/dev/null || echo "Service not found"
	@echo ""
	@echo "RDS Instance Status:"
	@aws rds describe-db-instances --db-instance-identifier line-commerce-$(ENV)-postgres --query 'DBInstances[0].{Status:DBInstanceStatus,Engine:Engine,Class:DBInstanceClass}' --output table 2>/dev/null || echo "Database not found"

# Quick deployment (plan + apply)
deploy: plan apply ## Quick deployment (plan + apply)

# Full setup for new environment
bootstrap: setup init deploy ## Bootstrap new environment (setup + init + deploy)