#!/usr/bin/env python3
"""
Environment configuration validation script.
Validates that all required environment variables are set and secure.
"""

import os
import sys
import re
from pathlib import Path
from typing import List, Dict, Optional, Tuple


class EnvValidator:
    """Environment configuration validator."""
    
    def __init__(self, env_file: Optional[str] = None):
        self.env_file = env_file
        self.errors: List[str] = []
        self.warnings: List[str] = []
        
        # Load environment variables from file if specified
        if env_file and Path(env_file).exists():
            self._load_env_file(env_file)
    
    def _load_env_file(self, env_file: str) -> None:
        """Load environment variables from file."""
        with open(env_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    os.environ[key.strip()] = value.strip()
    
    def validate_required_vars(self, required_vars: List[str]) -> None:
        """Validate that required environment variables are set."""
        missing_vars = []
        for var in required_vars:
            if not os.getenv(var):
                missing_vars.append(var)
        
        if missing_vars:
            self.errors.append(f"Missing required environment variables: {', '.join(missing_vars)}")
    
    def validate_database_url(self) -> None:
        """Validate database URL format."""
        db_url = os.getenv('DATABASE_URL')
        if db_url:
            if not db_url.startswith(('postgresql://', 'postgresql+asyncpg://')):
                self.errors.append("DATABASE_URL must be a PostgreSQL connection string")
            
            # Check for default/weak passwords in production
            if os.getenv('ENVIRONMENT') == 'production':
                if 'postgres:postgres@' in db_url:
                    self.errors.append("DATABASE_URL contains default PostgreSQL credentials in production")
    
    def validate_jwt_secret(self) -> None:
        """Validate JWT secret key strength."""
        jwt_secret = os.getenv('JWT_SECRET_KEY')
        if jwt_secret:
            if len(jwt_secret) < 32:
                self.errors.append("JWT_SECRET_KEY must be at least 32 characters long")
            
            # Check for common weak secrets
            weak_secrets = [
                'your-secret-key-change-in-production',
                'dev-jwt-secret-key-not-for-production-use-only',
                'change-me',
                'secret',
                'password',
                '12345'
            ]
            
            if jwt_secret.lower() in [s.lower() for s in weak_secrets]:
                self.errors.append("JWT_SECRET_KEY appears to be a default/weak value")
            
            # Check for development keys in production
            if os.getenv('ENVIRONMENT') == 'production':
                if 'dev' in jwt_secret.lower() or 'test' in jwt_secret.lower():
                    self.errors.append("JWT_SECRET_KEY appears to be a development key in production")
    
    def validate_nextauth_secret(self) -> None:
        """Validate NextAuth secret."""
        nextauth_secret = os.getenv('NEXTAUTH_SECRET')
        if nextauth_secret:
            if len(nextauth_secret) < 32:
                self.errors.append("NEXTAUTH_SECRET must be at least 32 characters long")
            
            # Check for development keys in production
            if os.getenv('ENVIRONMENT') == 'production':
                if 'dev' in nextauth_secret.lower() or 'test' in nextauth_secret.lower():
                    self.errors.append("NEXTAUTH_SECRET appears to be a development key in production")
    
    def validate_urls(self) -> None:
        """Validate URL configurations."""
        environment = os.getenv('ENVIRONMENT', 'development')
        
        # URLs to check
        urls_to_check = [
            ('NEXT_PUBLIC_API_URL', 'API URL'),
            ('NEXT_PUBLIC_APP_URL', 'App URL'),
            ('NEXTAUTH_URL', 'NextAuth URL'),
        ]
        
        for env_var, description in urls_to_check:
            url = os.getenv(env_var)
            if url:
                # Check for HTTPS in production
                if environment == 'production':
                    if not url.startswith('https://') and 'localhost' not in url:
                        self.errors.append(f"{description} should use HTTPS in production: {url}")
                
                # Check for valid URL format
                if not re.match(r'^https?://.+', url):
                    self.errors.append(f"{description} is not a valid URL: {url}")
    
    def validate_oauth_config(self) -> None:
        """Validate OAuth configuration."""
        google_id = os.getenv('GOOGLE_CLIENT_ID')
        google_secret = os.getenv('GOOGLE_CLIENT_SECRET')
        apple_id = os.getenv('APPLE_CLIENT_ID')
        apple_secret = os.getenv('APPLE_CLIENT_SECRET')
        
        # Check for incomplete OAuth configurations
        if google_id and not google_secret:
            self.warnings.append("GOOGLE_CLIENT_ID is set but GOOGLE_CLIENT_SECRET is missing")
        if google_secret and not google_id:
            self.warnings.append("GOOGLE_CLIENT_SECRET is set but GOOGLE_CLIENT_ID is missing")
        
        if apple_id and not apple_secret:
            self.warnings.append("APPLE_CLIENT_ID is set but APPLE_CLIENT_SECRET is missing")
        if apple_secret and not apple_id:
            self.warnings.append("APPLE_CLIENT_SECRET is set but APPLE_CLIENT_ID is missing")
        
        # Check for placeholder values
        placeholder_values = [
            'your-google-client-id',
            'your-apple-client-id',
            'your-google-client-secret',
            'your-apple-client-secret'
        ]
        
        for var_name, var_value in [
            ('GOOGLE_CLIENT_ID', google_id),
            ('GOOGLE_CLIENT_SECRET', google_secret),
            ('APPLE_CLIENT_ID', apple_id),
            ('APPLE_CLIENT_SECRET', apple_secret)
        ]:
            if var_value and var_value.lower() in [p.lower() for p in placeholder_values]:
                self.warnings.append(f"{var_name} appears to be a placeholder value")
    
    def validate_cors_origins(self) -> None:
        """Validate CORS origins configuration."""
        cors_origins = os.getenv('CORS_ORIGINS')
        if cors_origins:
            origins = [origin.strip() for origin in cors_origins.split(',')]
            
            for origin in origins:
                if not re.match(r'^https?://.+', origin):
                    self.errors.append(f"Invalid CORS origin format: {origin}")
            
            # Check for production HTTPS requirement
            if os.getenv('ENVIRONMENT') == 'production':
                for origin in origins:
                    if not origin.startswith('https://') and 'localhost' not in origin:
                        self.errors.append(f"CORS origin should use HTTPS in production: {origin}")
    
    def check_for_hardcoded_secrets(self, directory: str) -> None:
        """Check for hardcoded secrets in code files."""
        secret_patterns = [
            (r'password\s*=\s*["\'][^"\']{8,}["\']', 'Potential hardcoded password'),
            (r'secret\s*=\s*["\'][^"\']{16,}["\']', 'Potential hardcoded secret'),
            (r'key\s*=\s*["\'][^"\']{16,}["\']', 'Potential hardcoded key'),
            (r'token\s*=\s*["\'][^"\']{16,}["\']', 'Potential hardcoded token'),
        ]
        
        exclude_patterns = [
            r'\.git/',
            r'node_modules/',
            r'__pycache__/',
            r'\.pytest_cache/',
            r'\.env\.example',
            r'validate-env\.py',  # Exclude this script
        ]
        
        for root, dirs, files in os.walk(directory):
            # Skip excluded directories
            dirs[:] = [d for d in dirs if not any(re.search(pattern, os.path.join(root, d)) for pattern in exclude_patterns)]
            
            for file in files:
                if file.endswith(('.py', '.ts', '.tsx', '.js', '.jsx', '.json', '.yml', '.yaml')):
                    file_path = os.path.join(root, file)
                    
                    # Skip excluded files
                    if any(re.search(pattern, file_path) for pattern in exclude_patterns):
                        continue
                    
                    try:
                        with open(file_path, 'r', encoding='utf-8') as f:
                            content = f.read()
                            
                            for pattern, description in secret_patterns:
                                matches = re.finditer(pattern, content, re.IGNORECASE)
                                for match in matches:
                                    line_num = content[:match.start()].count('\n') + 1
                                    self.warnings.append(f"{description} found in {file_path}:{line_num}")
                    except (UnicodeDecodeError, PermissionError):
                        # Skip files that can't be read
                        continue
    
    def validate_all(self) -> Tuple[bool, List[str], List[str]]:
        """Run all validations."""
        environment = os.getenv('ENVIRONMENT', 'development')
        
        # Required variables for all environments
        required_vars = [
            'DATABASE_URL',
            'JWT_SECRET_KEY',
            'NEXTAUTH_SECRET',
            'NEXT_PUBLIC_API_URL',
            'NEXT_PUBLIC_APP_URL'
        ]
        
        # Additional required variables for production
        if environment == 'production':
            required_vars.extend([
                'POSTGRES_PASSWORD',
                'CORS_ORIGINS'
            ])
        
        # Run validations
        self.validate_required_vars(required_vars)
        self.validate_database_url()
        self.validate_jwt_secret()
        self.validate_nextauth_secret()
        self.validate_urls()
        self.validate_oauth_config()
        self.validate_cors_origins()
        
        # Check for hardcoded secrets in code
        current_dir = Path(__file__).parent.parent
        self.check_for_hardcoded_secrets(str(current_dir))
        
        return len(self.errors) == 0, self.errors, self.warnings


def main():
    """Main validation function."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Validate environment configuration')
    parser.add_argument('--env-file', help='Path to .env file to validate')
    parser.add_argument('--environment', help='Environment to validate for (development, staging, production)')
    
    args = parser.parse_args()
    
    # Set environment if specified
    if args.environment:
        os.environ['ENVIRONMENT'] = args.environment
    
    # Create validator
    validator = EnvValidator(args.env_file)
    
    # Run validation
    is_valid, errors, warnings = validator.validate_all()
    
    # Print results
    environment = os.getenv('ENVIRONMENT', 'development')
    print(f"🔍 Validating environment configuration for: {environment}")
    print()
    
    if errors:
        print("❌ Validation failed with errors:")
        for error in errors:
            print(f"  - {error}")
        print()
    
    if warnings:
        print("⚠️  Warnings:")
        for warning in warnings:
            print(f"  - {warning}")
        print()
    
    if is_valid:
        print("✅ Environment configuration is valid!")
        sys.exit(0)
    else:
        print("❌ Environment configuration validation failed!")
        print("Please fix the errors above before proceeding.")
        sys.exit(1)


if __name__ == '__main__':
    main()