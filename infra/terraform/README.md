# Terraform Infrastructure

This directory contains the Terraform configurations for deploying the Basic Item CRUD App infrastructure on AWS.

## Directory Structure

The infrastructure has been organized into two separate directories:

- **`tf-backend/`** - Backend infrastructure (Lambda, API Gateway, DynamoDB, ECR)
- **`tf-frontend/`** - Frontend infrastructure (S3, CloudFront, deployment IAM roles)

## Deployment Order

### Option 1: Deploy Everything at Once (Recommended)

Use the deployment script which handles both backend and frontend:

```bash
cd infra/scripts
./deploy-all.sh
```

### Option 2: Deploy Backend Only

```bash
cd infra/scripts
./deploy-all.sh --backend-only
```

Or manually:

```bash
cd infra/terraform/tf-backend
terraform init
terraform plan
terraform apply
```

### Option 3: Deploy Frontend Only

**Note:** Backend must be deployed first!

```bash
cd infra/scripts
./deploy-all.sh --frontend-only
```

Or manually:

```bash
# Get API Gateway ID from backend
cd infra/terraform/tf-backend
export API_GATEWAY_ID=$(terraform output -raw api_gateway_id)

# Deploy frontend
cd ../tf-frontend
terraform init
terraform plan -var="api_gateway_id=$API_GATEWAY_ID"
terraform apply -var="api_gateway_id=$API_GATEWAY_ID"
```

## Configuration

### Backend Configuration

Edit `tf-backend/terraform.tfvars`:

```hcl
aws_region = "us-east-2"
environment = "dev"
app_name = "basic-item-crud"
lambda_memory_size = 512
lambda_timeout = 30
dynamodb_billing_mode = "PAY_PER_REQUEST"
```

### Frontend Configuration

Edit `tf-frontend/terraform.tfvars`:

```hcl
aws_region = "us-east-2"
environment = "dev"
app_name = "basic-item-crud"

# Optional: API Gateway ID from backend (for CloudFront integration)
# Get this from: cd tf-backend && terraform output -raw api_gateway_id
# api_gateway_id = "your-api-gateway-id"
```

## Cross-Dependencies

The frontend can optionally integrate with the backend through CloudFront:

1. Deploy the backend first
2. Get the API Gateway ID: `cd tf-backend && terraform output -raw api_gateway_id`
3. Set the `api_gateway_id` variable when deploying the frontend

If `api_gateway_id` is not provided, the frontend will deploy without API Gateway integration in CloudFront.

## Destruction

To destroy the infrastructure:

```bash
cd infra/scripts
./destroy-all.sh
```

This will destroy both frontend and backend infrastructure. You can also use:
- `./destroy-all.sh --backend-only` - Destroy only backend
- `./destroy-all.sh --frontend-only` - Destroy only frontend

## Outputs

### Backend Outputs

```bash
cd tf-backend
terraform output
```

Key outputs:
- `api_gateway_id` - Use this for frontend deployment
- `api_gateway_invoke_url` - Backend API endpoint
- `ecr_repository_url` - Docker image repository
- `lambda_function_name` - Lambda function name

### Frontend Outputs

```bash
cd tf-frontend
terraform output
```

Key outputs:
- `frontend_cloudfront_url` - Frontend application URL
- `frontend_s3_bucket` - S3 bucket name
- `frontend_cloudfront_distribution_id` - CloudFront distribution ID

## Notes

- Each directory has its own Terraform state file
- Backend and frontend can be deployed and destroyed independently
- The deployment scripts handle the cross-dependencies automatically
- Make sure to configure AWS credentials before running Terraform

