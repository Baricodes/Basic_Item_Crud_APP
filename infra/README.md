# AWS Infrastructure for Basic Item CRUD App

This Terraform configuration deploys a FastAPI application on AWS using:
- **Lambda** with Docker container images
- **API Gateway** for HTTP routing
- **DynamoDB** for data storage
- **ECR** for container image storage
- **CloudWatch** for logging

## Architecture

```
Internet → API Gateway → Lambda (Docker) → DynamoDB
```

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0
3. **Docker** for building container images
4. **AWS Account** with necessary permissions

## Quick Start

1. **Configure variables**:
   ```bash
   cd infra/terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Initialize and deploy**:
   ```bash
   cd infra/terraform
   terraform init
   terraform plan
   terraform apply
   ```

3. **Build and push Docker image**:
   ```bash
   # Get the ECR repository URL from terraform output
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ECR_REPO_URL>
   
   # Build and tag image
   docker build -t basic-item-crud ../../backend/
   docker tag basic-item-crud:latest <ECR_REPO_URL>:latest
   
   # Push image
   docker push <ECR_REPO_URL>:latest
   ```

4. **Update Lambda function**:
   ```bash
   aws lambda update-function-code --function-name <FUNCTION_NAME> --image-uri <ECR_REPO_URL>:latest
   ```

## Resources Created

### Lambda
- Lambda function with Docker container
- ECR repository for images
- IAM role with DynamoDB permissions
- CloudWatch log group

### API Gateway
- REST API with proxy integration
- Deployment and stage
- CloudWatch logging

### DynamoDB
- `users` table with username GSI
- `items` table with owner_id GSI
- Point-in-time recovery enabled

### IAM
- Lambda execution role
- DynamoDB access policies
- API Gateway invocation permissions

## Environment Variables

The Lambda function receives these environment variables:
- `REGION`: AWS region
- `USERS_TABLE`: DynamoDB users table name
- `ITEMS_TABLE`: DynamoDB items table name

## API Endpoints

After deployment, your API will be available at:
```
https://<api-gateway-id>.execute-api.<region>.amazonaws.com/<stage>/
```

Available endpoints:
- `GET /health` - Health check
- `POST /user/register` - User registration
- `POST /user/login` - User login
- `GET /item/` - List items
- `POST /item/` - Create item
- `GET /item/{id}` - Get item
- `PUT /item/{id}` - Update item
- `DELETE /item/{id}` - Delete item

## Monitoring

- **CloudWatch Logs**: `/aws/lambda/<function-name>` and `/aws/apigateway/<api-name>`
- **Lambda Metrics**: Invocations, errors, duration, throttles
- **API Gateway Metrics**: Request count, latency, error rates

## Cleanup

To destroy all resources:
```bash
cd infra/terraform
terraform destroy
```

## Troubleshooting

1. **Lambda timeout**: Increase `lambda_timeout` variable
2. **Memory issues**: Increase `lambda_memory_size` variable
3. **CORS errors**: Update `allowed_origins` variable
4. **DynamoDB access**: Check IAM policies and table names

## Security Notes

- API Gateway has no authentication (add as needed)
- DynamoDB uses least-privilege IAM policies
- ECR repository has image scanning enabled
- All resources are tagged for cost tracking
