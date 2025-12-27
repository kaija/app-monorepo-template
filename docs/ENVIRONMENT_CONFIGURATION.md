# Environment Configuration Guide

This guide explains how to configure environment variables for the LINE Commerce monorepo template across different environments (development, staging, production).

## Overview

The application uses a layered environment configuration system that:
- Validates all required environment variables at startup
- Provides environment-specific configuration files
- Ensures no hardcoded secrets in the codebase
- Validates security settings for production environments

## Environment Files

### Root Level Configuration

- `.env.example` - Template with all available environment variables
- `.env.local.example` - Development-friendly defaults
- `.env.staging.example` - Staging environment template
- `.env.production.example` - Production environment template

### Component-Specific Configuration

- `frontend/.env.example` - Frontend-specific environment variables
- `backend/.env.example` - Backend-specific environment variables

## Quick Start

### 1. Local Development Setup

```bash
# Copy the local development template
cp .env.local.example .env

# Copy frontend template
cp frontend/.env.example frontend/.env.local

# Copy backend template  
cp backend/.env.example backend/.env

# Update the values in each file as needed
```

### 2. Generate Secure Secrets

```bash
# Generate JWT secret (32+ characters)
openssl rand -hex 32

# Generate NextAuth secret
openssl rand -base64 32

# Generate database password
openssl rand -base64 24
```

### 3. Validate Configuration

```bash
# Validate current environment
./scripts/validate-env.sh

# Validate specific environment
./scripts/validate-env.sh -e production

# Validate specific .env file
./scripts/validate-env.sh -f .env.production -e production
```

## Required Environment Variables

### Core Variables (All Environments)

| Variable | Description | Example |
|----------|-------------|---------|
| `ENVIRONMENT` | Application environment | `development`, `staging`, `production` |
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://user:pass@host:5432/db` |
| `JWT_SECRET_KEY` | JWT signing secret (32+ chars) | Generated with `openssl rand -hex 32` |
| `NEXTAUTH_SECRET` | NextAuth session secret (32+ chars) | Generated with `openssl rand -base64 32` |
| `NEXT_PUBLIC_API_URL` | Backend API URL | `http://localhost:8000` |
| `NEXT_PUBLIC_APP_URL` | Frontend app URL | `http://localhost:3000` |

### Production-Only Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `POSTGRES_PASSWORD` | Database password | Yes |
| `CORS_ORIGINS` | Allowed CORS origins | Yes |
| `SENTRY_DSN` | Error tracking DSN | Recommended |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `GOOGLE_CLIENT_ID` | Google OAuth client ID | None |
| `GOOGLE_CLIENT_SECRET` | Google OAuth secret | None |
| `APPLE_CLIENT_ID` | Apple OAuth client ID | None |
| `APPLE_CLIENT_SECRET` | Apple OAuth secret | None |
| `NEXT_PUBLIC_GA_ID` | Google Analytics ID | None |

## Environment-Specific Configuration

### Development Environment

```bash
# .env (development)
ENVIRONMENT=development
NODE_ENV=development
DEBUG=true
LOG_LEVEL=debug

# Use local PostgreSQL
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/line_commerce_dev

# Development secrets (not secure)
JWT_SECRET_KEY=dev-jwt-secret-key-not-for-production-use-only
NEXTAUTH_SECRET=dev-nextauth-secret-not-for-production-use

# Local URLs
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_APP_URL=http://localhost:3000

# Relaxed CORS for development
CORS_ORIGINS=http://localhost:3000,http://127.0.0.1:3000,http://localhost:3001
```

### Staging Environment

```bash
# .env.staging
ENVIRONMENT=staging
NODE_ENV=production
DEBUG=false
LOG_LEVEL=info

# Managed database
DATABASE_URL=postgresql://user:SECURE_PASSWORD@staging-db.example.com:5432/line_commerce_staging

# Production-grade secrets
JWT_SECRET_KEY=CRYPTOGRAPHICALLY_SECURE_32_CHAR_SECRET
NEXTAUTH_SECRET=CRYPTOGRAPHICALLY_SECURE_32_CHAR_SECRET

# Staging URLs (HTTPS)
NEXT_PUBLIC_API_URL=https://api-staging.linecommerce.example.com
NEXT_PUBLIC_APP_URL=https://staging.linecommerce.example.com

# Restricted CORS
CORS_ORIGINS=https://staging.linecommerce.example.com
```

### Production Environment

