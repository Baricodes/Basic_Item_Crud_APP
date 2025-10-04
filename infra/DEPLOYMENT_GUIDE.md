# 🚀 AWS Deployment Guide for Basic Item CRUD App

## Overview

This guide will help you deploy your FastAPI application on AWS using:
- **AWS Lambda** with Docker containers
- **API Gateway** for HTTP routing
- **DynamoDB** for data storage
- **ECR** for container image storage

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured
3. **Terraform** >= 1.0 installed
4. **Docker** installed and running

## Quick Deployment

### Step 1: Configure Variables
```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### Step 2: Deploy Infrastructure
```bash
# Option A: Use the automated script
cd infra/scripts
./deploy.sh

# Option B: Manual deployment
cd infra/terraform
terraform init
terraform plan
terraform apply
```

### Step 3: Build and Push Docker Image
```bash
# Get ECR repository URL from terraform output
cd infra/terraform
ECR_REPO_URL=$(terraform output -raw ecr_repository_url)

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REPO_URL

# Build and push image
docker build -t basic-item-crud ../../backend/
docker tag basic-item-crud:latest $ECR_REPO_URL:latest
docker push $ECR_REPO_URL:latest

# Update Lambda function
aws lambda update-function-code --function-name $(terraform output -raw lambda_function_name) --image-uri $ECR_REPO_URL:latest
```

## Architecture Components

### 1. Lambda Function
- **Runtime**: Python 3.12 with Docker
- **Memory**: 512 MB (configurable)
- **Timeout**: 30 seconds (configurable)
- **Handler**: `main.handler` (Mangum adapter)

### 2. API Gateway
- **Type**: REST API with proxy integration
- **CORS**: Configured for your frontend domains
- **Logging**: CloudWatch integration enabled

### 3. DynamoDB Tables
- **users**: User authentication and management
  - Primary key: `id` (String)
  - GSI: `username-index` on `username`
- **items**: Item CRUD operations
  - Primary key: `id` (String)
  - GSI: `owner-id-index` on `owner_id`

### 4. IAM Security
- **Lambda Role**: DynamoDB access with least privilege
- **API Gateway Role**: Lambda invocation permissions
- **Policies**: Granular permissions for each service

## Environment Variables

Your Lambda function will receive:
```bash
REGION=us-east-1
USERS_TABLE=basic-item-crud-dev-users
ITEMS_TABLE=basic-item-crud-dev-items
```

## API Endpoints

After deployment, your API will be available at:
```
https://<api-gateway-id>.execute-api.<region>.amazonaws.com/dev/
```

### Available Endpoints:
- `GET /health` - Health check
- `POST /user/register` - User registration
- `POST /user/login` - User login
- `GET /item/` - List items
- `POST /item/` - Create item
- `GET /item/{id}` - Get item
- `PUT /item/{id}` - Update item
- `DELETE /item/{id}` - Delete item

## Monitoring and Logs

### CloudWatch Logs:
- Lambda logs: `/aws/lambda/basic-item-crud-dev`
- API Gateway logs: `/aws/apigateway/basic-item-crud-dev-api`

### Key Metrics:
- Lambda: Invocations, errors, duration, throttles
- API Gateway: Request count, latency, error rates
- DynamoDB: Read/write capacity, throttles

## Security Features

✅ **Least Privilege IAM**: Lambda only has necessary DynamoDB permissions  
✅ **CORS Configuration**: Restricted to specified origins  
✅ **VPC Isolation**: Resources in default VPC (can be customized)  
✅ **Encryption**: DynamoDB encryption at rest enabled  
✅ **Logging**: Comprehensive CloudWatch logging  

## Cost Optimization

- **DynamoDB**: Pay-per-request billing mode
- **Lambda**: Only pay for actual execution time
- **API Gateway**: Pay per API call
- **ECR**: Pay for storage and data transfer

## Troubleshooting

### Common Issues:

1. **Lambda Timeout**
   - Increase `lambda_timeout` in terraform.tfvars
   - Check CloudWatch logs for errors

2. **CORS Errors**
   - Update `allowed_origins` in terraform.tfvars
   - Redeploy API Gateway

3. **DynamoDB Access Denied**
   - Check IAM policies
   - Verify table names in environment variables

4. **Docker Build Fails**
   - Ensure Docker is running
   - Check Dockerfile syntax
   - Verify ECR login

### Debug Commands:
```bash
# Check Lambda function status
aws lambda get-function --function-name basic-item-crud-dev

# View Lambda logs
aws logs tail /aws/lambda/basic-item-crud-dev --follow

# Test API Gateway
curl https://<api-gateway-url>/health
```

## Cleanup

To remove all resources:
```bash
cd infra/terraform
terraform destroy
```

## Next Steps

1. **Add Authentication**: Implement JWT or Cognito
2. **Add Monitoring**: Set up CloudWatch alarms
3. **Add CI/CD**: GitHub Actions or AWS CodePipeline
4. **Add Custom Domain**: Route 53 + API Gateway custom domain
5. **Add Rate Limiting**: API Gateway throttling or WAF

## Support

For issues or questions:
1. Check CloudWatch logs
2. Review Terraform plan output
3. Verify AWS permissions
4. Check this documentation
