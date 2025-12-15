from fastapi import Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from core.config import ALGORITHM, SECRET_KEY
from db import user_table
from schemas.user import UserRead
import logging


log = logging.getLogger("app.dependencies")

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/user/login/")

def get_current_user(token: str = Depends(oauth2_scheme)) -> UserRead:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(status_code=401, detail="Invalid credentials")
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")

    # Get user from DynamoDB
    try:
        response = user_table.get_item(Key={"id": user_id})
        user = response.get("Item")
    except Exception:
        raise HTTPException(status_code=500, detail="Error fetching user from DB")

    if user is None:
        raise HTTPException(status_code=401, detail="User not found")

    return UserRead(**user)
