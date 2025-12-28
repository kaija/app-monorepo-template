"""Test FastAPI application setup."""

import pytest
from fastapi.testclient import TestClient

from app.main import create_app


def test_create_app():
    """Test that FastAPI app can be created."""
    from app.core.config import get_settings

    app = create_app()
    settings = get_settings()

    assert app is not None
    # App title should match the configured app name
    assert app.title == settings.app_name
    assert app.version == "0.1.0"


def test_app_routes():
    """Test that required routes are registered."""
    app = create_app()

    # Get all routes
    routes = [route.path for route in app.routes]

    # Check that health endpoint exists
    assert "/healthz" in routes

    # Check that items endpoints exist
    assert "/api/items" in routes


@pytest.mark.asyncio
async def test_health_endpoint_structure():
    """Test health endpoint returns correct structure."""
    from unittest.mock import AsyncMock, MagicMock

    from app.api.routes.health import health_check
    from app.core.database import get_db

    # Mock database session
    mock_db = AsyncMock()
    mock_result = MagicMock()
    mock_result.fetchone.return_value = (1,)
    mock_db.execute.return_value = mock_result

    # Call health check
    result = await health_check(mock_db)

    # Verify response structure
    assert "status" in result
    assert "service" in result
    assert "version" in result
    assert "database" in result
    assert result["status"] == "healthy"
    assert result["database"] == "connected"
