"""Merchant model for future e-commerce functionality."""

from datetime import datetime
from typing import Optional
from uuid import UUID, uuid4

from sqlalchemy import DateTime, String, Text, Boolean
from sqlalchemy.dialects.postgresql import UUID as PostgresUUID
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func

from app.core.database import Base


class Merchant(Base):
    """Merchant model for e-commerce vendor management.
    
    This is a stub model for future development. Additional fields
    should be added based on specific business requirements.
    """
    
    __tablename__ = "merchants"

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
    contact_email: Mapped[Optional[str]] = mapped_column(
        String(255), 
        nullable=True,
        index=True
    )
    website_url: Mapped[Optional[str]] = mapped_column(
        String(500), 
        nullable=True
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, 
        default=True, 
        nullable=False
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

    def __repr__(self) -> str:
        return f"<Merchant(id={self.id}, name={self.name})>"