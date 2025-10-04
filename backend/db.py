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
user_table = dynamodb.Table("users")
item_table = dynamodb.Table("items")
