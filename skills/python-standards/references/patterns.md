# Common Python Patterns

## Service Layer Pattern

```python
# src/core/users/service.py
import structlog
from src.core.users.models.user import User
from src.core.users.repository import UserRepository
from src.core.users.exceptions import UserNotFoundError, DuplicateEmailError

log = structlog.get_logger()

class UserService:
    """Handles user business logic."""

    def __init__(self, repository: UserRepository) -> None:
        self.repo = repository

    def get_by_id(self, user_id: str) -> User:
        """Retrieve user by ID.

        Args:
            user_id: The unique user identifier.

        Returns:
            The user object.

        Raises:
            UserNotFoundError: If user does not exist.
        """
        log.debug("fetching_user", user_id=user_id)
        user = self.repo.find_by_id(user_id)
        if not user:
            raise UserNotFoundError(f"User {user_id} not found")
        return user

    def create(self, email: str, name: str) -> User:
        """Create a new user.

        Args:
            email: User email address.
            name: User display name.

        Returns:
            The created user.

        Raises:
            DuplicateEmailError: If email already registered.
        """
        log.info("creating_user", email=email)

        existing = self.repo.find_by_email(email)
        if existing:
            raise DuplicateEmailError(f"Email {email} already registered")

        user = User(email=email, name=name)
        self.repo.save(user)

        log.info("user_created", user_id=user.id)
        return user
```

## Repository Pattern

```python
# src/core/users/repository.py
from abc import ABC, abstractmethod

from src.core.users.models.user import User

class UserRepository(ABC):
    """Abstract repository for user persistence."""

    @abstractmethod
    def find_by_id(self, user_id: str) -> User | None:
        """Find user by ID."""
        ...

    @abstractmethod
    def find_by_email(self, email: str) -> User | None:
        """Find user by email."""
        ...

    @abstractmethod
    def save(self, user: User) -> None:
        """Persist user."""
        ...

    @abstractmethod
    def delete(self, user_id: str) -> bool:
        """Delete user by ID."""
        ...
```

## Domain Model with Validation

```python
# src/core/users/models/user.py
from datetime import datetime
from uuid import UUID, uuid4

from pydantic import field_validator

from src.models.base import BaseSchema

class User(BaseSchema):
    """User domain model."""

    id: UUID = None
    email: str
    name: str
    created_at: datetime = None
    is_active: bool = True

    def __init__(self, **data) -> None:
        if "id" not in data or data["id"] is None:
            data["id"] = uuid4()
        if "created_at" not in data or data["created_at"] is None:
            data["created_at"] = datetime.utcnow()
        super().__init__(**data)

    @field_validator("email")
    @classmethod
    def normalize_email(cls, v: str) -> str:
        return v.lower().strip()

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: str) -> str:
        if len(v) < 2:
            raise ValueError("Name must be at least 2 characters")
        return v
```

## Exception Hierarchy

```python
# src/core/users/exceptions.py

class UserError(Exception):
    """Base exception for user domain."""

    def __init__(self, message: str, code: str | None = None) -> None:
        self.message = message
        self.code = code
        super().__init__(message)


class UserNotFoundError(UserError):
    """Raised when user does not exist."""

    def __init__(self, message: str) -> None:
        super().__init__(message, code="USER_NOT_FOUND")


class DuplicateEmailError(UserError):
    """Raised when email already registered."""

    def __init__(self, message: str) -> None:
        super().__init__(message, code="DUPLICATE_EMAIL")


class InvalidUserDataError(UserError):
    """Raised when user data fails validation."""

    def __init__(self, message: str, field: str | None = None) -> None:
        self.field = field
        super().__init__(message, code="INVALID_USER_DATA")
```

## CLI Entry Point

```python
# src/cli/main.py
import sys

import structlog

log = structlog.get_logger()

def main() -> int:
    """Main CLI entry point.

    Returns:
        Exit code (0 for success, non-zero for failure).
    """
    log.info("application_starting")

    try:
        # Application logic here
        log.info("application_completed")
        return 0
    except Exception as e:
        log.error("application_failed", error=str(e))
        return 1


if __name__ == "__main__":
    sys.exit(main())
```

## API Entry Point (FastAPI)

```python
# src/api/main.py
from contextlib import asynccontextmanager
from collections.abc import AsyncGenerator

import structlog
from fastapi import FastAPI

log = structlog.get_logger()

@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Application lifespan handler."""
    log.info("application_starting")
    yield
    log.info("application_shutting_down")


app = FastAPI(
    title="My API",
    lifespan=lifespan,
)


@app.get("/health")
async def health_check() -> dict[str, str]:
    """Health check endpoint."""
    return {"status": "healthy"}
```

## Test Structure

```python
# src/core/users/tests/test_service.py
import pytest

from src.core.users.exceptions import UserNotFoundError
from src.core.users.models.user import User
from src.core.users.service import UserService


class TestUserService:
    """Tests for UserService."""

    def test_get_by_id_returns_user(self, user_service: UserService, sample_user: User) -> None:
        """Test successful user retrieval."""
        result = user_service.get_by_id(str(sample_user.id))

        assert result.id == sample_user.id
        assert result.email == sample_user.email

    def test_get_by_id_raises_not_found(self, user_service: UserService) -> None:
        """Test UserNotFoundError when user does not exist."""
        with pytest.raises(UserNotFoundError) as exc_info:
            user_service.get_by_id("nonexistent-id")

        assert "not found" in str(exc_info.value)

    def test_create_user_success(self, user_service: UserService) -> None:
        """Test successful user creation."""
        user = user_service.create(email="test@example.com", name="Test User")

        assert user.email == "test@example.com"
        assert user.name == "Test User"
        assert user.id is not None


@pytest.fixture
def user_service() -> UserService:
    """Create UserService with mock repository."""
    # Implement with mock repository
    ...


@pytest.fixture
def sample_user() -> User:
    """Create sample user for testing."""
    return User(email="sample@example.com", name="Sample User")
```

## Conftest Pattern

```python
# src/core/users/tests/conftest.py
import pytest

from src.core.users.repository import UserRepository
from src.core.users.service import UserService


class InMemoryUserRepository(UserRepository):
    """In-memory repository for testing."""

    def __init__(self) -> None:
        self._users: dict[str, User] = {}

    def find_by_id(self, user_id: str) -> User | None:
        return self._users.get(user_id)

    def find_by_email(self, email: str) -> User | None:
        for user in self._users.values():
            if user.email == email:
                return user
        return None

    def save(self, user: User) -> None:
        self._users[str(user.id)] = user

    def delete(self, user_id: str) -> bool:
        if user_id in self._users:
            del self._users[user_id]
            return True
        return False


@pytest.fixture
def repository() -> InMemoryUserRepository:
    """Create in-memory repository."""
    return InMemoryUserRepository()


@pytest.fixture
def user_service(repository: InMemoryUserRepository) -> UserService:
    """Create user service with in-memory repository."""
    return UserService(repository=repository)
```
