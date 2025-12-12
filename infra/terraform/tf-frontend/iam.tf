# IAM role for CloudFront to access S3
resource "aws_iam_role" "cloudfront_s3_role" {
  name = "${var.app_name}-${var.environment}-cloudfront-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM policy for CloudFront to access S3
resource "aws_iam_policy" "cloudfront_s3_policy" {
  name        = "${var.app_name}-${var.environment}-cloudfront-s3-policy"
  description = "Policy for CloudFront to access S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })

  tags = var.tags
}

# Attach policy to CloudFront role
resource "aws_iam_role_policy_attachment" "cloudfront_s3_policy_attachment" {
  role       = aws_iam_role.cloudfront_s3_role.name
  policy_arn = aws_iam_policy.cloudfront_s3_policy.arn
}

# IAM role for deployment (S3 uploads)
resource "aws_iam_role" "deployment_role" {
  name = "${var.app_name}-${var.environment}-deployment-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM policy for deployment (S3 uploads and CloudFront invalidation)
resource "aws_iam_policy" "deployment_policy" {
  name        = "${var.app_name}-${var.environment}-deployment-policy"
  description = "Policy for deploying frontend files to S3 and invalidating CloudFront"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.frontend.arn,
          "${aws_s3_bucket.frontend.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation"
        ]
        Resource = aws_cloudfront_distribution.frontend.arn
      }
    ]
  })

  tags = var.tags
}

# Attach policy to deployment role
resource "aws_iam_role_policy_attachment" "deployment_policy_attachment" {
  role       = aws_iam_role.deployment_role.name
  policy_arn = aws_iam_policy.deployment_policy.arn
}
