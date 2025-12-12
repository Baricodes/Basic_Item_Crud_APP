output "frontend_s3_bucket" {
  description = "S3 bucket name for frontend files"
  value       = aws_s3_bucket.frontend.bucket
}

output "frontend_s3_bucket_arn" {
  description = "S3 bucket ARN for frontend files"
  value       = aws_s3_bucket.frontend.arn
}

output "frontend_cloudfront_domain" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "frontend_cloudfront_url" {
  description = "CloudFront distribution URL"
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "frontend_deployment_role_arn" {
  description = "IAM role ARN for frontend deployment"
  value       = aws_iam_role.deployment_role.arn
}

output "frontend_cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.frontend.id
}