```bash
# .env.production
ENVIRONMENT=production
NODE_ENV=production
DEBUG=false
LOG_LEVEL=warn

# Production database
DATABASE_URL=postgresql://user:SECURE_PASSWORD@prod-db.example.com:5432/line_commerce_prod

# Cryptographically secure secrets
JWT_SECRET_KEY=REPLACE_WITH_CRYPTOGRAPHICALLY_SECURE_SECRET
NEXTAUTH_SECRET=REPLACE_WITH_CRYPTOGRAPHICALLY_SECURE_SECRET

# Production URLs (HTTPS only)
NEXT_PUBLIC_API_URL=https://api.linecommerce.example.com
NEXT_PUBLIC_APP_URL=https://linecommerce.example.com

# Strict CORS
CORS_ORIGINS=https://linecommerce.example.com

# Production services
SENTRY_DSN=https://your-sentry-dsn@sentry.io/project
NEXT_PUBLIC_GA_ID=GA_MEASUREMENT_ID
```

## Validation Rules

### Security Validation

1. **JWT Secret Key**
   - Must be at least 32 characters long
   - Cannot be default/weak values
   - Cannot contain "dev" or "test" in production

2. **Database URL**
   - Must be a valid PostgreSQL connection string
   - Cannot use default credentials in production

3. **URLs**
   - Must use HTTPS in production (except localhost)
   - Must be valid URL format

4. **CORS Origins**
   - Must use HTTPS in production
   - At least one origin must be specified

### Environment-Specific Validation

- **Development**: Relaxed validation, allows HTTP URLs
- **Staging**: Production-like validation with staging resources
- **Production**: Strict validation, requires HTTPS and secure secrets

## OAuth Configuration

### Google OAuth Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable Google+ API
4. Create OAuth 2.0 credentials
5. Add authorized redirect URIs:
   - `http://localhost:3000/api/auth/callback/google` (development)
   - `https://yourdomain.com/api/auth/callback/google` (production)

```bash
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
```

### Apple OAuth Setup

1. Go to [Apple Developer Console](https://developer.apple.com/)
2. Create a new App ID
3. Enable Sign In with Apple
4. Create a Service ID
5. Configure domains and redirect URLs

```bash
APPLE_CLIENT_ID=your_apple_client_id
APPLE_CLIENT_SECRET=your_apple_client_secret
APPLE_TEAM_ID=your_apple_team_id
APPLE_KEY_ID=your_apple_key_id
```

## Troubleshooting

### Common Issues

1. **Missing Environment Variables**
   ```bash
   ❌ Missing required environment variables: DATABASE_URL, JWT_SECRET_KEY
   ```
   **Solution**: Copy `.env.example` to `.env` and set all required variables

2. **Weak JWT Secret**
   ```bash
   ❌ JWT secret key must be at least 32 characters long
   ```
   **Solution**: Generate a secure secret: `openssl rand -hex 32`

3. **Production HTTPS Validation**
   ```bash
   ❌ API URL should use HTTPS in production
   ```
   **Solution**: Use HTTPS URLs in production environment

4. **Database Connection Failed**
   ```bash
   ❌ Database URL must be a PostgreSQL connection string
   ```
   **Solution**: Ensure DATABASE_URL starts with `postgresql://` or `postgresql+asyncpg://`

### Validation Commands

```bash
# Check environment configuration
./scripts/validate-env.sh

# Check for hardcoded secrets in code
./scripts/validate-env.py --check-secrets

# Validate specific environment
./scripts/validate-env.sh -e production -f .env.production
```

### Debug Configuration

```bash
# Backend: Check loaded configuration
python -c "from backend.app.core.config import settings; print(settings.model_dump())"

# Frontend: Check configuration in browser console
# Open browser dev tools and check for configuration logs
```

## Security Best Practices

1. **Never commit `.env` files** - They're in `.gitignore` for a reason
2. **Use strong, unique secrets** - Generate with `openssl rand`
3. **Rotate secrets regularly** - Especially in production
4. **Use environment-specific secrets** - Don't reuse across environments
5. **Validate configuration** - Run validation scripts before deployment
6. **Monitor for exposed secrets** - Use tools like GitLeaks or TruffleHog
7. **Use managed services** - For databases, secret management in production

## CI/CD Integration

Add environment validation to your CI/CD pipeline:

```yaml
# .github/workflows/validate-env.yml
- name: Validate Environment Configuration
  run: |
    ./scripts/validate-env.sh -e production -f .env.production.example
```

This ensures all deployments have valid configuration before going live.