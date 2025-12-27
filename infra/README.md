# LINE Commerce Infrastructure

This directory contains Terraform infrastructure as code for deploying the LINE Commerce monorepo to AWS and Vercel.

## Architecture Overview

The infrastructure consists of:

- **Frontend**: Next.js application deployed to Vercel
- **Backend**: FastAPI application running on AWS ECS Fargate
- **Database**: Managed PostgreSQL on AWS RDS
- **Networking**: VPC with public/private subnets, NAT gateways, and security groups
- **Load Balancing**: Application Load Balancer with SSL termination
- **Container Registry**: AWS ECR for Docker images
- **Secrets Management**: AWS Secrets Manager for database credentials
- **CI/CD**: GitHub Actions with OIDC for secure deployments

## Prerequisites

1. **AWS CLI** - Configure with appropriate credentials
   ```bash
   aws configure
   ```

2. **Terraform** - Version 1.0 or later
   ```bash
   # macOS
   brew install terraform
   
   # Or download from https://terraform.io
   ```

3. **Vercel CLI** - For frontend deployment
   ```bash
   npm install -g vercel
   vercel login
   ```

4. **Docker** - For building backend images
   ```bash
   # Install Docker Desktop or Docker Engine
   ```

## Quick Start

### 1. Setup Remote State Backend

First, create the S3 bucket and DynamoDB table for Terraform state:

```bash
cd infra
./scripts/setup-state-backend.sh
```

This will create:
- S3 bucket for storing Terraform state
- DynamoDB table for state locking
- Backend configuration files for each environment

### 2. Initialize Terraform

Initialize Terraform with the appropriate backend configuration:

```bash
# For development environment
terraform init -backend-config=backend-dev.hcl

# For staging environment  
terraform init -backend-config=backend-staging.hcl

# For production environment
terraform init -backend-config=backend-prod.hcl
```

### 3. Deploy Infrastructure

Use the deployment script to deploy to your desired environment:

```bash
# Plan deployment (see what will be created)
./scripts/deploy.sh dev plan

# Apply deployment (create infrastructure)
./scripts/deploy.sh dev apply

# Check outputs
./scripts/deploy.sh dev output
```

## Environment Configuration

### Development (dev)
- **Database**: db.t3.micro with 20GB storage
- **Backend**: 1 task with 256 CPU / 512MB memory
- **Features**: ECS Exec enabled for debugging
- **Domain**: Uses ALB default domain

### Staging (staging)
- **Database**: db.t3.small with 50GB storage
- **Backend**: 2 tasks with 512 CPU / 1GB memory
- **Features**: Similar to production but smaller scale
- **Domain**: staging.your-domain.com (configure in staging.tfvars)

### Production (prod)
- **Database**: db.t3.medium with 100GB storage, enhanced monitoring
- **Backend**: 3 tasks with 1024 CPU / 2GB memory
- **Features**: Deletion protection, performance insights
- **Domain**: your-domain.com (configure in prod.tfvars)

## Configuration Files

### Environment Variables

Update the following files with your specific configuration:

1. **infra/environments/dev.tfvars**
2. **infra/environments/staging.tfvars**
3. **infra/environments/prod.tfvars**

Key variables to customize:
- `domain_name`: Your custom domain (leave empty for ALB domain)
- `allowed_cidr_blocks`: IP ranges allowed to access the database
- `backend_image_tag`: Docker image tag to deploy

### Vercel Configuration

Update the following in `infra/frontend.tf`:
- `git_repository.repo`: Your GitHub repository path
- Vercel project settings and environment variables

### GitHub Actions

Update the following in `infra/frontend.tf`:
- GitHub repository path in the OIDC provider configuration
- IAM role trust policy with your repository path

## Deployment Process

### Backend Deployment

1. **Build and Push Docker Image**:
   ```bash
   # Get ECR login token
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
   
   # Build and tag image
   cd backend
   docker build -t line-commerce-backend .
   docker tag line-commerce-backend:latest <ecr-repo-url>:latest
   
   # Push image
   docker push <ecr-repo-url>:latest
   ```

