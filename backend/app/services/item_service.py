"""Item service for business logic."""

from typing import Optional, Tuple
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.item import Item
from app.repositories.item_repository import ItemRepository
from app.schemas.item import ItemCreate, ItemUpdate


class ItemService:
    """Service for item business logic."""

    def __init__(self, db: AsyncSession):
        self.repository = ItemRepository(db)

    async def create_item(self, item_data: ItemCreate, user_id: UUID) -> Item:
        """Create a new item."""
        return await self.repository.create_item(item_data, user_id)

    async def get_item(self, item_id: UUID) -> Optional[Item]:
        """Get an item by ID."""
        return await self.repository.get_item_by_id(item_id)

    async def get_user_items(
        self, 
        user_id: UUID, 
        page: int = 1, 
        per_page: int = 20
    ) -> Tuple[list[Item], int]:
        """Get items for a specific user with pagination."""
        if page < 1:
            page = 1
        if per_page < 1 or per_page > 100:
            per_page = 20

        return await self.repository.get_items_by_user(user_id, page, per_page)

    async def get_all_items(
        self, 
        page: int = 1, 
        per_page: int = 20
    ) -> Tuple[list[Item], int]:
        """Get all items with pagination."""
        if page < 1:
            page = 1
        if per_page < 1 or per_page > 100:
            per_page = 20

        return await self.repository.get_all_items(page, per_page)

    async def update_item(
        self, 
        item_id: UUID, 
        item_data: ItemUpdate, 
        user_id: UUID
    ) -> Optional[Item]:
        """Update an item (only by owner)."""
        return await self.repository.update_item(item_id, item_data, user_id)

    async def delete_item(self, item_id: UUID, user_id: UUID) -> bool:
        """Delete an item (only by owner)."""
        return await self.repository.delete_item(item_id, user_id)