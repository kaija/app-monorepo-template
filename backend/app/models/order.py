"""Order model for future e-commerce functionality."""

from datetime import datetime
from decimal import Decimal
from enum import Enum
from typing import Optional
from uuid import UUID, uuid4

from sqlalchemy import DECIMAL, DateTime
from sqlalchemy import Enum as SQLEnum
from sqlalchemy import ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID as PostgresUUID
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func

from app.core.database import Base


class OrderStatus(str, Enum):
    """Order status enumeration for tracking order lifecycle."""

    PENDING = "pending"
    CONFIRMED = "confirmed"
    PROCESSING = "processing"
    SHIPPED = "shipped"
    DELIVERED = "delivered"
    CANCELLED = "cancelled"
    REFUNDED = "refunded"


class Order(Base):
    """Order model for e-commerce transaction management.

    This is a stub model for future development. Additional fields
    should be added based on specific business requirements such as
    shipping addresses, payment methods, order items, etc.
    """

    __tablename__ = "orders"

    id: Mapped[UUID] = mapped_column(
        PostgresUUID(as_uuid=True), primary_key=True, default=uuid4
    )
    order_number: Mapped[Optional[str]] = mapped_column(
        String(50), nullable=True, unique=True, index=True
    )
    user_id: Mapped[UUID] = mapped_column(
        PostgresUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    status: Mapped[OrderStatus] = mapped_column(
        SQLEnum(OrderStatus, name="order_status"),
        default=OrderStatus.PENDING,
        nullable=False,
        index=True,
    )
    total_amount: Mapped[Optional[Decimal]] = mapped_column(
        DECIMAL(10, 2), nullable=True
    )
    currency: Mapped[Optional[str]] = mapped_column(
        String(3), nullable=True, default="USD"
    )
    notes: Mapped[Optional[str]] = mapped_column(String(1000), nullable=True)
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
    # user: Mapped["User"] = relationship("User", back_populates="orders")
    # order_items: Mapped[List["OrderItem"]] = relationship("OrderItem", back_populates="order")

    def __repr__(self) -> str:
        return f"<Order(id={self.id}, order_number={self.order_number}, status={self.status})>"
