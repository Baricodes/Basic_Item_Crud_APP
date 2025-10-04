# DynamoDB table for users
resource "aws_dynamodb_table" "users" {
  name           = "${var.app_name}-${var.environment}-users"
  billing_mode   = var.dynamodb_billing_mode
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "username"
    type = "S"
  }

  global_secondary_index {
    name            = "username-index"
    hash_key        = "username"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(var.tags, {
    Name = "${var.app_name}-${var.environment}-users"
  })
}

# DynamoDB table for items
resource "aws_dynamodb_table" "items" {
  name           = "${var.app_name}-${var.environment}-items"
  billing_mode   = var.dynamodb_billing_mode
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "owner_id"
    type = "S"
  }

  global_secondary_index {
    name            = "owner-id-index"
    hash_key        = "owner_id"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(var.tags, {
    Name = "${var.app_name}-${var.environment}-items"
  })
}
