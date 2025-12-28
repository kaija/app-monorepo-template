"""Authentication endpoints."""

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies import DatabaseSession, get_current_active_user
from app.models.user import User
from app.schemas.auth import (
    OAuthAuthorizationURL,
    OAuthCallback,
    Token,
    UserLogin,
    UserRegister,
    UserResponse,
)
from app.services.auth_service import AuthService

router = APIRouter()


@router.post(
    "/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED
)
async def register(
    user_data: UserRegister, db: AsyncSession = Depends(DatabaseSession)
) -> UserResponse:
    """
    Register a new user with email and password.

    Args:
        user_data: User registration data
        db: Database session

    Returns:
        UserResponse: Created user data

    Raises:
        HTTPException: If registration fails
    """
    auth_service = AuthService(db)
    return await auth_service.register_user(user_data)


@router.post("/login", response_model=Token)
async def login(
    response: Response,
    user_data: UserLogin,
    db: AsyncSession = Depends(DatabaseSession),
) -> Token:
    """
    Authenticate user with email and password.

    Args:
        response: FastAPI response object for setting cookies
        user_data: User login credentials
        db: Database session

    Returns:
        Token: JWT token and user data

    Raises:
        HTTPException: If authentication fails
    """
    auth_service = AuthService(db)
    token = await auth_service.authenticate_user(user_data)

    # Set HTTP-only cookie with JWT token
    response.set_cookie(
        key="access_token",
        value=token.access_token,
        httponly=True,
        secure=True,  # Use HTTPS in production
        samesite="lax",
        max_age=1800,  # 30 minutes
    )

    return token


@router.post("/logout")
async def logout(response: Response) -> dict[str, str]:
    """
    Logout user by clearing authentication cookie.

    Args:
        response: FastAPI response object for clearing cookies

    Returns:
        dict: Logout confirmation message
    """
    response.delete_cookie(
        key="access_token", httponly=True, secure=True, samesite="lax"
    )

    return {"message": "Successfully logged out"}


@router.get("/me", response_model=UserResponse)
async def get_current_user_info(
    current_user: User = Depends(get_current_active_user),
) -> UserResponse:
    """
    Get current authenticated user information.

    Args:
        current_user: Current authenticated user

    Returns:
        UserResponse: Current user data
    """
    return UserResponse.model_validate(current_user)


@router.get("/google", response_model=OAuthAuthorizationURL)
async def google_oauth_init(
    db: AsyncSession = Depends(DatabaseSession),
) -> OAuthAuthorizationURL:
    """
    Initiate Google OAuth flow.

    Args:
        db: Database session

    Returns:
        OAuthAuthorizationURL: Google authorization URL and state

    Raises:
        HTTPException: If Google OAuth is not configured
    """
    auth_service = AuthService(db)
    return auth_service.get_google_authorization_url()


@router.get("/google/callback", response_model=Token)
async def google_oauth_callback(
    response: Response,
    code: str,
    state: str,
    db: AsyncSession = Depends(DatabaseSession),
) -> Token:
    """
    Handle Google OAuth callback.

    Args:
        response: FastAPI response object for setting cookies
        code: Authorization code from Google
        state: State parameter for CSRF protection
        db: Database session

    Returns:
        Token: JWT token and user data

    Raises:
        HTTPException: If OAuth flow fails
    """
    auth_service = AuthService(db)
    token = await auth_service.handle_google_callback(code, state)

    # Set HTTP-only cookie with JWT token
    response.set_cookie(
        key="access_token",
        value=token.access_token,
        httponly=True,
        secure=True,
        samesite="lax",
        max_age=1800,  # 30 minutes
    )

    return token


@router.get("/apple", response_model=OAuthAuthorizationURL)
async def apple_oauth_init(
    db: AsyncSession = Depends(DatabaseSession),
) -> OAuthAuthorizationURL:
    """
    Initiate Apple OAuth flow.

    Args:
        db: Database session

    Returns:
        OAuthAuthorizationURL: Apple authorization URL and state

    Raises:
        HTTPException: If Apple OAuth is not configured
    """
    auth_service = AuthService(db)
    return auth_service.get_apple_authorization_url()


@router.post("/apple/callback", response_model=Token)
async def apple_oauth_callback(
    response: Response,
    callback_data: OAuthCallback,
    db: AsyncSession = Depends(DatabaseSession),
) -> Token:
    """
    Handle Apple OAuth callback.

    Args:
        response: FastAPI response object for setting cookies
        callback_data: OAuth callback data (code and state)
        db: Database session

    Returns:
        Token: JWT token and user data

    Raises:
        HTTPException: If OAuth flow fails
    """
    auth_service = AuthService(db)
    token = await auth_service.handle_apple_callback(
        callback_data.code, callback_data.state
    )

    # Set HTTP-only cookie with JWT token
    response.set_cookie(
        key="access_token",
        value=token.access_token,
        httponly=True,
        secure=True,
        samesite="lax",
        max_age=1800,  # 30 minutes
    )

    return token
