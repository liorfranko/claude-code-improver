---
name: Python Standards
description: This skill should be used when the user is working on a Python project, asks to "write Python code", "create a Python class", "add a Pydantic model", "create a service", "add error handling", or when any .py files are detected in the project. Provides coding standards for structure, typing, Pydantic, logging, and exceptions.
---

# Python Development Standards

## Overview

This skill enforces a consistent Python coding style focused on type safety, clean architecture, and maintainability. Apply these standards when writing or reviewing Python code.

## Project Structure

Organize Python projects hierarchically with `utils/`, `models/`, and `tests/` at each level:

```
project-name/
├── pyproject.toml
├── .python-version
├── src/
│   ├── __init__.py
│   ├── cli/                    # or api/
│   │   ├── __init__.py
│   │   └── main.py
│   ├── utils/
│   │   └── __init__.py
│   ├── models/
│   │   ├── __init__.py
│   │   └── base.py             # BaseSchema
│   └── core/
│       ├── __init__.py
│       └── <domain>/           # e.g., auth/, users/, orders/
│           ├── __init__.py
│           ├── service.py
│           ├── repository.py
│           ├── exceptions.py
│           ├── utils/
│           │   └── __init__.py
│           ├── models/
│           │   ├── __init__.py
│           │   └── <model>.py
│           └── tests/
│               ├── __init__.py
│               └── test_service.py
```

**Key rules:**
- One class or concern per file
- Each domain module has its own `utils/`, `models/`, `tests/`
- snake_case for all file and directory names

## Tools

| Tool | Purpose |
|------|---------|
| uv | Package management |
| pytest | Testing |
| ruff | Linting and formatting |

## Type Annotations

Apply full type annotations to all code:

```python
from typing import TypeVar, Generic
from collections.abc import Sequence

T = TypeVar("T")

def get_first(items: Sequence[T]) -> T | None:
    """Return first item or None if empty."""
    return items[0] if items else None
```

Use modern typing syntax:
- `list[str]` not `List[str]`
- `dict[str, int]` not `Dict[str, int]`
- `str | None` not `Optional[str]`
- `collections.abc` for abstract types

## Pydantic Models

### Base Schema

All Pydantic models inherit from a project-wide `BaseSchema`:

```python
# src/models/base.py
from pydantic import BaseModel, ConfigDict

class BaseSchema(BaseModel):
    """Base model for all Pydantic schemas."""

    model_config = ConfigDict(
        from_attributes=True,
        str_strip_whitespace=True,
    )
```

### Field Validators

Use `@field_validator` for custom validation:

```python
from pydantic import field_validator

from src.models.base import BaseSchema

class User(BaseSchema):
    email: str
    age: int

    @field_validator("email")
    @classmethod
    def validate_email(cls, v: str) -> str:
        if "@" not in v:
            raise ValueError("Invalid email format")
        return v.lower()

    @field_validator("age")
    @classmethod
    def validate_age(cls, v: int) -> int:
        if v < 0:
            raise ValueError("Age cannot be negative")
        return v
```

### Model Organization

Place models in `models/` directories, one model per file:

```
src/core/users/models/
├── __init__.py
├── user.py           # class User(BaseSchema)
├── profile.py        # class Profile(BaseSchema)
└── preferences.py    # class Preferences(BaseSchema)
```

## Import Ordering

Order imports: stdlib → third-party → local:

```python
# Standard library
import os
from pathlib import Path

# Third-party
import structlog
from pydantic import BaseModel

# Local
from src.core.users.models.user import User
from src.utils.helpers import format_name
```

Ruff enforces this automatically with the `I` rule set.

## Docstrings

Use Google style docstrings:

```python
def create_user(name: str, email: str) -> User:
    """Create a new user in the system.

    Args:
        name: The user's display name.
        email: The user's email address.

    Returns:
        The newly created user object.

    Raises:
        ValidationError: If email format is invalid.
        DuplicateEmailError: If email already exists.
    """
```

## Logging

Use structlog for structured logging:

```python
import structlog

log = structlog.get_logger()

class UserService:
    def create(self, email: str) -> User:
        log.info("creating_user", email=email)
        user = self.repo.create(email)
        log.info("user_created", user_id=user.id)
        return user
```

**Guidelines:**
- Use snake_case event names
- Pass context as keyword arguments
- Log at appropriate levels (debug, info, warning, error)

## Domain Exceptions

Create domain-specific exceptions per module:

