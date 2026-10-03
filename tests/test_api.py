from fastapi.testclient import TestClient
from app.api import app

client = TestClient(app)

def test_app_demarre():
    assert app is not None
