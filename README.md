# claude-code-improver

A Claude Code plugin that enforces Python coding standards and scaffolds projects with a consistent structure.

## Installation

```bash
# Clone the repository
git clone https://github.com/liorfranko/claude-code-improver.git

# Use with Claude Code
claude --plugin-dir /path/to/claude-code-improver
```

Or add to your Claude Code settings to enable permanently.

## Features

- **Auto-detection**: Activates when working in Python projects
- **Scaffolding**: Create new projects with `/python-init`
- **Validation**: Check code conventions with `/python-check`
- **Code review**: Proactive Python code reviewer agent

## Standards Enforced

| Category | Standard |
|----------|----------|
| Structure | Hierarchical `src/` with `utils/`, `models/`, `tests/` at each level |
| Tools | uv, pytest, ruff |
| Typing | Full annotations, Pydantic v2 |
| Pydantic | Base model with `ConfigDict`, `@field_validator` |
| Imports | stdlib → third-party → local |
| Naming | snake_case everywhere |
| Docstrings | Google style |
| Logging | structlog |
| Errors | Domain-specific exceptions per module |
| Files | One class/concern per file |
| **Config** | **pydantic-settings only, NO hardcoded values** |

## Project Structure

The plugin enforces this structure for Python projects:

```
project-name/
├── pyproject.toml
├── .python-version
├── .env                      # Local config (gitignored)
├── .env.example              # Config template (committed)
├── src/
│   ├── cli/ (or api/)
│   ├── utils/
│   ├── models/
│   │   └── base.py          # BaseSchema
│   └── core/
│       ├── config.py        # pydantic-settings
│       └── <domain>/
│           ├── service.py
│           ├── repository.py
│           ├── exceptions.py
│           ├── utils/
│           ├── models/
│           └── tests/
```

## Commands

- `/python-init` - Scaffold a new Python project with the standard structure
- `/python-check` - Validate existing code against conventions

## Components

| Component | Description |
|-----------|-------------|
| **Skill**: `python-standards` | Auto-activates on Python projects, provides coding standards |
| **Agent**: `python-reviewer` | Reviews code for convention adherence (proactive + on-demand) |
| **Hook**: `SessionStart` | Detects Python projects and shows standards reminder |

## License

MIT
