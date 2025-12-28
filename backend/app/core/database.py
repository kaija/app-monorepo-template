"""Database configuration and session management."""

import os
from typing import AsyncGenerator

from sqlalchemy import create_engine
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from sqlalchemy.pool import NullPool

# Database URL from environment variable
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+asyncpg://postgres:postgres@localhost:5432/line_commerce",
)

# Convert sync postgres URL to async if needed
if DATABASE_URL.startswith("postgresql://"):
    DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://", 1)

# Create sync URL for migrations and table creation
SYNC_DATABASE_URL = DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")

# Create async engine
engine = create_async_engine(
    DATABASE_URL,
    poolclass=NullPool,  # Use NullPool for better connection handling
    echo=os.getenv("DATABASE_ECHO", "false").lower() == "true",
)

# Create sync engine for migrations and table creation
sync_engine = create_engine(
    SYNC_DATABASE_URL,
    poolclass=NullPool,
    echo=os.getenv("DATABASE_ECHO", "false").lower() == "true",
)

# Create async session maker
AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

# Create sync session maker for migrations
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=sync_engine)

# Create declarative base
Base = declarative_base()


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Dependency to get database session."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


def create_tables() -> None:
    """Create database tables synchronously."""
    # Import all models to ensure they are registered with Base
    from app.models.item import Item  # noqa: F401
    from app.models.merchant import Merchant  # noqa: F401
    from app.models.order import Order  # noqa: F401
    from app.models.product import Product  # noqa: F401
    from app.models.user import User  # noqa: F401

    Base.metadata.create_all(bind=sync_engine)


async def init_db() -> None:
    """Initialize database tables."""
    async with engine.begin() as conn:
        # Import all models to ensure they are registered with Base
        from app.models.item import Item  # noqa: F401
        from app.models.merchant import Merchant  # noqa: F401
        from app.models.order import Order  # noqa: F401
        from app.models.product import Product  # noqa: F401
        from app.models.user import User  # noqa: F401

        await conn.run_sync(Base.metadata.create_all)


async def close_db() -> None:
    """Close database connections."""
    await engine.dispose()
    sync_engine.dispose()
