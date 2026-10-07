import pytest
from app.app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_home(client):
    rv = client.get('/')
    assert rv.status_code == 200
    assert b"OrderHub API" in rv.data

def test_health(client):
    rv = client.get('/health')
    assert rv.status_code == 200
    assert rv.json["status"] == "UP"

def test_orders(client):
    rv = client.get('/orders')
    assert rv.status_code == 200
    assert len(rv.json) == 2