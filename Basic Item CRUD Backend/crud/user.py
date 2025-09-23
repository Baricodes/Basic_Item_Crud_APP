#crud/user.py
from fastapi import HTTPException, status
from boto3.dynamodb.conditions import Key
from uuid import uuid4

from schemas.user import UserRegister, UserLogin, Token
from core.security import verify_password, hash_password, create_access_token
from db import user_table
import logging

log = logging.getLogger("app.crud.user")


def register_user(user: UserRegister) -> Token:
    # Query the users table by username using the username GSI (Global Secondary Index)
    response = user_table.query(
        IndexName="username-index",
        KeyConditionExpression=Key("username").eq(user.username)
    )

    # If any user is returned, that means the username already exists
    if response["Items"]:
        # Raise an HTTP 400 error if the username is already taken
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username already registered"
        )

    # Generate a new unique user ID using UUID
    user_id = str(uuid4())

    # Hash the provided password before storing
    hashed_pw = hash_password(user.password)

    # Prepare the user data to insert into DynamoDB
    user_item = {
        "id": user_id,
        "username": user.username,
        "hashed_password": hashed_pw,
    }

    # Add the new user to the DynamoDB table
    user_table.put_item(Item=user_item)

    # Create an access token using the user ID as subject
    access_token = create_access_token(data={"sub": user_id})

    # Return the access token to the client
    return access_token


def user_login(user: UserLogin) -> Token:
    # Query the users table by username using the username GSI
    response = user_table.query(
        IndexName="username-index",
        KeyConditionExpression=Key("username").eq(user.username)
    )

    # If no user is found, return invalid credentials error
    if not response["Items"]:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    # Extract the matched user from the response
    db_user = response["Items"][0]

    # Verify the provided password against the stored hash
    if not verify_password(user.password, db_user["hashed_password"]):
        # Raise HTTP 401 if password doesn't match
        raise HTTPException(status_code=401, detail="Invalid credentials")

    # Create an access token using the user's ID
    access_token = create_access_token(data={"sub": db_user["id"]})

    # Return the access token to the client
    return access_token
