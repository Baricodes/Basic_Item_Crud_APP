# Copy this file to terraform.tfvars and customize the values

aws_region = "us-east-2"
environment = "dev"
app_name = "basic-item-crud"

# Lambda configuration
lambda_memory_size = 512
lambda_timeout = 30

# DynamoDB configuration
dynamodb_billing_mode = "PAY_PER_REQUEST"

# CORS configuration
allowed_origins = [
  "http://localhost:5500"
]

# Tags
tags = {
  Project     = "Basic Item CRUD"
  Environment = "dev"
  ManagedBy   = "terraform"
  Owner       = "your-name"
}
