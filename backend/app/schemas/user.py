"""User schemas for request/response validation."""

from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class UserBase(BaseModel):
    """Base user schema."""

    email: EmailStr
    display_name: Optional[str] = None


class UserCreate(UserBase):
    """Schema for creating a new user."""

    password: Optional[str] = Field(None, min_length=8, max_length=128)
    oauth_provider: Optional[str] = Field(None, pattern=r"^(google|apple)$")
    oauth_id: Optional[str] = None
    avatar_url: Optional[str] = Field(None, max_length=500)


class UserOAuthCreate(BaseModel):
    """Schema for creating a user via OAuth."""

    email: EmailStr
    oauth_provider: str = Field(..., pattern=r"^(google|apple)$")
    oauth_id: str = Field(..., min_length=1)
    display_name: Optional[str] = None
    avatar_url: Optional[str] = Field(None, max_length=500)


class UserUpdate(BaseModel):
    """Schema for updating user information."""

    display_name: Optional[str] = None
    avatar_url: Optional[str] = Field(None, max_length=500)


class UserResponse(UserBase):
    """Schema for user response."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    oauth_provider: Optional[str] = None
    avatar_url: Optional[str] = None
    is_active: bool
    created_at: datetime
    updated_at: datetime


class UserLogin(BaseModel):
    """Schema for user login."""

    email: EmailStr
    password: str = Field(..., min_length=1)


class UserLoginResponse(BaseModel):
    """Schema for login response."""

    access_token: str
    token_type: str = "bearer"
    user: UserResponse
