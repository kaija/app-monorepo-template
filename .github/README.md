# LINE Commerce CI/CD Pipeline

This directory contains GitHub Actions workflows for the LINE Commerce monorepo template. The CI/CD pipeline provides automated testing, building, and deployment for frontend, backend, and infrastructure components.

## Workflows Overview

### Core CI Workflows

1. **`ci.yml`** - Main CI pipeline that orchestrates all other workflows
2. **`frontend-ci.yml`** - Frontend linting, testing, and building
3. **`backend-ci.yml`** - Backend linting, testing, and Docker building
4. **`database-ci.yml`** - Database migration validation and testing

### Deployment Workflows

1. **`deploy-production.yml`** - Production deployment (triggered on main branch)
2. **`deploy-staging.yml`** - Staging deployment (triggered on develop branch)
3. **`rollback.yml`** - Manual rollback workflow for emergency situations

## Required GitHub Secrets

Configure these secrets in your GitHub repository settings:

### AWS Configuration
```
AWS_ACCESS_KEY_ID          # AWS access key for deployment
AWS_SECRET_ACCESS_KEY      # AWS secret key for deployment
```

### Database Configuration
```
PROD_DATABASE_URL          # Production PostgreSQL connection string
STAGING_DATABASE_URL       # Staging PostgreSQL connection string
```

### Vercel Configuration (Frontend Deployment)
```
VERCEL_TOKEN              # Vercel API token
VERCEL_ORG_ID            # Vercel organization ID
VERCEL_PROJECT_ID        # Vercel project ID
```

### Application URLs
```
FRONTEND_URL             # Production frontend URL
BACKEND_API_URL          # Production backend API URL (fallback)
```

## Workflow Triggers

### Automatic Triggers

- **Push to `main`**: Triggers production deployment
- **Push to `develop`**: Triggers staging deployment
- **Pull Requests**: Triggers CI validation
- **Changes to specific paths**: Optimized CI runs based on changed files

### Manual Triggers

- **Production Deployment**: Can be manually triggered via GitHub Actions UI
- **Rollback**: Emergency rollback workflow with options for different rollback types

## CI/CD Features

### 🔍 Smart Change Detection
- Detects changes in frontend, backend, database, or infrastructure
- Runs only relevant CI jobs to optimize build times
- Skips unnecessary workflows when files haven't changed

### 🧪 Comprehensive Testing
- **Frontend**: ESLint, TypeScript checking, Jest tests, Playwright E2E tests
- **Backend**: Black, isort, Flake8, MyPy, pytest with coverage
- **Database**: Migration validation, rollback testing, performance checks
- **Integration**: Full-stack integration tests with Docker Compose

### 🔒 Security Scanning
- **Dependency Scanning**: npm audit, Safety (Python)
- **Code Scanning**: Bandit (Python), CodeQL, Trivy
- **SARIF Integration**: Security results uploaded to GitHub Security tab

### 📊 Performance Monitoring
- **Load Testing**: k6 performance tests on main branch
- **Migration Performance**: Database migration timing validation
- **Health Checks**: Automated endpoint validation after deployment

### 🚀 Zero-Downtime Deployment
- **Blue-Green Deployment**: ECS service updates with health checks
- **Database Migrations**: Automated migration execution
- **Rollback Capability**: Quick rollback to previous versions

## Environment Configuration

### Development Environment
- **Trigger**: Manual or feature branch testing
- **Resources**: Minimal AWS resources (t3.micro instances)
- **Purpose**: Development and testing

### Staging Environment
- **Trigger**: Push to `develop` branch
- **Resources**: Production-like but smaller scale
- **Purpose**: Pre-production validation and testing

### Production Environment
- **Trigger**: Push to `main` branch
- **Resources**: Full production scale with high availability
- **Purpose**: Live application serving users

## Deployment Process

### 1. Code Changes
```
Developer pushes to develop → Staging deployment
Developer creates PR → CI validation
PR merged to main → Production deployment
```

### 2. Automated Validation
- All CI checks must pass before deployment
- Security scans must not find critical vulnerabilities
- Integration tests must pass

### 3. Infrastructure Deployment
- Terraform applies infrastructure changes
- Docker images built and pushed to ECR
- ECS services updated with new images

### 4. Application Deployment
- Database migrations executed
- Backend services updated
- Frontend deployed to Vercel
- Health checks performed

### 5. Post-Deployment Validation
- Smoke tests executed
- Performance benchmarks run
- Monitoring alerts configured

## Rollback Procedures

### Automatic Rollback Triggers
- Health check failures after deployment
- Critical errors in application logs
- Performance degradation beyond thresholds

### Manual Rollback Options
1. **Backend Only**: Rollback ECS service to previous task definition
2. **Frontend Only**: Rollback Vercel deployment
3. **Full Rollback**: Rollback both frontend and backend
4. **Database Rollback**: Rollback database migrations (use with extreme caution)

### Rollback Execution
```bash
# Via GitHub Actions UI
1. Go to Actions → Rollback Deployment
2. Select environment (prod/staging)
3. Choose rollback type
4. Optionally specify target version
5. Execute rollback
```

## Monitoring and Observability

### CI/CD Metrics
- Build success/failure rates
- Deployment frequency
- Lead time for changes
- Mean time to recovery

### Application Metrics
- API response times
- Error rates
- Database performance
- Frontend Core Web Vitals

### Alerting
- Deployment failures
- Security vulnerabilities
- Performance degradation
- Infrastructure issues

## Best Practices

### 1. Branch Strategy
- `main`: Production-ready code only
- `develop`: Integration branch for staging
- `feature/*`: Feature development branches
- `hotfix/*`: Emergency production fixes

### 2. Commit Messages
- Use conventional commits format
- Include breaking change indicators
- Reference issue numbers

### 3. Pull Request Process
- All CI checks must pass
- Require code review approval
- Include deployment notes
- Test in staging environment

### 4. Security
- Never commit secrets to repository
- Use GitHub Secrets for sensitive data
- Regularly update dependencies
- Monitor security scan results

### 5. Performance
- Monitor deployment times
- Optimize Docker image sizes
- Use caching strategies
- Profile application performance

## Troubleshooting

### Common Issues

#### 1. Deployment Failures
```bash
# Check ECS service status
aws ecs describe-services --cluster <cluster-name> --services <service-name>

# Check CloudWatch logs
aws logs tail /aws/ecs/<log-group> --follow
```

#### 2. Migration Failures
```bash
# Check migration status
alembic current

# View migration history
alembic history

# Manual migration rollback
alembic downgrade -1
```

#### 3. Frontend Build Issues
```bash
# Check Vercel deployment logs
vercel logs <deployment-url>

# Local debugging
npm run build
npm run start
```

### Getting Help

1. **Check Workflow Logs**: GitHub Actions provides detailed logs for each step
2. **Review Documentation**: This README and inline workflow comments
3. **Monitor Alerts**: CloudWatch and application monitoring dashboards
4. **Team Communication**: Use established incident response procedures

## Maintenance

### Regular Tasks
- Update GitHub Actions versions monthly
- Review and rotate secrets quarterly
- Update base Docker images for security patches
- Monitor and optimize CI/CD performance

### Dependency Updates
- Frontend dependencies: Dependabot PRs
- Backend dependencies: Safety security scans
- Infrastructure: Terraform provider updates
- CI/CD: GitHub Actions marketplace updates

---

For more information about specific workflows, see the individual workflow files in this directory.