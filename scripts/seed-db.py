#!/usr/bin/env python3
"""
Database seeding script for LINE Commerce development environment.
Creates sample data for testing and development.
"""

import asyncio
import os
import sys
from datetime import datetime
from decimal import Decimal
from uuid import uuid4

# Add the backend directory to the Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "backend"))

from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

from app.core.config import get_settings
from app.core.security import get_password_hash
from app.models.item import Item
from app.models.user import User


async def seed_database():
    """Seed the database with sample data."""
    settings = get_settings()

    # Create async engine
    engine = create_async_engine(
        settings.database_url,
        echo=True if settings.environment == "development" else False,
    )

    # Create session factory
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        try:
            print("🌱 Seeding database with sample data...")

            # Create sample users
            users_data = [
                {
                    "email": "admin@linecommerce.com",
                    "password": "admin123",
                    "display_name": "Admin User",
                    "is_active": True,
                },
                {
                    "email": "user1@example.com",
                    "password": "password123",
                    "display_name": "John Doe",
                    "is_active": True,
                },
                {
                    "email": "user2@example.com",
                    "password": "password123",
                    "display_name": "Jane Smith",
                    "is_active": True,
                },
                {
                    "email": "oauth.user@gmail.com",
                    "oauth_provider": "google",
                    "oauth_id": "google_123456789",
                    "display_name": "OAuth User",
                    "avatar_url": "https://example.com/avatar.jpg",
                    "is_active": True,
                },
            ]

            created_users = []
            for user_data in users_data:
                # Check if user already exists
                existing_user = await session.get(User, user_data["email"])
                if existing_user:
                    print(
                        f"  ⚠️  User {user_data['email']} already exists, skipping..."
                    )
                    created_users.append(existing_user)
                    continue

                user = User(
                    id=uuid4(),
                    email=user_data["email"],
                    password_hash=get_password_hash(user_data["password"])
                    if "password" in user_data
                    else None,
                    oauth_provider=user_data.get("oauth_provider"),
                    oauth_id=user_data.get("oauth_id"),
                    display_name=user_data["display_name"],
                    avatar_url=user_data.get("avatar_url"),
                    is_active=user_data["is_active"],
                    created_at=datetime.utcnow(),
                    updated_at=datetime.utcnow(),
                )
                session.add(user)
                created_users.append(user)
                print(f"  ✅ Created user: {user_data['email']}")

            # Commit users first to get their IDs
            await session.commit()

            # Create sample items
            items_data = [
                {
                    "name": "Sample Product 1",
                    "description": "This is a sample product for testing purposes",
                    "price": Decimal("29.99"),
                },
                {
                    "name": "Sample Product 2",
                    "description": "Another sample product with different pricing",
                    "price": Decimal("49.99"),
                },
                {
                    "name": "Free Sample",
                    "description": "A free sample item for testing",
                    "price": Decimal("0.00"),
                },
                {
                    "name": "Premium Product",
                    "description": "A premium product with higher pricing",
                    "price": Decimal("199.99"),
                },
                {
                    "name": "No Price Item",
                    "description": "An item without a price set",
                    "price": None,
                },
            ]

            # Assign items to users (cycle through users)
            for i, item_data in enumerate(items_data):
                user = created_users[i % len(created_users)]

                item = Item(
                    id=uuid4(),
                    name=item_data["name"],
                    description=item_data["description"],
                    price=item_data["price"],
                    user_id=user.id,
                    created_at=datetime.utcnow(),
                    updated_at=datetime.utcnow(),
                )
                session.add(item)
                print(f"  ✅ Created item: {item_data['name']} (owner: {user.email})")

            await session.commit()

            print("🎉 Database seeding completed successfully!")
            print(f"   - Created {len(created_users)} users")
            print(f"   - Created {len(items_data)} items")
            print("\n📝 Sample credentials:")
            print("   - admin@linecommerce.com / admin123")
            print("   - user1@example.com / password123")
            print("   - user2@example.com / password123")

        except Exception as e:
            await session.rollback()
            print(f"❌ Error seeding database: {e}")
            raise
        finally:
            await engine.dispose()


if __name__ == "__main__":
    asyncio.run(seed_database())
