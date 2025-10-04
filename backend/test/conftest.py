import boto3
import pytest
import os
from botocore.exceptions import ClientError

@pytest.fixture(scope="session", autouse=True)
def setup_dynamodb():
    os.environ["LOCAL_TESTING"] = "1"

    # Connect to DynamoDB Local (running in Docker)
    dynamodb = boto3.resource(
        "dynamodb",
        endpoint_url="http://localhost:8000",  # docker container mapped to host
        region_name="us-east-1",
    )

    def create_table_if_not_exists(table_name, key_schema, attribute_definitions, global_secondary_indexes=None):
        try:
            table = dynamodb.Table(table_name)
            table.load()
            print(f"ℹ️ DynamoDB table '{table_name}' already exists.")
        except ClientError as e:
            if e.response["Error"]["Code"] == "ResourceNotFoundException":
                print(f"🛠 Creating DynamoDB table '{table_name}'...")
                params = {
                    "TableName": table_name,
                    "KeySchema": key_schema,
                    "AttributeDefinitions": attribute_definitions,
                    "BillingMode": "PAY_PER_REQUEST"
                }
                if global_secondary_indexes:
                    params["GlobalSecondaryIndexes"] = global_secondary_indexes
                table = dynamodb.create_table(**params)
                table.wait_until_exists()
                print(f"✅ DynamoDB table '{table_name}' created.")
            else:
                raise

    # Create "users" table
    create_table_if_not_exists(
        table_name="users",
        key_schema=[{"AttributeName": "id", "KeyType": "HASH"}],
        attribute_definitions=[
            {"AttributeName": "id", "AttributeType": "S"},
            {"AttributeName": "username", "AttributeType": "S"}
        ],
        global_secondary_indexes=[
            {
                "IndexName": "username-index",
                "KeySchema": [{"AttributeName": "username", "KeyType": "HASH"}],
                "Projection": {"ProjectionType": "ALL"},
                "ProvisionedThroughput": {
                    "ReadCapacityUnits": 5,
                    "WriteCapacityUnits": 5,
                },
            }
        ]
    )

    # Create "items" table
    create_table_if_not_exists(
        table_name="items",
        key_schema=[{"AttributeName": "id", "KeyType": "HASH"}],
        attribute_definitions=[
            {"AttributeName": "id", "AttributeType": "S"},
            {"AttributeName": "owner_id", "AttributeType": "S"}
        ],
        global_secondary_indexes=[
            {
                "IndexName": "owner_id-index",
                "KeySchema": [{"AttributeName": "owner_id", "KeyType": "HASH"}],
                "Projection": {"ProjectionType": "ALL"},
                "ProvisionedThroughput": {
                    "ReadCapacityUnits": 5,
                    "WriteCapacityUnits": 5,
                },
            }
        ]
    )

    yield
