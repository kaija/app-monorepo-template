# LINE Commerce Monorepo Development Makefile
# Provides convenient commands for Docker-based development

.PHONY: help start stop restart status logs clean test seed reset build dev-tools

# Default target
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Docker Compose files
COMPOSE_FILE := docker-compose.yml
COMPOSE_DEV_FILE := docker-compose.dev.yml
COMPOSE_TEST_FILE := docker-compose.test.yml

help: ## Show this help message
	@echo "$(BLUE)LINE Commerce Development Commands$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ { printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(YELLOW)Examples:$(NC)"
	@echo "  make start          # Start development environment"
	@echo "  make logs service=backend  # Show backend logs"
	@echo "  make test           # Run integration tests"

start: ## Start the development environment
	@echo "$(BLUE)🚀 Starting LINE Commerce development environment...$(NC)"
	@./scripts/dev-setup.sh start

stop: ## Stop all services
	@echo "$(BLUE)🛑 Stopping services...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) down

restart: ## Restart all services
	@echo "$(BLUE)🔄 Restarting services...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) restart

status: ## Show service status and URLs
	@echo "$(BLUE)📊 Service Status:$(NC)"
	@docker-compose -f $(COMPOSE_FILE) ps
	@echo ""
	@echo "$(BLUE)🌐 Service URLs:$(NC)"
	@echo "  Frontend:  http://localhost:3000"
	@echo "  Backend:   http://localhost:8000"
	@echo "  API Docs:  http://localhost:8000/docs"
	@echo "  Database:  postgresql://postgres:postgres@localhost:5432/line_commerce"

logs: ## Show logs for all services or specific service (usage: make logs service=backend)
	@if [ -n "$(service)" ]; then \
		echo "$(BLUE)📋 Showing logs for $(service)...$(NC)"; \
		docker-compose -f $(COMPOSE_FILE) logs -f $(service); \
	else \
		echo "$(BLUE)📋 Showing logs for all services...$(NC)"; \
		docker-compose -f $(COMPOSE_FILE) logs -f; \
	fi

build: ## Build all Docker images
	@echo "$(BLUE)🏗️  Building Docker images...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) build --no-cache

dev-tools: ## Start development environment with additional tools (pgAdmin, Redis, Mailhog)
	@echo "$(BLUE)🛠️  Starting development environment with additional tools...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) -f $(COMPOSE_DEV_FILE) up -d --build
	@echo ""
	@echo "$(GREEN)✅ Development tools started!$(NC)"
	@echo ""
	@echo "$(BLUE)🌐 Additional Service URLs:$(NC)"
	@echo "  pgAdmin:   http://localhost:5050 (admin@linecommerce.com / admin123)"
	@echo "  Redis:     localhost:6379"
	@echo "  Mailhog:   http://localhost:8025"

test: ## Run integration tests
	@echo "$(BLUE)🧪 Running integration tests...$(NC)"
	@./scripts/run-integration-tests.sh run

test-clean: ## Clean up test environment
	@echo "$(BLUE)🧹 Cleaning up test environment...$(NC)"
	@./scripts/run-integration-tests.sh clean

seed: ## Seed database with sample data
	@echo "$(BLUE)🌱 Seeding database...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) exec backend python /scripts/seed-db.py

reset: ## Reset database (removes all data)
	@echo "$(YELLOW)⚠️  This will reset the database and remove all data!$(NC)"
	@read -p "Are you sure? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	@echo "$(BLUE)🔄 Resetting database...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) exec backend python /scripts/reset-db.py
	@$(MAKE) seed

clean: ## Stop services and clean up Docker resources
	@echo "$(YELLOW)⚠️  This will stop all services and remove Docker resources!$(NC)"
	@read -p "Are you sure? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	@echo "$(BLUE)🧹 Cleaning up Docker resources...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) -f $(COMPOSE_DEV_FILE) -f $(COMPOSE_TEST_FILE) down -v --remove-orphans
	@docker system prune -f
	@docker volume prune -f
	@echo "$(GREEN)✅ Cleanup completed!$(NC)"

shell-backend: ## Open shell in backend container
	@echo "$(BLUE)🐚 Opening shell in backend container...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) exec backend bash

shell-frontend: ## Open shell in frontend container
	@echo "$(BLUE)🐚 Opening shell in frontend container...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) exec frontend sh

shell-db: ## Open PostgreSQL shell
	@echo "$(BLUE)🐚 Opening PostgreSQL shell...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) exec postgres psql -U postgres -d line_commerce

migrate: ## Run database migrations
	@echo "$(BLUE)🔄 Running database migrations...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) exec backend alembic upgrade head

migrate-create: ## Create new migration (usage: make migrate-create message="description")
	@if [ -z "$(message)" ]; then \
		echo "$(RED)❌ Please provide a migration message: make migrate-create message=\"your description\"$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)📝 Creating new migration: $(message)$(NC)"
	@docker-compose -f $(COMPOSE_FILE) exec backend alembic revision --autogenerate -m "$(message)"

install: ## Install/update dependencies
	@echo "$(BLUE)📦 Installing dependencies...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) exec backend pip install -r requirements.txt
	@docker-compose -f $(COMPOSE_FILE) exec frontend npm install

lint: ## Run linting for backend and frontend
	@echo "$(BLUE)🔍 Running linting...$(NC)"
	@echo "Backend linting:"
	@docker-compose -f $(COMPOSE_FILE) exec backend black --check app/
	@docker-compose -f $(COMPOSE_FILE) exec backend isort --check-only app/
	@docker-compose -f $(COMPOSE_FILE) exec backend flake8 app/
	@echo "Frontend linting:"
	@docker-compose -f $(COMPOSE_FILE) exec frontend npm run lint

format: ## Format code for backend and frontend
	@echo "$(BLUE)✨ Formatting code...$(NC)"
	@echo "Backend formatting:"
	@docker-compose -f $(COMPOSE_FILE) exec backend black app/
	@docker-compose -f $(COMPOSE_FILE) exec backend isort app/
	@echo "Frontend formatting:"
	@docker-compose -f $(COMPOSE_FILE) exec frontend npm run format

backup-db: ## Backup database to file
	@echo "$(BLUE)💾 Creating database backup...$(NC)"
	@mkdir -p backups
	@docker-compose -f $(COMPOSE_FILE) exec postgres pg_dump -U postgres line_commerce > backups/backup_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "$(GREEN)✅ Database backup created in backups/ directory$(NC)"

restore-db: ## Restore database from backup file (usage: make restore-db file=backup.sql)
	@if [ -z "$(file)" ]; then \
		echo "$(RED)❌ Please provide a backup file: make restore-db file=backup.sql$(NC)"; \
		exit 1; \
	fi
	@if [ ! -f "$(file)" ]; then \
		echo "$(RED)❌ Backup file $(file) not found$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)🔄 Restoring database from $(file)...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) exec -T postgres psql -U postgres -d line_commerce < $(file)
	@echo "$(GREEN)✅ Database restored successfully$(NC)"