# Deployment Scripts

This directory contains deployment scripts for the Basic Item CRUD App.

## Scripts Overview

### `deploy-all.sh` (Recommended)
The main deployment script that handles both backend and frontend deployment.

**Usage:**
```bash
# Full deployment (backend + frontend)
./deploy-all.sh

# Backend only
./deploy-all.sh --backend-only

# Frontend only (requires backend to exist)
./deploy-all.sh --frontend-only

# Skip confirmation prompts
./deploy-all.sh --skip-confirm

# Skip Docker build/push (use existing image)
./deploy-all.sh --skip-docker
```

### `deploy.sh` (Legacy)
Legacy script that now redirects to `deploy-all.sh` with backend-only mode for backward compatibility.

### `deploy-frontend.sh` (Standalone)
Standalone frontend deployment script (kept for reference).

### `destroy-all.sh` (Destruction)
Comprehensive destruction script for safely removing infrastructure.

**Usage:**
```bash
# Full destruction (backend + frontend + ECR)
./destroy-all.sh

# Backend only (includes ECR repository)
./destroy-all.sh --backend-only

# Frontend only
./destroy-all.sh --frontend-only

# Skip confirmation prompts
./destroy-all.sh --skip-confirm

# Skip ECR repository deletion
./destroy-all.sh --skip-ecr

# Force destruction without confirmation
./destroy-all.sh --force
```

**⚠️ WARNING: This will permanently destroy your infrastructure! ⚠️**

## Prerequisites

1. **AWS CLI** installed and configured
2. **Terraform** installed
3. **Docker** installed (for backend deployment)
4. **terraform.tfvars** file configured

## Quick Start

1. **Configure your environment:**
   ```bash
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Deploy everything:**
   ```bash
   ./deploy-all.sh
   ```

3. **Access your application:**
   - The script will output your CloudFront URL (frontend)
   - The script will output your API Gateway URL (backend)

## Deployment Modes

### Full Deployment
Deploys both backend infrastructure and frontend files:
- Creates/updates all AWS resources
- Builds and pushes Docker image to ECR
- Uploads frontend files to S3
- Configures CloudFront distribution
- Invalidates CloudFront cache

### Backend Only
Deploys only the backend infrastructure:
- Lambda function with API Gateway
- DynamoDB tables
- ECR repository
- IAM roles and policies
- S3 bucket and CloudFront (for future frontend use)

### Frontend Only
Deploys only the frontend files:
- Requires backend infrastructure to already exist
- Uploads files to existing S3 bucket
- Invalidates CloudFront cache

## Options

- `--backend-only`: Deploy only backend infrastructure
- `--frontend-only`: Deploy only frontend (requires backend to exist)
- `--skip-confirm`: Skip confirmation prompts (useful for CI/CD)
- `--skip-docker`: Skip Docker build/push (use existing image)

## Troubleshooting

### Common Issues

1. **"Access Denied" errors:**
   - Ensure AWS credentials are configured
   - Check IAM permissions

2. **"Terraform state not found":**
   - Run backend deployment first
   - Check terraform.tfstate file exists

3. **Docker build failures:**
   - Ensure Docker is running
   - Check Dockerfile exists in backend directory

4. **CloudFront shows old content:**
   - Invalidation can take 5-15 minutes
   - Check invalidation status in AWS Console

### Manual Commands

If scripts fail, you can run commands manually:

```bash
# Backend deployment
cd terraform
terraform init
terraform plan
terraform apply

# Frontend deployment
aws s3 sync frontend/ s3://your-bucket-name --delete
aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths "/*"
```

## Destruction

### Safe Infrastructure Removal

The `destroy-all.sh` script provides a safe way to remove your infrastructure:

#### Features
- **Selective destruction**: Choose to destroy backend, frontend, or everything
- **ECR safety**: Shows repository contents and requires explicit confirmation before deleting
- **Confirmation prompts**: Multiple safety checks to prevent accidental deletion
- **S3 cleanup**: Empties S3 buckets before destroying them
- **State validation**: Checks Terraform state before proceeding

#### ECR Repository Safety
When destroying backend or all infrastructure, the script will:
1. Show you exactly what's in the ECR repository
2. Display image count and details
3. Require you to type "DELETE ECR" to confirm
4. Delete all images before removing the repository

#### Examples
```bash
# Destroy everything with safety prompts
./destroy-all.sh

# Destroy only frontend (keeps backend and ECR)
./destroy-all.sh --frontend-only

# Destroy only backend (includes ECR with confirmation)
./destroy-all.sh --backend-only

# Force destruction without prompts (use with caution!)
./destroy-all.sh --force
```

## File Structure

```
infra/scripts/
├── deploy-all.sh          # Main deployment script
├── deploy.sh              # Legacy script (redirects)
├── deploy-frontend.sh     # Standalone frontend script
├── destroy-all.sh         # Infrastructure destruction script
└── README.md              # This file
```

## Security Notes

- All scripts use least-privilege IAM roles
- S3 buckets are configured with public access blocked
- CloudFront uses Origin Access Control (OAC)
- All traffic is encrypted in transit (HTTPS)

## Cost Optimization

- S3 storage costs are minimal for static files
- CloudFront has a free tier for first 1TB
- Lambda has a generous free tier
- DynamoDB on-demand billing scales with usage
