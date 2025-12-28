"""Product model for future e-commerce functionality."""

from datetime import datetime
from decimal import Decimal
from typing import Optional
from uuid import UUID, uuid4

from sqlalchemy import DECIMAL, Boolean, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import UUID as PostgresUUID
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func

from app.core.database import Base


class Product(Base):
    """Product model for e-commerce catalog management.

    This is a stub model for future development. Additional fields
    should be added based on specific business requirements such as
    categories, variants, inventory tracking, etc.
    """

    __tablename__ = "products"

    id: Mapped[UUID] = mapped_column(
        PostgresUUID(as_uuid=True), primary_key=True, default=uuid4
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    price: Mapped[Optional[Decimal]] = mapped_column(DECIMAL(10, 2), nullable=True)
    sku: Mapped[Optional[str]] = mapped_column(
        String(100), nullable=True, unique=True, index=True
    )
    stock_quantity: Mapped[Optional[int]] = mapped_column(
        Integer, nullable=True, default=0
    )
    merchant_id: Mapped[UUID] = mapped_column(
        PostgresUUID(as_uuid=True),
        ForeignKey("merchants.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    # Future relationships can be added here:
    # merchant: Mapped["Merchant"] = relationship("Merchant", back_populates="products")
    # categories: Mapped[List["Category"]] = relationship("Category", secondary="product_categories")

    def __repr__(self) -> str:
        return (
            f"<Product(id={self.id}, name={self.name}, merchant_id={self.merchant_id})>"
        )
