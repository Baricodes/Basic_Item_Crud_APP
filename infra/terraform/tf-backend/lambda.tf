# ECR repository for Docker images
resource "aws_ecr_repository" "main" {
  name                 = "${var.app_name}-${var.environment}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}

# ECR lifecycle policy
resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Lambda function
resource "aws_lambda_function" "main" {
  function_name = "${var.app_name}-${var.environment}"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.main.repository_url}:latest"
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory_size

  environment {
    variables = {
      REGION = var.aws_region
      USERS_TABLE = aws_dynamodb_table.users.name
      ITEMS_TABLE = aws_dynamodb_table.items.name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_dynamodb_policy_attachment,
    aws_iam_role_policy_attachment.lambda_basic_execution_policy_attachment,
  ]

  tags = var.tags
}

# Lambda function URL (optional - for direct access)
resource "aws_lambda_function_url" "main" {
  function_name      = aws_lambda_function.main.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = false
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["date", "keep-alive", "Authorization", "Content-Type"]
    expose_headers    = ["date", "keep-alive"]
    max_age          = 86400
  }
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.main.function_name}"
  retention_in_days = 14

  tags = var.tags
}
