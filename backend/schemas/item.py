# item.py
from pydantic import BaseModel, ConfigDict
from typing import Optional

class ItemBase(BaseModel):
    name: str
    description: str

    model_config = ConfigDict(from_attributes=True)

class ItemCreate(ItemBase):
    pass

class ItemRead(ItemBase):
    id: str
    owner_id: str

class ItemUpdate(BaseModel):
    name: Optional[str]
    description: Optional[str]