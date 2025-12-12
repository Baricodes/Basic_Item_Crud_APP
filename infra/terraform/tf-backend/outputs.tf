output "api_gateway_id" {
  description = "API Gateway REST API ID (use this for frontend CloudFront configuration)"
  value       = aws_api_gateway_rest_api.main.id
}

output "api_gateway_url" {
  description = "API Gateway URL"
  value       = aws_api_gateway_rest_api.main.execution_arn
}

output "api_gateway_invoke_url" {
  description = "API Gateway invoke URL"
  value       = "https://${aws_api_gateway_rest_api.main.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.main.stage_name}"
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.main.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.main.arn
}

output "dynamodb_tables" {
  description = "DynamoDB table names"
  value = {
    users = aws_dynamodb_table.users.name
    items = aws_dynamodb_table.items.name
  }
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.main.repository_url
}

output "docker_build_and_push_commands" {
  description = "Commands to build and push Docker image"
  value = <<-EOT
    # Get login token
    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.main.repository_url}
    
    # Build image
    docker build -t ${aws_ecr_repository.main.name} .
    
    # Tag image
    docker tag ${aws_ecr_repository.main.name}:latest ${aws_ecr_repository.main.repository_url}:latest
    
    # Push image
    docker push ${aws_ecr_repository.main.repository_url}:latest
  EOT
}