```python
# src/core/users/exceptions.py

class UserError(Exception):
    """Base exception for user domain."""
    pass

class UserNotFoundError(UserError):
    """Raised when user does not exist."""
    pass

class DuplicateEmailError(UserError):
    """Raised when email already registered."""
    pass
```

**Guidelines:**
- Each domain has its own `exceptions.py`
- Inherit from a domain-specific base exception
- Use descriptive names ending in `Error`

## Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Files | snake_case | `user_service.py` |
| Directories | snake_case | `user_management/` |
| Classes | PascalCase | `UserService` |
| Functions | snake_case | `get_user_by_id` |
| Variables | snake_case | `user_count` |
| Constants | UPPER_SNAKE | `MAX_RETRIES` |
| Type vars | Single uppercase or PascalCase | `T`, `UserT` |

## File Organization

One class or primary concern per file:

```
src/core/users/
├── service.py        # class UserService
├── repository.py     # class UserRepository
├── exceptions.py     # UserError, UserNotFoundError, DuplicateEmailError
└── models/
    ├── user.py       # class User
    └── profile.py    # class Profile
```

**Avoid:**
- Multiple unrelated classes in one file
- Mixing models with services
- Putting exceptions in model files

## Configuration Management

**STRICT RULE: No static configuration values in code. All configuration MUST come from environment variables via pydantic-settings.**

### Forbidden Patterns

```python
# NEVER DO THIS - hardcoded values
DATABASE_URL = "postgresql://localhost/mydb"  # FORBIDDEN
API_TIMEOUT = 30  # FORBIDDEN
DEBUG = True  # FORBIDDEN

# NEVER DO THIS - config files with values
config = yaml.load("config.yaml")  # FORBIDDEN
settings = json.load("settings.json")  # FORBIDDEN
```

### Required Pattern: pydantic-settings

All configuration must use `pydantic-settings` with environment variables:

```python
# src/core/config.py
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    """Application settings from environment variables."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="forbid",  # Fail on unknown env vars
    )

    # Database - REQUIRED, no default
    database_url: str = Field(..., description="PostgreSQL connection string")

    # API - with sensible defaults
    api_host: str = Field(default="0.0.0.0", description="API bind host")
    api_port: int = Field(default=8000, ge=1, le=65535, description="API port")

    # Feature flags
    debug: bool = Field(default=False, description="Enable debug mode")

    # Secrets - REQUIRED, validated
    secret_key: str = Field(..., min_length=32, description="JWT signing key")


# Singleton instance - validates on import
settings = Settings()
```

### Configuration Rules

| Rule | Description |
|------|-------------|
| **No hardcoded values** | All config from env vars, never in code |
| **No config files** | No YAML/JSON/TOML with actual values |
| **Validate on startup** | App fails fast if config invalid |
| **Type everything** | All settings fully typed with Pydantic |
| **Document all vars** | `.env.example` with all variables |
| **Secrets via env** | Never commit secrets, use env vars |

### Required Files

```
project/
├── .env              # Local values (GITIGNORED)
├── .env.example      # Documented template (committed)
└── src/core/
    └── config.py     # Settings class
```

### .env.example Template

```bash
# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/dbname

# API
API_HOST=0.0.0.0
API_PORT=8000

# Security (generate with: openssl rand -hex 32)
SECRET_KEY=your-32-char-minimum-secret-key-here

# Feature Flags
DEBUG=false
```

### Using Settings

```python
# Import the singleton
from src.core.config import settings

# Use typed values directly
db = connect(settings.database_url)
app.run(host=settings.api_host, port=settings.api_port)

# NEVER do this
from src.core.config import Settings
s = Settings()  # Creates new instance, wasteful
```

### Nested Configuration

For complex configs, use nested models:

```python
class DatabaseSettings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="DB_")

    url: str
    pool_size: int = 5
    echo: bool = False

class Settings(BaseSettings):
    db: DatabaseSettings = DatabaseSettings()
    # ...
```

Environment variables: `DB_URL`, `DB_POOL_SIZE`, `DB_ECHO`

## Additional Resources

### Templates

Scaffold templates available in `templates/`:
- **`pyproject.toml.template`** - Project configuration with uv, pytest, ruff
- **`base_schema.py.template`** - BaseSchema implementation
- **`config.py.template`** - Settings class with pydantic-settings
- **`env.example.template`** - Environment variables template

### References

For detailed examples, see `references/`:
- **`references/patterns.md`** - Common code patterns
- **`references/config.md`** - Configuration patterns and examples
