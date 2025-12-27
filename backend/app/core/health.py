"""Health check utilities for database and services."""

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db


async def check_database_health() -> dict[str, str]:
    """Check database connectivity and return health status."""
    try:
        # Get database session
        async for db in get_db():
            # Execute a simple query to test connectivity
            result = await db.execute(text("SELECT 1 as health_check"))
            row = result.fetchone()
            
            if row and row[0] == 1:
                return {
                    "status": "healthy",
                    "database": "connected",
                    "message": "Database connection successful"
                }
            else:
                return {
                    "status": "unhealthy",
                    "database": "error",
                    "message": "Database query returned unexpected result"
                }
                
    except Exception as e:
        return {
            "status": "unhealthy",
            "database": "disconnected",
            "message": f"Database connection failed: {str(e)}"
        }


async def get_health_status() -> dict[str, any]:
    """Get comprehensive health status of the application."""
    db_health = await check_database_health()
    
    return {
        "app": "LINE Commerce API",
        "version": "0.1.0",
        "status": db_health["status"],
        "checks": {
            "database": db_health
        }
    }