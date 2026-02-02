# Configuration Patterns

## Strict Rules

**NEVER hardcode configuration values. ALL configuration MUST come from environment variables.**

### Forbidden Patterns

```python
# ❌ FORBIDDEN: Hardcoded connection strings
DATABASE_URL = "postgresql://localhost/mydb"

# ❌ FORBIDDEN: Hardcoded API keys
API_KEY = "your-key-here"  # NEVER do this

# ❌ FORBIDDEN: Hardcoded timeouts/limits
TIMEOUT = 30
MAX_RETRIES = 3

# ❌ FORBIDDEN: Hardcoded feature flags
DEBUG = True
ENABLE_CACHE = False

# ❌ FORBIDDEN: Config files with values
config = yaml.safe_load(open("config.yaml"))
settings = json.load(open("settings.json"))
config = tomllib.load(open("config.toml", "rb"))

# ❌ FORBIDDEN: Inline defaults that should be configurable
def connect(host="localhost", port=5432):  # Hardcoded defaults
    ...
```

### Required Pattern

```python
# ✅ CORRECT: All config from environment via pydantic-settings
from src.core.config import settings

def connect():
    return Database(settings.database_url)
```

## Complete Settings Example

```python
# src/core/config.py
from functools import lru_cache

from pydantic import Field, SecretStr, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings from environment variables."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="forbid",  # Reject unknown env vars
    )

    # =========================================================================
    # Database
    # =========================================================================
    database_url: str = Field(
        ...,  # Required - no default
        description="PostgreSQL connection string",
    )
    db_pool_size: int = Field(
        default=5,
        ge=1,
        le=100,
        description="Connection pool size",
    )
    db_echo: bool = Field(
        default=False,
        description="Echo SQL queries",
    )

    # =========================================================================
    # Redis
    # =========================================================================
    redis_url: str = Field(
        default="redis://localhost:6379/0",
        description="Redis connection string",
    )

    # =========================================================================
    # API
    # =========================================================================
    api_host: str = Field(default="0.0.0.0")
    api_port: int = Field(default=8000, ge=1, le=65535)
    api_workers: int = Field(default=4, ge=1)
    api_cors_origins: list[str] = Field(default=["*"])

    # =========================================================================
    # Security
    # =========================================================================
    secret_key: SecretStr = Field(..., min_length=32)
    jwt_algorithm: str = Field(default="HS256")
    jwt_expiry_minutes: int = Field(default=60, ge=1)

    # =========================================================================
    # External Services
    # =========================================================================
    smtp_host: str | None = Field(default=None)
    smtp_port: int = Field(default=587)
    smtp_user: str | None = Field(default=None)
    smtp_password: SecretStr | None = Field(default=None)

    # =========================================================================
    # Feature Flags
    # =========================================================================
    debug: bool = Field(default=False)
    enable_docs: bool = Field(default=True)
    enable_metrics: bool = Field(default=True)

    # =========================================================================
    # Validators
    # =========================================================================
    @field_validator("database_url")
    @classmethod
    def validate_database_url(cls, v: str) -> str:
        if not v.startswith(("postgresql://", "postgres://")):
            raise ValueError("Only PostgreSQL is supported")
        return v

    @field_validator("api_cors_origins", mode="before")
    @classmethod
    def parse_cors_origins(cls, v: str | list[str]) -> list[str]:
        if isinstance(v, str):
            return [origin.strip() for origin in v.split(",")]
        return v


# Singleton with caching
@lru_cache
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()


# Convenience access
settings = get_settings()
```

## Nested Configuration

For complex configurations, use nested models with env prefixes:

