# Docker Development Environment

This document provides comprehensive information about the Docker-based development environment for the LINE Commerce Monorepo Template.

## Overview

The development environment uses Docker Compose to orchestrate multiple services:
- **PostgreSQL**: Database service with health checks
- **Backend**: FastAPI application with hot reloading
- **Frontend**: Next.js application with hot reloading
- **Additional Tools**: pgAdmin, Redis, Mailhog (optional)

## Quick Start

### 1. Initial Setup
```bash
# Clone and setup
git clone <your-repo-url>
cd line-commerce-monorepo
./scripts/setup.sh
```

### 2. Start Development Environment
```bash
# Option 1: Using Make (recommended)
make start

# Option 2: Using development script
./scripts/dev-setup.sh start

# Option 3: Using Docker Compose directly
docker-compose up -d
```

### 3. Access Services
- **Frontend**: http://localhost:3000
- **Backend**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **Database**: localhost:5432

## Docker Compose Files

### Main Configuration (`docker-compose.yml`)
The primary configuration file that defines:
- PostgreSQL database with health checks
- Backend FastAPI service with hot reloading
- Frontend Next.js service with hot reloading
- Shared network and volumes

### Development Tools (`docker-compose.dev.yml`)
Additional development tools:
- **pgAdmin**: Database management UI (http://localhost:5050)
- **Redis**: Caching and session storage (localhost:6379)
- **Mailhog**: Email testing (http://localhost:8025)

Usage:
```bash
make dev-tools
# OR
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

### Testing Environment (`docker-compose.test.yml`)
Isolated testing environment:
- Separate database instance (port 5433)
- Test-specific configuration
- Automated test runner service

Usage:
```bash
make test
# OR
./scripts/run-integration-tests.sh
```

## Development Features

### Hot Reloading

**Backend Hot Reloading:**
- Uses `uvicorn --reload` with file watching
- Monitors `/app` directory for changes
- Excludes `__pycache__` and `.pytest_cache` from volume mounts
- Environment variable `WATCHFILES_FORCE_POLLING=true` for cross-platform compatibility

**Frontend Hot Reloading:**
- Uses Next.js development server with `npm run dev`
- Environment variables for enhanced file watching:
  - `WATCHPACK_POLLING=true`
  - `CHOKIDAR_USEPOLLING=true`
- Excludes `.next/cache` from volume mounts for performance

### Health Checks

All services include health checks:
- **PostgreSQL**: `pg_isready` command
- **Backend**: HTTP request to `/healthz` endpoint
- **Frontend**: HTTP request to root path

Health check configuration:
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8000/healthz"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 10s
```

### Volume Management

**Persistent Volumes:**
- `postgres_data`: Database data persistence
- `backend_cache`: Python package cache
- `frontend_node_modules`: Node.js dependencies
- `frontend_next`: Next.js build cache

**Bind Mounts:**
- Source code directories for hot reloading
- Configuration files
- Scripts directory

## Database Operations

### Seeding and Resetting

**Seed Database:**
```bash
make seed
# OR
docker-compose exec backend python /scripts/seed-db.py
```

**Reset Database:**
```bash
make reset
# OR
docker-compose exec backend python /scripts/reset-db.py
```

### Migrations

**Run Migrations:**
```bash
make migrate
# OR
docker-compose exec backend alembic upgrade head
```

**Create Migration:**
```bash
make migrate-create message="Add new table"
# OR
docker-compose exec backend alembic revision --autogenerate -m "Add new table"
```

### Database Access

**PostgreSQL Shell:**
```bash
make shell-db
# OR
docker-compose exec postgres psql -U postgres -d line_commerce
```

**pgAdmin (with dev-tools):**
- URL: http://localhost:5050
- Email: admin@linecommerce.com
- Password: admin123

## Testing

### Integration Tests

The testing environment provides:
- Isolated PostgreSQL instance (port 5433)
- Test-specific configuration
- Automated test execution

**Run All Tests:**
```bash
make test
# OR
./scripts/run-integration-tests.sh
```

**Test Components:**
1. API health checks
2. Database connectivity
3. Authentication flow
4. CRUD operations
5. Backend pytest suite

### Unit Tests

**Backend Tests:**
```bash
make shell-backend
pytest tests/ -v
```

**Frontend Tests:**
```bash
make shell-frontend
npm test
```

## Development Tools

### Container Shell Access

**Backend Shell:**
```bash
make shell-backend
# OR
docker-compose exec backend bash
```

**Frontend Shell:**
```bash
make shell-frontend
# OR
docker-compose exec frontend sh
```

### Code Quality

**Linting:**
```bash
make lint
# Backend: black, isort, flake8
# Frontend: eslint, prettier
```

**Formatting:**
```bash
make format
# Auto-format all code
```

### Logging

**View All Logs:**
```bash
make logs
# OR
docker-compose logs -f
```

**View Service-Specific Logs:**
```bash
make logs service=backend
# OR
docker-compose logs -f backend
```

## Environment Configuration

### Environment Files

The setup creates multiple environment files:
- `.env`: Root configuration
- `backend/.env`: Backend-specific variables
- `frontend/.env.local`: Frontend-specific variables

### Variable Precedence

1. Docker Compose environment section
2. `.env` file in project root
3. Service-specific `.env` files
4. Default values in Docker Compose

### Security Considerations

- Secrets are loaded from environment files
- No hardcoded credentials in Docker images
- HTTP-only cookies for authentication
- CORS configuration for API security

## Performance Optimization

### Development Performance

**Volume Optimization:**
- Exclude cache directories from bind mounts
- Use named volumes for dependencies
- Separate volumes for build artifacts

**File Watching:**
- Polling-based file watching for cross-platform compatibility
- Optimized reload directories
- Excluded patterns for better performance

### Resource Management

**Memory Usage:**
- Shared volumes reduce disk usage
- Optimized Docker images with multi-stage builds
- Efficient layer caching

**Network Performance:**
- Single Docker network for all services
- Health checks prevent premature connections
- Service dependencies ensure proper startup order

## Troubleshooting

### Common Issues

**Services Not Starting:**
```bash
# Check service status
make status

# View logs for errors
make logs service=backend

# Restart specific service
docker-compose restart backend
```

**Database Connection Issues:**
```bash
# Check PostgreSQL health
docker-compose exec postgres pg_isready -U postgres

# Verify database exists
make shell-db
\l
```

**Hot Reloading Not Working:**
```bash
# Check file watching environment variables
docker-compose exec backend env | grep WATCH
docker-compose exec frontend env | grep WATCH

# Restart services
make restart
```

**Port Conflicts:**
```bash
# Check port usage
lsof -i :3000
lsof -i :8000
lsof -i :5432

# Stop conflicting services
make stop
```

### Cleanup and Reset

**Clean Docker Resources:**
```bash
make clean
# Removes containers, volumes, and unused images
```

**Reset Everything:**
```bash
make clean
make start
```

**Selective Cleanup:**
```bash
# Remove only volumes
docker-compose down -v

# Remove unused images
docker image prune -f
```

## Advanced Configuration

### Custom Docker Compose Overrides

Create `docker-compose.override.yml` for local customizations:
```yaml
version: '3.8'
services:
  backend:
    environment:
      - CUSTOM_VAR=value
    ports:
      - "8001:8000"  # Custom port mapping
```

### Development vs Production

**Development Features:**
- Hot reloading enabled
- Debug logging
- Development dependencies installed
- Source code mounted as volumes

**Production Differences:**
- Optimized Docker images
- No source code mounts
- Production environment variables
- Health checks and monitoring

### Integration with IDEs

**VS Code:**
- Use Dev Containers extension
- Configure remote debugging
- Mount workspace in containers

**PyCharm:**
- Configure Docker Compose interpreter
- Set up remote debugging
- Use Docker-based run configurations

## Best Practices

### Development Workflow

1. **Start Environment**: `make start`
2. **Make Changes**: Edit source code
3. **Test Changes**: Automatic reload + `make test`
4. **Commit**: Use `make lint` before committing
5. **Clean Up**: `make stop` when done

### Database Management

1. **Regular Backups**: `make backup-db`
2. **Migration Testing**: Test migrations in isolated environment
3. **Data Seeding**: Use consistent seed data for development
4. **Schema Changes**: Always create migrations for schema changes

### Performance Monitoring

1. **Resource Usage**: Monitor Docker resource consumption
2. **Log Analysis**: Regular log review for errors
3. **Health Checks**: Monitor service health status
4. **Network Performance**: Check inter-service communication

This Docker development environment provides a robust, scalable foundation for LINE Commerce application development with comprehensive tooling and automation.