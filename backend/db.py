# db.py
import os
import boto3

AWS_REGION = os.getenv("REGION", "us-east-2")

def get_dynamodb():
    if os.getenv("LOCAL_TESTING") == "1":
        return boto3.resource(
            "dynamodb",
            region_name="us-east-1",
            endpoint_url="http://localhost:8000"
        )
    return boto3.resource("dynamodb", region_name=AWS_REGION)

dynamodb = get_dynamodb()

# Optional: define tables here for convenience
# Use environment variables for table names to match Terraform configuration
USERS_TABLE = os.getenv("USERS_TABLE")
ITEMS_TABLE = os.getenv("ITEMS_TABLE")

if not USERS_TABLE or not ITEMS_TABLE:
    raise ValueError("USERS_TABLE and ITEMS_TABLE environment variables must be set")

user_table = dynamodb.Table(USERS_TABLE)
item_table = dynamodb.Table(ITEMS_TABLE)
