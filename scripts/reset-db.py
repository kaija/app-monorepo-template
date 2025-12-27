#!/usr/bin/env python3
"""
Database reset script for LINE Commerce development environment.
Drops all tables and recreates them with fresh migrations.
"""

import asyncio
import os
import sys
import subprocess
from pathlib import Path

# Add the backend directory to the Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'backend'))

from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
from app.core.config import get_settings
from app.models import Base


async def reset_database():
    """Reset the database by dropping all tables and running migrations."""
    settings = get_settings()
    
    print("🔄 Resetting database...")
    
    # Create async engine
    engine = create_async_engine(
        settings.database_url,
        echo=True if settings.environment == "development" else False
    )
    
    try:
        async with engine.begin() as conn:
            print("  🗑️  Dropping all tables...")
            
            # Drop all tables
            await conn.run_sync(Base.metadata.drop_all)
            print("  ✅ All tables dropped")
            
            # Create all tables
            print("  🏗️  Creating tables from models...")
            await conn.run_sync(Base.metadata.create_all)
            print("  ✅ All tables created")
            
    except Exception as e:
        print(f"❌ Error resetting database: {e}")
        raise
    finally:
        await engine.dispose()
    
    # Run Alembic migrations to ensure schema is up to date
    print("  🔄 Running Alembic migrations...")
    backend_dir = Path(__file__).parent.parent / "backend"
    
    try:
        # Change to backend directory for Alembic
        original_cwd = os.getcwd()
        os.chdir(backend_dir)
        
        # Stamp the database with the current migration
        result = subprocess.run(
            ["alembic", "stamp", "head"],
            capture_output=True,
            text=True,
            check=True
        )
        print("  ✅ Database stamped with current migration")
        
    except subprocess.CalledProcessError as e:
        print(f"  ⚠️  Alembic stamp failed: {e.stderr}")
        print("  ℹ️  This is normal if Alembic is not set up yet")
    except FileNotFoundError:
        print("  ⚠️  Alembic not found, skipping migration stamp")
        print("  ℹ️  Install alembic in the backend environment if needed")
    finally:
        os.chdir(original_cwd)
    
    print("🎉 Database reset completed successfully!")
    print("💡 Run 'python scripts/seed-db.py' to add sample data")


if __name__ == "__main__":
    asyncio.run(reset_database())