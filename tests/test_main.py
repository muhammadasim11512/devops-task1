import pytest
from fastapi.testclient import TestClient
import sys,os
sys.path.insert(0,os.path.join(os.path.dirname(__file__),'..','backend'))
from main import app
client=TestClient(app)
def test_health_check():
    r=client.get("/health")
    assert r.status_code==200
    assert "status" in r.json()
def test_register_user():
    r=client.post("/api/register",json={"username":"testuser","email":"test@example.com","password":"testpass123"})
    assert r.status_code in[201,400]
def test_login_invalid():
    r=client.post("/api/login",json={"username":"nonexistent","password":"wrongpass"})
    assert r.status_code==401
def test_profile_without_auth():
    r=client.get("/api/profile")
    assert r.status_code==403
