"""Main FastAPI application with environment validation."""

from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import auth, health, items
from app.core.config import get_settings
from app.core.database import close_db, init_db

# Settings are validated during import
settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Application lifespan manager."""
    # Startup
    print(f"🚀 Starting {settings.app_name} v{settings.app_version}")
    print(f"   Environment: {settings.environment}")
    print(f"   Debug mode: {settings.debug}")
    print(f"   OAuth enabled: {settings.oauth_enabled()}")

    await init_db()
    print("✅ Database initialized successfully")

    yield

    # Shutdown
    print("🛑 Shutting down application...")
    await close_db()
    print("✅ Database connections closed")


def create_app() -> FastAPI:
    """Create and configure FastAPI application."""
    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        description="LINE Commerce Backend API with comprehensive environment configuration",
        lifespan=lifespan,
        debug=settings.debug,
    )

    # Add CORS middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Include routers
    app.include_router(health.router, tags=["health"])
    app.include_router(auth.router, prefix="/api/auth", tags=["authentication"])
    app.include_router(items.router, prefix="/api", tags=["items"])

    return app


# Create app instance
app = create_app()


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.debug,
        log_level=settings.log_level.value,
    )
