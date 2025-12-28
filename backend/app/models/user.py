"""User model for authentication and profile management."""

from datetime import datetime
from typing import Optional
from uuid import UUID, uuid4

from sqlalchemy import Boolean, DateTime, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID as PostgresUUID
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func

from app.core.database import Base


class User(Base):
    """User model for authentication and profile management."""

    __tablename__ = "users"

    id: Mapped[UUID] = mapped_column(
        PostgresUUID(as_uuid=True), primary_key=True, default=uuid4
    )
    email: Mapped[str] = mapped_column(
        String(255), unique=True, nullable=False, index=True
    )
    password_hash: Mapped[Optional[str]] = mapped_column(
        String(255), nullable=True  # Nullable for OAuth-only users
    )
    oauth_provider: Mapped[Optional[str]] = mapped_column(
        String(50), nullable=True  # 'google', 'apple', etc.
    )
    oauth_id: Mapped[Optional[str]] = mapped_column(
        String(255), nullable=True  # Provider-specific user ID
    )
    display_name: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    avatar_url: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
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

    __table_args__ = (
        UniqueConstraint("oauth_provider", "oauth_id", name="unique_oauth_account"),
    )

    def __repr__(self) -> str:
        return f"<User(id={self.id}, email={self.email})>"
