# tests/test_user.py
import pytest
from fastapi.testclient import TestClient
from starlette import status

from main import app

client = TestClient(app)


@pytest.fixture(scope="module")
def test_client():
    return client


def test_create_user(test_client):
    response = test_client.post("/user/register/", json={
        "username": "John",
        "password": "password123"
    })

    print("\nTest Create JSON RESPONSE: ", response.json())

    if response.json()['detail'] == "Username already registered":
        assert response.status_code == 400
    else:
        assert response.status_code == 201


def test_login_and_get_profile(test_client):
    # First, login
    response = test_client.post(
        "/user/login/", json={
            "username": "John",
            "password": "password123"}
    )

    print("\nTest Login JSON RESPONSE: ", response.json())

    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data

    token = data["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Then, get profile
    response = test_client.get("/user/profile/", headers=headers)
    assert response.status_code == 200
    print(response.json())
