"""Items API endpoints."""

from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies import DatabaseSession, get_current_active_user
from app.models.user import User
from app.schemas.item import ItemCreate, ItemListResponse, ItemResponse, ItemUpdate
from app.services.item_service import ItemService

router = APIRouter()


def get_item_service(db: AsyncSession = Depends(DatabaseSession)) -> ItemService:
    """Get item service dependency."""
    return ItemService(db)


@router.post("/items", response_model=ItemResponse, status_code=201)
async def create_item(
    item_data: ItemCreate,
    current_user: User = Depends(get_current_active_user),
    item_service: ItemService = Depends(get_item_service),
) -> ItemResponse:
    """
    Create a new item.

    Args:
        item_data: Item creation data
        current_user: Current authenticated user
        item_service: Item service dependency

    Returns:
        ItemResponse: Created item data
    """
    try:
        item = await item_service.create_item(item_data, current_user.id)
        return ItemResponse.model_validate(item)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to create item: {str(e)}")


@router.get("/items", response_model=ItemListResponse)
async def get_items(
    page: int = Query(1, ge=1, description="Page number"),
    per_page: int = Query(20, ge=1, le=100, description="Items per page"),
    user_id: Optional[UUID] = Query(None, description="Filter by user ID"),
    item_service: ItemService = Depends(get_item_service),
) -> ItemListResponse:
    """
    Get items with pagination.

    Args:
        page: Page number (1-based)
        per_page: Number of items per page (1-100)
        user_id: Optional user ID filter
        item_service: Item service dependency

    Returns:
        ItemListResponse: Paginated list of items
    """
    try:
        if user_id:
            items, total = await item_service.get_user_items(user_id, page, per_page)
        else:
            items, total = await item_service.get_all_items(page, per_page)

        # Calculate pagination info
        total_pages = (total + per_page - 1) // per_page
        has_next = page < total_pages
        has_prev = page > 1

        return ItemListResponse(
            items=[ItemResponse.model_validate(item) for item in items],
            total=total,
            page=page,
            per_page=per_page,
            has_next=has_next,
            has_prev=has_prev,
        )
    except Exception as e:
        raise HTTPException(
            status_code=400, detail=f"Failed to retrieve items: {str(e)}"
        )


@router.get("/items/{item_id}", response_model=ItemResponse)
async def get_item(
    item_id: UUID,
    item_service: ItemService = Depends(get_item_service),
) -> ItemResponse:
    """
    Get a specific item by ID.

    Args:
        item_id: Item UUID
        item_service: Item service dependency

    Returns:
        ItemResponse: Item data

    Raises:
        HTTPException: If item not found
    """
    item = await item_service.get_item(item_id)
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")

    return ItemResponse.model_validate(item)


@router.put("/items/{item_id}", response_model=ItemResponse)
async def update_item(
    item_id: UUID,
    item_data: ItemUpdate,
    current_user: User = Depends(get_current_active_user),
    item_service: ItemService = Depends(get_item_service),
) -> ItemResponse:
    """
    Update an item.

    Args:
        item_id: Item UUID
        item_data: Item update data
        current_user: Current authenticated user
        item_service: Item service dependency

    Returns:
        ItemResponse: Updated item data

    Raises:
        HTTPException: If item not found or user not authorized
    """
    item = await item_service.update_item(item_id, item_data, current_user.id)
    if not item:
        raise HTTPException(
            status_code=404,
            detail="Item not found or you don't have permission to update it",
        )

    return ItemResponse.model_validate(item)


@router.delete("/items/{item_id}", status_code=204)
async def delete_item(
    item_id: UUID,
    current_user: User = Depends(get_current_active_user),
    item_service: ItemService = Depends(get_item_service),
) -> None:
    """
    Delete an item.

    Args:
        item_id: Item UUID
        current_user: Current authenticated user
        item_service: Item service dependency

    Raises:
        HTTPException: If item not found or user not authorized
    """
    success = await item_service.delete_item(item_id, current_user.id)
    if not success:
        raise HTTPException(
            status_code=404,
            detail="Item not found or you don't have permission to delete it",
        )
