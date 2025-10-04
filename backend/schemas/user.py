# user.py
from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime

class UserCredentials(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=6, max_length=128)

class UserRegister(UserCredentials):
    pass


class UserLogin(UserCredentials):
    pass

class UserRead(BaseModel):
    id: str
    username: str

    model_config = ConfigDict(from_attributes=True)

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_at: datetime | None = None  # optional expiry metadata