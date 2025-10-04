# routes/user.py
from fastapi import APIRouter, Depends, HTTPException
from schemas.user import UserRegister, UserLogin, Token, UserRead
from crud.user import register_user, user_login
from dependencies import get_current_user

user_router = APIRouter()

@user_router.post("/register/", response_model=Token)
def register(user: UserRegister):
    access_token = register_user(user)
    return {"access_token": access_token}

@user_router.post("/login/", response_model=Token)
def login(user: UserLogin):
    access_token = user_login(user)
    return {"access_token": access_token}

@user_router.get("/profile/")
def profile(user: UserRead = Depends(get_current_user)):
    return {"message": f"Welcome {user.username}!"}
