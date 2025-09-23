from fastapi import APIRouter, Depends
from schemas.item import ItemCreate, ItemRead, ItemUpdate
from schemas.user import UserRead
from crud.item import create_item, get_items, update_item, delete_item
from dependencies import get_current_user

item_router = APIRouter()

@item_router.post("/create/", response_model=ItemRead)
def create_new_item(item: ItemCreate,
    current_user: UserRead = Depends(get_current_user)):
    return create_item(item, current_user)


@item_router.get("/read/", response_model=list[ItemRead])
def read_items(current_user: UserRead = Depends(get_current_user)):
    return get_items(current_user)


@item_router.put("/update/{item_id}", response_model=ItemRead)
def item_update(item_id: str,
    item: ItemUpdate,
    current_user: UserRead = Depends(get_current_user)):
    return update_item(item_id, item, current_user)


@item_router.delete("/delete/{item_id}", response_model=ItemRead)
def item_delete(item_id: str,
    current_user: UserRead = Depends(get_current_user)):
    return delete_item(item_id, current_user)