2. **Update ECS Service**:
   ```bash
   # The deployment script will automatically update the ECS service
   ./scripts/deploy.sh prod apply
   ```

### Frontend Deployment

The frontend is automatically deployed to Vercel when you push to the configured branch. You can also deploy manually:

```bash
cd frontend
vercel --prod
```

## Monitoring and Logging

### CloudWatch Logs

- **Backend Application**: `/aws/ecs/line-commerce-{env}-backend`
- **Database**: `/aws/rds/instance/line-commerce-{env}-postgres/postgresql`
- **ECS Exec**: `/aws/ecs/line-commerce-{env}-exec`

### Health Checks

- **Backend Health**: `https://<alb-domain>/healthz`
- **Database**: Monitored via RDS enhanced monitoring (production only)

### Accessing Logs

```bash
# View backend logs
aws logs tail /aws/ecs/line-commerce-dev-backend --follow

# View database logs
aws logs tail /aws/rds/instance/line-commerce-dev-postgres/postgresql --follow
```

## Security

### Database Security

- Database is deployed in private subnets
- Security groups restrict access to backend services only
- Credentials stored in AWS Secrets Manager
- Encryption at rest enabled
- SSL/TLS encryption in transit

### Backend Security

- ECS tasks run in private subnets
- Security groups allow only ALB traffic
- Secrets injected via AWS Secrets Manager
- Container images scanned for vulnerabilities

### Network Security

- VPC with public/private subnet architecture
- NAT gateways for outbound internet access
- Security groups with least privilege access
- SSL termination at load balancer

## Troubleshooting

### Common Issues

1. **Terraform State Lock**:
   ```bash
   # If state is locked, force unlock (use carefully)
   terraform force-unlock <lock-id>
   ```

2. **ECS Service Not Starting**:
   ```bash
   # Check ECS service events
   aws ecs describe-services --cluster line-commerce-dev-backend-cluster --services line-commerce-dev-backend
   
   # Check CloudWatch logs
   aws logs tail /aws/ecs/line-commerce-dev-backend --follow
   ```

3. **Database Connection Issues**:
   ```bash
   # Test database connectivity from ECS task
   aws ecs execute-command --cluster line-commerce-dev-backend-cluster --task <task-id> --container backend --interactive --command "/bin/bash"
   ```

4. **SSL Certificate Issues**:
   - Ensure DNS validation records are created
   - Check certificate status in AWS Certificate Manager
   - Verify domain ownership

### Debugging Commands

```bash
# Get all outputs
terraform output

# Show current workspace
terraform workspace show

# List all workspaces
terraform workspace list

# Validate configuration
terraform validate

# Format configuration files
terraform fmt -recursive
```

## Cost Optimization

### Development Environment
- Use smaller instance types
- Single AZ deployment
- Minimal backup retention
- No enhanced monitoring

### Production Environment
- Right-size instances based on usage
- Use Reserved Instances for predictable workloads
- Enable detailed monitoring only when needed
- Set up CloudWatch alarms for cost monitoring

## Cleanup

To destroy infrastructure (use with caution):

```bash
# Destroy development environment
./scripts/deploy.sh dev destroy

# Destroy staging environment
./scripts/deploy.sh staging destroy

# Destroy production environment (requires confirmation)
./scripts/deploy.sh prod destroy
```

## Support

For issues with this infrastructure:

1. Check the troubleshooting section above
2. Review CloudWatch logs for error messages
3. Validate Terraform configuration with `terraform validate`
4. Check AWS service health dashboard
5. Review GitHub Actions logs for CI/CD issues

## Contributing

When making changes to the infrastructure:

1. Test changes in development environment first
2. Run `terraform plan` to review changes
3. Update documentation if needed
4. Follow the deployment process for each environment
5. Monitor deployments and rollback if issues occur