```python
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class DatabaseSettings(BaseSettings):
    """Database-specific settings with DB_ prefix."""

    model_config = SettingsConfigDict(env_prefix="DB_")

    url: str = Field(..., description="Connection string")
    pool_size: int = Field(default=5, ge=1)
    pool_timeout: int = Field(default=30, ge=1)
    echo: bool = Field(default=False)


class RedisSettings(BaseSettings):
    """Redis-specific settings with REDIS_ prefix."""

    model_config = SettingsConfigDict(env_prefix="REDIS_")

    url: str = Field(default="redis://localhost:6379/0")
    max_connections: int = Field(default=10, ge=1)


class Settings(BaseSettings):
    """Main settings composing nested configs."""

    model_config = SettingsConfigDict(
        env_file=".env",
        case_sensitive=False,
    )

    # Nested settings
    db: DatabaseSettings = Field(default_factory=DatabaseSettings)
    redis: RedisSettings = Field(default_factory=RedisSettings)

    # Top-level settings
    debug: bool = Field(default=False)


settings = Settings()

# Usage:
# settings.db.url -> DB_URL
# settings.db.pool_size -> DB_POOL_SIZE
# settings.redis.url -> REDIS_URL
```

## Environment Variable Mapping

| Setting | Environment Variable |
|---------|---------------------|
| `database_url` | `DATABASE_URL` |
| `api_port` | `API_PORT` |
| `db.url` (nested) | `DB_URL` |
| `redis.max_connections` | `REDIS_MAX_CONNECTIONS` |

## Testing Configuration

```python
# tests/conftest.py
import pytest
from unittest.mock import patch

from src.core.config import Settings


@pytest.fixture
def test_settings() -> Settings:
    """Create settings for testing."""
    return Settings(
        database_url="postgresql://test:test@localhost:5432/test",
        secret_key="test-secret-key-minimum-32-characters-long",
        debug=True,
    )


@pytest.fixture(autouse=True)
def mock_settings(test_settings: Settings):
    """Replace settings globally for all tests."""
    with patch("src.core.config.settings", test_settings):
        yield test_settings
```

## .env.example Best Practices

```bash
# ==============================================================================
# Application Configuration
# ==============================================================================
# Copy to .env and fill in values. NEVER commit .env!

# ------------------------------------------------------------------------------
# Database (REQUIRED)
# ------------------------------------------------------------------------------
DATABASE_URL=postgresql://user:password@localhost:5432/dbname
DB_POOL_SIZE=5
DB_ECHO=false

# ------------------------------------------------------------------------------
# Redis
# ------------------------------------------------------------------------------
REDIS_URL=redis://localhost:6379/0

# ------------------------------------------------------------------------------
# API Server
# ------------------------------------------------------------------------------
API_HOST=0.0.0.0
API_PORT=8000
API_WORKERS=4
API_CORS_ORIGINS=http://localhost:3000,http://localhost:8080

# ------------------------------------------------------------------------------
# Security (REQUIRED)
# ------------------------------------------------------------------------------
# Generate with: openssl rand -hex 32
SECRET_KEY=
JWT_ALGORITHM=HS256
JWT_EXPIRY_MINUTES=60

# ------------------------------------------------------------------------------
# Email (Optional)
# ------------------------------------------------------------------------------
# SMTP_HOST=smtp.example.com
# SMTP_PORT=587
# SMTP_USER=
# SMTP_PASSWORD=

# ------------------------------------------------------------------------------
# Feature Flags
# ------------------------------------------------------------------------------
DEBUG=false
ENABLE_DOCS=true
ENABLE_METRICS=true
```

## Validation on Startup

The application should fail immediately if configuration is invalid:

```python
# src/main.py
import structlog

log = structlog.get_logger()

def main() -> int:
    # Settings validate on import - app fails fast if invalid
    from src.core.config import settings

    log.info(
        "configuration_loaded",
        debug=settings.debug,
        api_port=settings.api_port,
    )

    # Continue with app startup...
```

## Common Mistakes

### Mistake 1: Default Secrets

```python
# ❌ WRONG: Default value for secret
secret_key: str = Field(default="changeme")

# ✅ CORRECT: Required, no default
secret_key: str = Field(...)
```

### Mistake 2: Mutable Defaults

