"""Health check endpoints."""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies import DatabaseSession
from app.core.config import get_settings

router = APIRouter()
settings = get_settings()


@router.get("/healthz")
async def health_check(db: AsyncSession = Depends(DatabaseSession)) -> dict[str, str]:
    """
    Health check endpoint.
    
    Returns:
        dict: Health status including database connectivity
        
    Raises:
        HTTPException: If health check fails
    """
    try:
        # Test database connectivity
        result = await db.execute(text("SELECT 1"))
        result.fetchone()
        
        return {
            "status": "healthy",
            "service": settings.app_name,
            "version": settings.app_version,
            "database": "connected"
        }
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail={
                "status": "unhealthy",
                "service": settings.app_name,
                "version": settings.app_version,
                "database": "disconnected",
                "error": str(e)
            }
        )