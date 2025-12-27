"""Item model for basic data operations."""

from datetime import datetime
from decimal import Decimal
from typing import Optional
from uuid import UUID, uuid4

from sqlalchemy import DateTime, ForeignKey, String, Text, DECIMAL
from sqlalchemy.dialects.postgresql import UUID as PostgresUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.core.database import Base


class Item(Base):
    """Item model for basic CRUD operations."""
    
    __tablename__ = "items"

    id: Mapped[UUID] = mapped_column(
        PostgresUUID(as_uuid=True), 
        primary_key=True, 
        default=uuid4
    )
    name: Mapped[str] = mapped_column(
        String(255), 
        nullable=False,
        index=True
    )
    description: Mapped[Optional[str]] = mapped_column(
        Text, 
        nullable=True
    )
    price: Mapped[Optional[Decimal]] = mapped_column(
        DECIMAL(10, 2), 
        nullable=True
    )
    user_id: Mapped[UUID] = mapped_column(
        PostgresUUID(as_uuid=True), 
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), 
        server_default=func.now(),
        nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), 
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False
    )

    # Relationship to User (optional, for convenience)
    # user: Mapped["User"] = relationship("User", back_populates="items")

    def __repr__(self) -> str:
        return f"<Item(id={self.id}, name={self.name}, user_id={self.user_id})>"