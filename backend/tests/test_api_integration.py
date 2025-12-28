"""Integration tests for API endpoints."""

import pytest
from fastapi.testclient import TestClient

from app.main import create_app


@pytest.fixture
def client():
    """Create test client."""
    app = create_app()
    return TestClient(app)


def test_openapi_docs(client):
    """Test that OpenAPI documentation is available."""
    response = client.get("/docs")
    assert response.status_code == 200

    response = client.get("/openapi.json")
    assert response.status_code == 200

    openapi_spec = response.json()
    assert "paths" in openapi_spec
    assert "/healthz" in openapi_spec["paths"]
    assert "/api/items" in openapi_spec["paths"]


def test_cors_headers(client):
    """Test CORS headers are properly configured."""
    response = client.options(
        "/healthz",
        headers={
            "Origin": "http://localhost:3000",
            "Access-Control-Request-Method": "GET",
        },
    )
    # CORS preflight should be handled
    assert response.status_code in [200, 204]


def test_app_metadata():
    """Test application metadata is correctly configured."""
    app = create_app()
    assert app.title == "LINE Commerce API"
    assert app.version == "0.1.0"
    assert "LINE Commerce Backend API" in app.description
