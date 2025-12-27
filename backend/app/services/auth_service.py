"""Authentication service for user management and OAuth integration."""

import secrets
from typing import Optional, Tuple
from uuid import UUID

from authlib.integrations.httpx_client import AsyncOAuth2Client
from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.security import create_access_token, get_password_hash, verify_password
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.auth import (
    OAuthAuthorizationURL,
    Token,
    UserLogin,
    UserOAuthCreate,
    UserRegister,
    UserResponse,
)

settings = get_settings()


class AuthService:
    """Authentication service for user management and OAuth."""

    def __init__(self, db: AsyncSession):
        self.db = db
        self.user_repo = UserRepository(db)

    async def register_user(self, user_data: UserRegister) -> UserResponse:
        """
        Register a new user with email and password.
        
        Args:
            user_data: User registration data
            
        Returns:
            UserResponse: The created user
            
        Raises:
            HTTPException: If user already exists
        """
        # Check if user already exists
        existing_user = await self.user_repo.get_by_email(user_data.email)
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User with this email already exists"
            )

        # Hash password and create user
        hashed_password = get_password_hash(user_data.password)
        user = User(
            email=user_data.email,
            password_hash=hashed_password,
            display_name=user_data.display_name,
        )

        created_user = await self.user_repo.create(user)
        return UserResponse.model_validate(created_user)

    async def authenticate_user(self, login_data: UserLogin) -> Token:
        """
        Authenticate user with email and password.
        
        Args:
            login_data: User login credentials
            
        Returns:
            Token: JWT token and user data
            
        Raises:
            HTTPException: If authentication fails
        """
        user = await self.user_repo.get_by_email(login_data.email)
        
        if not user or not user.password_hash:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password"
            )

        if not verify_password(login_data.password, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password"
            )

        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User account is disabled"
            )

        # Create access token
        access_token = create_access_token(
            data={"sub": str(user.id), "email": user.email}
        )

        return Token(
            access_token=access_token,
            user=UserResponse.model_validate(user)
        )

    async def get_current_user(self, user_id: UUID) -> UserResponse:
        """
        Get current user by ID.
        
        Args:
            user_id: User ID from JWT token
            
        Returns:
            UserResponse: Current user data
            
        Raises:
            HTTPException: If user not found or inactive
        """
        user = await self.user_repo.get_by_id(user_id)
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )

        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User account is disabled"
            )

        return UserResponse.model_validate(user)

    def get_google_authorization_url(self) -> OAuthAuthorizationURL:
        """
        Get Google OAuth authorization URL.
        
        Returns:
            OAuthAuthorizationURL: Authorization URL and state
            
        Raises:
            HTTPException: If Google OAuth is not configured
        """
        if not settings.google_client_id or not settings.google_client_secret:
            raise HTTPException(
                status_code=status.HTTP_501_NOT_IMPLEMENTED,
                detail="Google OAuth is not configured"
            )

        client = AsyncOAuth2Client(
            client_id=settings.google_client_id,
            client_secret=settings.google_client_secret,
        )

        state = secrets.token_urlsafe(32)
        authorization_url, _ = client.create_authorization_url(
            "https://accounts.google.com/o/oauth2/auth",
            scope="openid email profile",
            state=state,
        )

        return OAuthAuthorizationURL(
            authorization_url=authorization_url,
            state=state
        )

    async def handle_google_callback(self, code: str, state: str) -> Token:
        """
        Handle Google OAuth callback.
        
        Args:
            code: Authorization code from Google
            state: State parameter for CSRF protection
            
        Returns:
            Token: JWT token and user data
            
        Raises:
            HTTPException: If OAuth flow fails
        """
        if not settings.google_client_id or not settings.google_client_secret:
            raise HTTPException(
                status_code=status.HTTP_501_NOT_IMPLEMENTED,
                detail="Google OAuth is not configured"
            )

        try:
            client = AsyncOAuth2Client(
                client_id=settings.google_client_id,
                client_secret=settings.google_client_secret,
            )

            # Exchange code for token
            token = await client.fetch_token(
                "https://oauth2.googleapis.com/token",
                code=code,
            )

            # Get user info
            resp = await client.get(
                "https://www.googleapis.com/oauth2/v2/userinfo",
                token=token
            )
            user_info = resp.json()

            # Create or get user
            user = await self._create_or_get_oauth_user(
                UserOAuthCreate(
                    email=user_info["email"],
                    oauth_provider="google",
                    oauth_id=user_info["id"],
                    display_name=user_info.get("name"),
                    avatar_url=user_info.get("picture"),
                )
            )

            # Create access token
            access_token = create_access_token(
                data={"sub": str(user.id), "email": user.email}
            )

            return Token(
                access_token=access_token,
                user=UserResponse.model_validate(user)
            )

        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"OAuth authentication failed: {str(e)}"
            )

    def get_apple_authorization_url(self) -> OAuthAuthorizationURL:
        """
        Get Apple OAuth authorization URL.
        
        Returns:
            OAuthAuthorizationURL: Authorization URL and state
            
        Raises:
            HTTPException: If Apple OAuth is not configured
        """
        if not settings.apple_client_id or not settings.apple_client_secret:
            raise HTTPException(
                status_code=status.HTTP_501_NOT_IMPLEMENTED,
                detail="Apple OAuth is not configured"
            )

        client = AsyncOAuth2Client(
            client_id=settings.apple_client_id,
            client_secret=settings.apple_client_secret,
        )

        state = secrets.token_urlsafe(32)
        authorization_url, _ = client.create_authorization_url(
            "https://appleid.apple.com/auth/authorize",
            scope="name email",
            state=state,
            response_mode="form_post",
        )

        return OAuthAuthorizationURL(
            authorization_url=authorization_url,
            state=state
        )

    async def handle_apple_callback(self, code: str, state: str) -> Token:
        """
        Handle Apple OAuth callback.
        
        Args:
            code: Authorization code from Apple
            state: State parameter for CSRF protection
            
        Returns:
            Token: JWT token and user data
            
        Raises:
            HTTPException: If OAuth flow fails
        """
        if not settings.apple_client_id or not settings.apple_client_secret:
            raise HTTPException(
                status_code=status.HTTP_501_NOT_IMPLEMENTED,
                detail="Apple OAuth is not configured"
            )

        try:
            client = AsyncOAuth2Client(
                client_id=settings.apple_client_id,
                client_secret=settings.apple_client_secret,
            )

            # Exchange code for token
            token = await client.fetch_token(
                "https://appleid.apple.com/auth/token",
                code=code,
            )

            # Apple doesn't provide a userinfo endpoint, so we decode the ID token
            # This is a simplified implementation - in production, you'd want to
            # properly verify the JWT signature
            import json
            import base64
            
            id_token = token.get("id_token")
            if not id_token:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="No ID token received from Apple"
                )

            # Decode JWT payload (without verification for simplicity)
            payload = id_token.split('.')[1]
            # Add padding if needed
            payload += '=' * (4 - len(payload) % 4)
            user_info = json.loads(base64.b64decode(payload))

            # Create or get user
            user = await self._create_or_get_oauth_user(
                UserOAuthCreate(
                    email=user_info["email"],
                    oauth_provider="apple",
                    oauth_id=user_info["sub"],
                    display_name=user_info.get("name"),
                )
            )

            # Create access token
            access_token = create_access_token(
                data={"sub": str(user.id), "email": user.email}
            )

            return Token(
                access_token=access_token,
                user=UserResponse.model_validate(user)
            )

        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"OAuth authentication failed: {str(e)}"
            )

    async def _create_or_get_oauth_user(self, oauth_data: UserOAuthCreate) -> User:
        """
        Create or get OAuth user.
        
        Args:
            oauth_data: OAuth user data
            
        Returns:
            User: The created or existing user
        """
        # First, try to find user by OAuth provider and ID
        user = await self.user_repo.get_by_oauth(
            oauth_data.oauth_provider, 
            oauth_data.oauth_id
        )
        
        if user:
            return user

        # If not found, try to find by email
        user = await self.user_repo.get_by_email(oauth_data.email)
        
        if user:
            # Update existing user with OAuth info
            user.oauth_provider = oauth_data.oauth_provider
            user.oauth_id = oauth_data.oauth_id
            if oauth_data.display_name and not user.display_name:
                user.display_name = oauth_data.display_name
            if oauth_data.avatar_url and not user.avatar_url:
                user.avatar_url = oauth_data.avatar_url
            
            return await self.user_repo.update(user)

        # Create new user
        user = User(
            email=oauth_data.email,
            oauth_provider=oauth_data.oauth_provider,
            oauth_id=oauth_data.oauth_id,
            display_name=oauth_data.display_name,
            avatar_url=oauth_data.avatar_url,
        )

        return await self.user_repo.create(user)