#!/usr/bin/env python3
"""Initialize backend database and run migrations."""

import asyncio
import os
import sys
from pathlib import Path

# Add backend directory to Python path
backend_dir = Path(__file__).parent.parent / "backend"
sys.path.insert(0, str(backend_dir))

from alembic import command
from alembic.config import Config
from app.core.database import engine, init_db


async def init_database():
    """Initialize database with tables."""
    print("🔄 Initializing database...")
    
    try:
        # Initialize database tables
        await init_db()
        print("✅ Database tables created successfully")
        
    except Exception as e:
        print(f"❌ Error initializing database: {e}")
        return False
    
    return True


def run_migrations():
    """Run Alembic migrations."""
    print("🔄 Running database migrations...")
    
    try:
        # Get Alembic configuration
        alembic_cfg = Config(str(backend_dir / "alembic.ini"))
        
        # Set the database URL from environment
        database_url = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/line_commerce")
        alembic_cfg.set_main_option("sqlalchemy.url", database_url)
        
        # Run migrations
        command.upgrade(alembic_cfg, "head")
        print("✅ Migrations completed successfully")
        
    except Exception as e:
        print(f"❌ Error running migrations: {e}")
        return False
    
    return True


async def main():
    """Main initialization function."""
    print("🚀 Starting LINE Commerce backend initialization...")
    
    # Run migrations
    if not run_migrations():
        sys.exit(1)
    
    # Initialize database
    if not await init_database():
        sys.exit(1)
    
    # Close database connections
    await engine.dispose()
    
    print("✅ Backend initialization completed successfully!")


if __name__ == "__main__":
    asyncio.run(main())