"""Item repository for database operations."""

from typing import Optional, Tuple
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.item import Item
from app.schemas.item import ItemCreate, ItemUpdate


class ItemRepository:
    """Repository for item database operations."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_item(self, item_data: ItemCreate, user_id: UUID) -> Item:
        """Create a new item."""
        item = Item(
            name=item_data.name,
            description=item_data.description,
            price=item_data.price,
            user_id=user_id,
        )
        self.db.add(item)
        await self.db.commit()
        await self.db.refresh(item)
        return item

    async def get_item_by_id(self, item_id: UUID) -> Optional[Item]:
        """Get item by ID."""
        result = await self.db.execute(
            select(Item).where(Item.id == item_id)
        )
        return result.scalar_one_or_none()

    async def get_items_by_user(
        self, 
        user_id: UUID, 
        page: int = 1, 
        per_page: int = 20
    ) -> Tuple[list[Item], int]:
        """Get items by user with pagination."""
        # Get total count
        count_result = await self.db.execute(
            select(func.count(Item.id)).where(Item.user_id == user_id)
        )
        total = count_result.scalar() or 0

        # Get items with pagination
        offset = (page - 1) * per_page
        result = await self.db.execute(
            select(Item)
            .where(Item.user_id == user_id)
            .order_by(Item.created_at.desc())
            .offset(offset)
            .limit(per_page)
        )
        items = result.scalars().all()

        return list(items), total

    async def get_all_items(
        self, 
        page: int = 1, 
        per_page: int = 20
    ) -> Tuple[list[Item], int]:
        """Get all items with pagination."""
        # Get total count
        count_result = await self.db.execute(
            select(func.count(Item.id))
        )
        total = count_result.scalar() or 0

        # Get items with pagination
        offset = (page - 1) * per_page
        result = await self.db.execute(
            select(Item)
            .order_by(Item.created_at.desc())
            .offset(offset)
            .limit(per_page)
        )
        items = result.scalars().all()

        return list(items), total

    async def update_item(
        self, 
        item_id: UUID, 
        item_data: ItemUpdate, 
        user_id: UUID
    ) -> Optional[Item]:
        """Update an item (only by owner)."""
        item = await self.get_item_by_id(item_id)
        if not item or item.user_id != user_id:
            return None

        for field, value in item_data.model_dump(exclude_unset=True).items():
            setattr(item, field, value)

        await self.db.commit()
        await self.db.refresh(item)
        return item

    async def delete_item(self, item_id: UUID, user_id: UUID) -> bool:
        """Delete an item (only by owner)."""
        item = await self.get_item_by_id(item_id)
        if not item or item.user_id != user_id:
            return False

        await self.db.delete(item)
        await self.db.commit()
        return True