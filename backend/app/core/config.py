"""Core configuration settings with environment validation."""

import os
import sys
from enum import Enum
from typing import List, Optional

from pydantic import ConfigDict, Field, ValidationError, field_validator
from pydantic_settings import BaseSettings


class Environment(str, Enum):
    """Environment types."""

    DEVELOPMENT = "development"
    STAGING = "staging"
    PRODUCTION = "production"


class LogLevel(str, Enum):
    """Log levels."""

    DEBUG = "debug"
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"
    CRITICAL = "critical"


class Settings(BaseSettings):
    """Application settings with validation."""

    model_config = ConfigDict(
        env_file=".env",
        case_sensitive=False,
        extra="ignore",  # Ignore extra environment variables
        env_parse_none_str=True,  # Parse None strings properly
    )

    # Environment Configuration
    environment: Environment = Field(
        default=Environment.DEVELOPMENT, description="Application environment"
    )

    # Database Configuration
    database_url: str = Field(description="Database connection URL")
    database_echo: bool = Field(
        default=False, description="Enable SQLAlchemy query logging"
    )

    # Authentication & Security
    jwt_secret_key: str = Field(description="Secret key for JWT token generation")
    jwt_algorithm: str = Field(default="HS256", description="JWT algorithm")
    jwt_expire_minutes: int = Field(
        default=30,
        ge=1,
        le=1440,  # Max 24 hours
        description="JWT token expiration time in minutes",
    )

    # OAuth Configuration (Optional)
    google_client_id: Optional[str] = Field(
        default=None, description="Google OAuth client ID"
    )
    google_client_secret: Optional[str] = Field(
        default=None, description="Google OAuth client secret"
    )
    apple_client_id: Optional[str] = Field(
        default=None, description="Apple OAuth client ID"
    )
    apple_client_secret: Optional[str] = Field(
        default=None, description="Apple OAuth client secret"
    )

    # Application Configuration
    app_name: str = Field(default="LINE Commerce API", description="Application name")
    app_version: str = Field(default="0.1.0", description="Application version")
    debug: bool = Field(default=False, description="Enable debug mode")

    # CORS Configuration
    cors_origins_str: str = Field(
        default="http://localhost:3000,http://127.0.0.1:3000",
        alias="CORS_ORIGINS",
        description="Comma-separated CORS origins",
    )

    @property
    def cors_origins(self) -> List[str]:
        """Get CORS origins as a list."""
        return [
            origin.strip()
            for origin in self.cors_origins_str.split(",")
            if origin.strip()
        ]

    # Rate Limiting
    rate_limit_requests_per_minute: int = Field(
        default=60, ge=1, le=10000, description="Rate limit requests per minute"
    )

    # Logging
    log_level: LogLevel = Field(default=LogLevel.INFO, description="Logging level")

    # Optional Services
    smtp_host: Optional[str] = Field(default=None, description="SMTP server host")
    smtp_port: Optional[int] = Field(
        default=587, ge=1, le=65535, description="SMTP server port"
    )
    smtp_user: Optional[str] = Field(default=None, description="SMTP username")
    smtp_password: Optional[str] = Field(default=None, description="SMTP password")

    # Monitoring
    sentry_dsn: Optional[str] = Field(
        default=None, description="Sentry DSN for error tracking"
    )

    @field_validator("jwt_secret_key")
    @classmethod
    def validate_jwt_secret_key(cls, v: str) -> str:
        """Validate JWT secret key strength."""
        if len(v) < 32:
            raise ValueError("JWT secret key must be at least 32 characters long")

        # Check for common weak secrets
        weak_secrets = [
            "your-secret-key-change-in-production",
            "dev-jwt-secret-key-not-for-production-use-only",
            "change-me",
            "secret",
            "password",
            "12345",
        ]

        if v.lower() in [s.lower() for s in weak_secrets]:
            raise ValueError(
                "JWT secret key appears to be a default/weak value. Use a cryptographically secure secret."
            )

        return v

    @field_validator("database_url")
    @classmethod
    def validate_database_url(cls, v: str) -> str:
        """Validate database URL format."""
        if not v.startswith(("postgresql://", "postgresql+asyncpg://")):
            raise ValueError("Database URL must be a PostgreSQL connection string")
        return v

    @field_validator("cors_origins_str")
    @classmethod
    def validate_cors_origins_str(cls, v: str) -> str:
        """Validate CORS origins string."""
        if not v:
            raise ValueError("At least one CORS origin must be specified")

        origins = [origin.strip() for origin in v.split(",") if origin.strip()]

        for origin in origins:
            if not origin.startswith(("http://", "https://")):
                raise ValueError(
                    f"CORS origin must start with http:// or https://: {origin}"
                )

        return v

    def is_production(self) -> bool:
        """Check if running in production environment."""
        return self.environment == Environment.PRODUCTION

    def is_development(self) -> bool:
        """Check if running in development environment."""
        return self.environment == Environment.DEVELOPMENT

    def oauth_enabled(self) -> bool:
        """Check if OAuth is configured."""
        return bool(
            (self.google_client_id and self.google_client_secret)
            or (self.apple_client_id and self.apple_client_secret)
        )


def validate_required_environment_variables() -> None:
    """Validate that all required environment variables are set."""
    required_vars = ["DATABASE_URL", "JWT_SECRET_KEY"]

    missing_vars = []
    for var in required_vars:
        if not os.getenv(var):
            missing_vars.append(var)

    if missing_vars:
        print(f"❌ Missing required environment variables: {', '.join(missing_vars)}")
        print("Please check your .env file and ensure all required variables are set.")
        print("See .env.example for reference.")
        sys.exit(1)


def create_settings() -> Settings:
    """Create and validate settings."""
    # First check for required environment variables
    validate_required_environment_variables()

    try:
        settings = Settings()

        # Additional production checks
        if settings.is_production():
            production_checks = []

            # Check for production-ready JWT secret
            if (
                "dev" in settings.jwt_secret_key.lower()
                or "test" in settings.jwt_secret_key.lower()
            ):
                production_checks.append(
                    "JWT_SECRET_KEY appears to be a development key"
                )

            # Check for HTTPS in production CORS origins
            for origin in settings.cors_origins:
                if not origin.startswith("https://") and not origin.startswith(
                    "http://localhost"
                ):
                    production_checks.append(
                        f"CORS origin should use HTTPS in production: {origin}"
                    )

            if production_checks:
                print("❌ Production environment validation failed:")
                for check in production_checks:
                    print(f"  - {check}")
                sys.exit(1)

        print(
            f"✅ Configuration loaded successfully for {settings.environment} environment"
        )
        return settings

    except ValidationError as e:
        print("❌ Configuration validation failed:")
        for error in e.errors():
            field = " -> ".join(str(loc) for loc in error["loc"])
            print(f"  - {field}: {error['msg']}")
        print("\nPlease check your environment variables and .env file.")
        print("See .env.example for reference.")
        sys.exit(1)


# Global settings instance
settings = create_settings()


def get_settings() -> Settings:
    """Get application settings."""
    return settings
