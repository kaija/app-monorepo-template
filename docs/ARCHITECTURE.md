# Architecture Documentation

## Overview

The LINE Commerce Monorepo Template follows a layered architecture pattern with clear separation of concerns. This document outlines the architectural decisions, design patterns, and extension points for future development.

## Architectural Principles

### 1. Layered Architecture

The backend follows a strict layered architecture with unidirectional dependency flow:

```
┌─────────────────┐
│   API Routes    │ ← HTTP endpoints, request/response handling
├─────────────────┤
│    Services     │ ← Business logic, orchestration
├─────────────────┤
│  Repositories   │ ← Data access, persistence
├─────────────────┤
│     Models      │ ← Data structures, ORM models
├─────────────────┤
│      Core       │ ← Shared utilities, configuration
└─────────────────┘
```

**Dependency Rules:**
- Routes may import from: Services, Schemas, Dependencies
- Services may import from: Repositories, Models, Core
- Repositories may import from: Models, Core
- Models may import from: Core, other Models
- Core modules should not import from business logic layers

### 2. Separation of Concerns

Each layer has specific responsibilities:

- **API Routes**: Handle HTTP requests, validate input, format responses
- **Services**: Implement business logic, coordinate between repositories
- **Repositories**: Abstract data access, handle database operations
- **Models**: Define data structures and relationships
- **Core**: Provide shared utilities and configuration

### 3. Dependency Injection

FastAPI's dependency injection system is used throughout:
- Database sessions injected into repositories
- Authentication handled through dependencies
- Configuration managed centrally

## Design Patterns

### 1. Repository Pattern

Data access is abstracted through repository classes:

```python
class UserRepository:
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def get_by_id(self, user_id: UUID) -> Optional[User]:
        # Implementation
    
    async def create(self, user_data: UserCreate) -> User:
        # Implementation
```

**Benefits:**
- Testable data access layer
- Database implementation can be swapped
- Clear interface for data operations

### 2. Service Layer Pattern

Business logic is encapsulated in service classes:

```python
class AuthService:
    def __init__(self, user_repo: UserRepository):
        self.user_repo = user_repo
    
    async def authenticate_user(self, email: str, password: str) -> Optional[User]:
        # Business logic implementation
```

**Benefits:**
- Reusable business logic
- Clear transaction boundaries
- Easier testing and mocking

### 3. Schema Validation

Pydantic schemas provide input/output validation:

```python
class UserCreate(BaseModel):
    email: str = Field(..., regex=r'^[^@]+@[^@]+\.[^@]+$')
    password: str = Field(..., min_length=8)
```

**Benefits:**
- Automatic validation and serialization
- Clear API contracts
- Type safety

## Extension Points

### 1. Adding New Entities

To add new business entities (e.g., Category, Review):

1. **Create Model** (`app/models/category.py`):
```python
class Category(Base):
    __tablename__ = "categories"
    
    id: Mapped[UUID] = mapped_column(PostgresUUID(as_uuid=True), primary_key=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    # Additional fields...
```

2. **Create Repository** (`app/repositories/category_repository.py`):
```python
class CategoryRepository:
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def get_all(self) -> List[Category]:
        # Implementation
```

3. **Create Service** (`app/services/category_service.py`):
```python
class CategoryService:
    def __init__(self, category_repo: CategoryRepository):
        self.category_repo = category_repo
    
    async def list_categories(self) -> List[Category]:
        # Business logic
```

4. **Create Routes** (`app/api/routes/categories.py`):
```python
@router.get("/categories")
async def list_categories(
    category_service: CategoryService = Depends(get_category_service)
):
    # Route implementation
```

5. **Add Migration**:
```bash
alembic revision --autogenerate -m "Add categories table"
alembic upgrade head
```

### 2. Adding Authentication Providers

To add new OAuth providers (e.g., Facebook, Twitter):

1. **Update User Model** with new provider support
2. **Add Provider Configuration** in `core/config.py`
3. **Implement Provider Service** in `services/auth_service.py`
4. **Add Routes** for authorization and callback
5. **Update Frontend** with new provider buttons

### 3. Adding Business Logic

For complex business operations:

1. **Create Service Methods** for business rules
2. **Use Repository Pattern** for data access
3. **Implement Validation** using Pydantic schemas
4. **Add Error Handling** with appropriate HTTP status codes
5. **Write Tests** for business logic validation

### 4. Adding External Integrations

