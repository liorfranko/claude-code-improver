---
name: python-init
description: Scaffold a new Python project with standard structure
allowed-tools:
  - Bash
  - Write
  - AskUserQuestion
---

# Python Project Scaffolding

Scaffold a new Python project following the python-standards conventions.

## Process

1. **Determine project name**: Use the current directory name as the project name.

2. **Ask entry point type**: Present the user with a choice:
   - CLI (command-line interface)
   - API (FastAPI web service)

3. **Create directory structure**:
   ```
   ./
   ├── pyproject.toml
   ├── .python-version
   ├── .gitignore
   ├── README.md
   └── src/
       ├── __init__.py
       ├── cli/ (or api/)
       │   ├── __init__.py
       │   └── main.py
       ├── utils/
       │   └── __init__.py
       ├── models/
       │   ├── __init__.py
       │   └── base.py
       └── core/
           ├── __init__.py
           └── example/
               ├── __init__.py
               ├── service.py
               ├── exceptions.py
               ├── utils/
               │   └── __init__.py
               ├── models/
               │   └── __init__.py
               └── tests/
                   └── __init__.py
   ```

4. **Generate files** using templates from the python-standards skill:
   - `pyproject.toml` with uv, pytest, ruff configuration
   - `src/models/base.py` with BaseSchema
   - Entry point (`cli/main.py` or `api/main.py`)
   - `.python-version` with `3.12`
   - `.gitignore` for Python projects
   - Basic `README.md`

5. **Initialize git** if not already a repository.

6. **Report completion** with next steps:
   - `uv sync` to install dependencies
   - How to run the project

## Templates

Reference templates from the python-standards skill at:
`${CLAUDE_PLUGIN_ROOT}/skills/python-standards/templates/`

## Notes

- All `__init__.py` files should be empty initially
- The example domain module demonstrates the structure pattern
- User can rename/remove the example module after scaffolding
