import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

@pytest.fixture(scope="module")
def test_client():
    return client


@pytest.fixture(scope="module")
def auth_token(test_client):
    # Register user
    test_client.post(
        "/user/register/",
        json={"username": "John", "password": "password123"}
    )

    # Login
    response = test_client.post(
        "/user/login/",
        json={"username": "John", "password": "password123"}
    )
    assert response.status_code == 200
    return response.json()["access_token"]


@pytest.fixture(scope="module")
def created_item_id(test_client, auth_token):
    headers = {"Authorization": f"Bearer {auth_token}"}
    response = test_client.post(
        "/item/create/",
        headers=headers,
        json={"name": "Test item", "description": "Test description"}
    )

    assert response.status_code == 200
    data = response.json()
    assert "id" in data, "Create endpoint must return the item ID"
    return data["id"]


def test_create_item(created_item_id):
    # Just verifies the fixture worked
    assert created_item_id is not None


def test_update_item(test_client, auth_token, created_item_id):
    headers = {"Authorization": f"Bearer {auth_token}"}
    response = test_client.put(
        f"/item/update/{created_item_id}",
        headers=headers,
        json={"name": "Updated Item", "description": "Updated Description"}
    )

    print("Status:", response.status_code)
    print("Body:", response.json())
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "Updated Item"
    assert data["description"] == "Updated Description"


def test_read_item(test_client, auth_token):
    headers = {"Authorization": f"Bearer {auth_token}"}
    response = test_client.get("/item/read/", headers=headers)

    print("Status:", response.status_code)
    print("Body:", response.json())
    assert response.status_code == 200
    data = response.json()
    assert any(item["name"] == "Updated Item" for item in data)


def test_delete_item(test_client, auth_token, created_item_id):
    headers = {"Authorization": f"Bearer {auth_token}"}
    response = test_client.delete(
        f"/item/delete/{created_item_id}",
        headers=headers
    )

    assert response.status_code == 204