For third-party service integration:

1. **Create Client Classes** in `core/` or `services/`
2. **Use Environment Variables** for configuration
3. **Implement Retry Logic** and error handling
4. **Add Health Checks** for external dependencies
5. **Mock in Tests** for reliable testing

## Database Design

### Current Schema

The template includes these core tables:

- **users**: Authentication and user management
- **items**: Basic CRUD operations example
- **merchants**: Stub for vendor management (extensible)
- **products**: Stub for catalog management (extensible)
- **orders**: Stub for transaction management (extensible)

### Extension Guidelines

When extending the database schema:

1. **Use UUIDs** for primary keys (better for distributed systems)
2. **Add Timestamps** (`created_at`, `updated_at`) to all tables
3. **Use Foreign Keys** with appropriate cascade rules
4. **Add Indexes** for frequently queried columns
5. **Use Enums** for status fields with limited values
6. **Consider Soft Deletes** for important business data

### Migration Best Practices

1. **Always Review** auto-generated migrations
2. **Add Data Migrations** when needed for existing data
3. **Test Migrations** on copy of production data
4. **Plan Rollback Strategy** for complex changes
5. **Use Transactions** for multi-step migrations

## Security Considerations

### Authentication & Authorization

- JWT tokens with HTTP-only cookies
- OAuth integration for social login
- Password hashing with bcrypt
- Token expiration and refresh handling

### Data Protection

- Input validation with Pydantic
- SQL injection prevention with SQLAlchemy
- CORS configuration for frontend integration
- Environment variable management for secrets

### API Security

- Rate limiting (to be implemented)
- Request size limits
- Authentication middleware
- Error message sanitization

## Performance Considerations

### Database Optimization

- Connection pooling with SQLAlchemy
- Async database operations
- Proper indexing strategy
- Query optimization with eager loading

### Caching Strategy

Extension points for caching:
- Redis integration for session storage
- Application-level caching for frequently accessed data
- CDN integration for static assets

### Monitoring & Observability

Extension points for monitoring:
- Structured logging with correlation IDs
- Metrics collection (Prometheus/StatsD)
- Distributed tracing (OpenTelemetry)
- Health check endpoints

## Testing Strategy

### Unit Testing

- Repository layer testing with test database
- Service layer testing with mocked repositories
- Route testing with FastAPI test client
- Model validation testing

### Integration Testing

- End-to-end API testing
- Database migration testing
- Authentication flow testing
- External service integration testing

### Property-Based Testing

- Universal property validation across inputs
- Correctness property verification
- Edge case discovery through randomization

## Deployment Architecture

### Local Development

- Docker Compose orchestration
- Hot reloading for development
- Separate test database
- Environment variable management

### Production Deployment

- Container-based deployment
- Infrastructure as Code (Terraform)
- CI/CD pipeline with GitHub Actions
- Environment-specific configuration

## Future Enhancements

### Recommended Extensions

1. **API Versioning**: Implement versioned API endpoints
2. **Rate Limiting**: Add request rate limiting
3. **Caching Layer**: Implement Redis for caching
4. **Message Queue**: Add async task processing
5. **File Storage**: Implement file upload/storage
6. **Search**: Add full-text search capabilities
7. **Analytics**: Implement event tracking
8. **Notifications**: Add email/SMS notification system

### Scalability Considerations

1. **Database Sharding**: Plan for horizontal scaling
2. **Microservices**: Consider service decomposition
3. **Load Balancing**: Implement proper load distribution
4. **CDN Integration**: Optimize static asset delivery
5. **Caching Strategy**: Multi-level caching implementation

## Validation Tools

The template includes validation tools to maintain architectural integrity:

- **Layer Separation Validator**: `backend/validate_layer_separation.py`
- **Implementation Validator**: `backend/validate_implementation.py`
- **Environment Validator**: `scripts/validate-env.py`

Run these tools regularly to ensure architectural compliance:

```bash
# Validate layer separation
python backend/validate_layer_separation.py

# Validate implementation completeness
python backend/validate_implementation.py

# Validate environment configuration
python scripts/validate-env.py
```

## Conclusion

This architecture provides a solid foundation for building scalable e-commerce applications while maintaining flexibility for future enhancements. The layered approach, clear separation of concerns, and comprehensive extension points enable rapid development while ensuring maintainability and testability.

For questions or suggestions regarding the architecture, please refer to the project documentation or create an issue in the repository.