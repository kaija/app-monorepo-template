"""Authentication schemas for request/response validation."""

from typing import Optional
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field


class UserLogin(BaseModel):
    """User login request schema."""

    email: EmailStr
    password: str = Field(..., min_length=8, max_length=100)


class UserRegister(BaseModel):
    """User registration request schema."""

    email: EmailStr
    password: str = Field(..., min_length=8, max_length=100)
    display_name: Optional[str] = Field(None, max_length=255)


class UserOAuthCreate(BaseModel):
    """OAuth user creation schema."""

    email: EmailStr
    oauth_provider: str = Field(..., pattern=r"^(google|apple)$")
    oauth_id: str = Field(..., max_length=255)
    display_name: Optional[str] = Field(None, max_length=255)
    avatar_url: Optional[str] = Field(None, max_length=500)


class UserResponse(BaseModel):
    """User response schema."""

    id: UUID
    email: str
    display_name: Optional[str]
    avatar_url: Optional[str]
    oauth_provider: Optional[str]
    is_active: bool

    class Config:
        from_attributes = True


class Token(BaseModel):
    """Token response schema."""

    access_token: str
    token_type: str = "bearer"
    user: UserResponse


class TokenData(BaseModel):
    """Token data schema for internal use."""

    user_id: Optional[str] = None
    email: Optional[str] = None


class OAuthAuthorizationURL(BaseModel):
    """OAuth authorization URL response."""

    authorization_url: str
    state: str


class OAuthCallback(BaseModel):
    """OAuth callback request schema."""

    code: str
    state: str