```python
# ❌ WRONG: Mutable default
allowed_hosts: list[str] = Field(default=["localhost"])

# ✅ CORRECT: Factory function
allowed_hosts: list[str] = Field(default_factory=lambda: ["localhost"])
```

### Mistake 3: Not Using SecretStr

```python
# ❌ WRONG: Secrets as plain strings (visible in logs/errors)
api_key: str = Field(...)

# ✅ CORRECT: SecretStr hides value
api_key: SecretStr = Field(...)

# Usage: api_key.get_secret_value()
```

### Mistake 4: Creating Multiple Instances

```python
# ❌ WRONG: New instance each time
def get_db():
    settings = Settings()  # Wasteful, parses env each time
    return connect(settings.database_url)

# ✅ CORRECT: Import singleton
from src.core.config import settings

def get_db():
    return connect(settings.database_url)
```

---

## Parameter Design: Read Config at Point of Use

**Don't pass config values through function layers. Read them where they're used.**

When you see a parameter passed through multiple layers but only used at the end, that's a code smell. The value should be loaded at the point of use instead.

### The Problem: Parameter Chains

```python
# ❌ BAD: Value passed through 3 layers, only used at the end
class Orchestrator:
    def create_evaluation(self, max_turns: int | None = None) -> Evaluation:
        return Evaluation.create(max_turns=max_turns)

class Evaluation:
    @classmethod
    def create(cls, max_turns: int | None = None) -> "Evaluation":
        worker = WorkerAgent(max_turns=max_turns)
        return cls(worker)

class WorkerAgent:
    def __init__(self, max_turns: int | None = None) -> None:
        self.max_turns = max_turns or 200  # Finally used here!
```

Problems with this pattern:
- Same default (200) appears in multiple places
- Each layer adds `if max_turns is not None` checks
- Adding a new config value requires changing every layer
- Tests need to mock or pass the value through every layer

### The Solution: Read Where Needed

```python
# ✅ GOOD: Read config at the point of use
from src.core.config import settings

class Orchestrator:
    def create_evaluation(self) -> Evaluation:
        return Evaluation.create()

class Evaluation:
    @classmethod
    def create(cls) -> "Evaluation":
        worker = WorkerAgent()
        return cls(worker)

class WorkerAgent:
    def __init__(self) -> None:
        self.max_turns = settings.worker.max_turns  # Read where used
```

### When to Pass Parameters

Pass parameters through layers only when:
1. **The value is different per call** - not config, but runtime data
2. **Each layer transforms the value** - not just passing through
3. **Testing requires injection** - but prefer mocking settings instead

```python
# ✅ OK to pass: This is runtime data, not config
def process_request(self, user_id: str, request: Request) -> Response:
    return self.handler.handle(user_id, request)

# ❌ BAD to pass: This is config, doesn't change per call
def process_request(self, user_id: str, timeout: int = 30) -> Response:
    return self.handler.handle(user_id, timeout=timeout)

# ✅ BETTER: Read config where used
def process_request(self, user_id: str) -> Response:
    return self.handler.handle(user_id)  # handler reads timeout from settings
```

### One Source of Truth for Defaults

If you see the same default value in multiple places, consolidate it:

```python
# ❌ BAD: Default duplicated in 3 places
class WorkerAgent:
    def __init__(self, max_turns: int = 200): ...

class Evaluation:
    def create(self, max_turns: int = 200): ...

# CLI
max_turns = max_turns or 200

# ✅ GOOD: Single source in settings
# settings.py
class WorkerSettings(BaseSettings):
    max_turns: int = Field(default=200)

# Everywhere else just reads from settings
```

### Before Adding a Parameter, Ask

1. **Where does this value come from?** (user input, config, hardcoded)
2. **Where is it actually consumed?** (which function/method uses it)
3. **Does every layer in between actually need it?**

If intermediate layers just pass it through → connect source to consumer directly.

### Apply This to Other Config Values

Look for parameters that flow through multiple layers but are only used at the end:
- Model names
- Timeout values
- Retry counts
- Permission modes
- Any value that could be read from settings
