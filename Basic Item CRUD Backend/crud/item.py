#crud/items.py
from boto3.dynamodb.conditions import Key
from fastapi import HTTPException, Response
from uuid import uuid4
import logging

from schemas.user import UserRead
from db import item_table
from schemas.item import ItemCreate, ItemUpdate, ItemRead

log = logging.getLogger("app.crud.items")

# Create an item with owner_id
def create_item(item_data: ItemCreate,
                user: UserRead) -> ItemCreate:
    if not user.id:
        raise ValueError("User is missing an id, cannot create item")


    item_id = str(uuid4())
    item = {
        "id": item_id,
        "owner_id": user.id,   # Required for GSI
        **item_data.model_dump()
    }
    item_table.put_item(Item=item)
    return item


# Get all items for a given owner_id
def get_items(user: UserRead):
    response = item_table.query(
        IndexName="owner_id-index",
        KeyConditionExpression=Key("owner_id").eq(user.id)
    )
    items = response.get("Items", [])
    if not items:
        raise HTTPException(status_code=404, detail="No items found for this owner")

    return items


# Update ONE item, but only if owner matches
def update_item(item_id: str,
                update_data: ItemUpdate,
                user: UserRead) -> ItemRead:
    # Get the item
    response = item_table.get_item(Key={"id": item_id})
    item = response.get("Item")
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")

    # Ownership check
    if item["owner_id"] != user.id:
        raise HTTPException(status_code=403, detail="Not authorized to update this item")

    # Build update expression
    expression = "SET " + ", ".join(f"#{k} = :{k}" for k in update_data.model_dump().keys())
    expression_names = {f"#{k}": k for k in update_data.model_dump().keys()}
    expression_values = {f":{k}": v for k, v in update_data.model_dump().items()}

    # Perform update and return updated item
    update_response = item_table.update_item(
        Key={"id": item_id},
        UpdateExpression=expression,
        ExpressionAttributeNames=expression_names,
        ExpressionAttributeValues=expression_values,
        ReturnValues="ALL_NEW"  # ✅ This tells DynamoDB to return the updated record
    )

    # Extract the updated item from the response
    updated_item = update_response.get("Attributes")
    if not updated_item:
        raise HTTPException(status_code=500, detail="Failed to retrieve updated item")

    return ItemRead(**updated_item)


def delete_item(item_id: str, user: UserRead):
    # First, get the specific item by ID
    response = item_table.get_item(Key={"id": item_id})
    item = response.get("Item")

    if not item:
        raise HTTPException(status_code=404, detail="Item not found")

    # Check that the item belongs to the current user
    if item.get("owner_id") != user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this item")

    # Delete the item
    item_table.delete_item(Key={"id": item_id})

    return Response(status_code=204)