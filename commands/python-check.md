---
name: python-check
description: Validate Python code against project conventions
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
---

# Python Convention Checker

Validate the current Python project against the python-standards conventions.

## Checks to Perform

### 1. Directory Structure

Verify the project follows the hierarchical structure:
- `src/` directory exists
- `src/models/` exists with `base.py`
- `src/utils/` exists
- `src/core/` exists
- Each domain in `core/` has `utils/`, `models/`, `tests/` subdirectories

**Report**: List missing directories and suggest creation.

### 2. Import Ordering

Use ruff to check import ordering:
```bash
ruff check --select=I .
```

**Report**: List files with import ordering violations.

### 3. Type Annotations

Check for missing type annotations:
```bash
ruff check --select=ANN .
```

**Report**: List functions/methods missing type hints.

### 4. Pydantic Patterns

Search for Pydantic models and verify:
- Models inherit from `BaseSchema` (not raw `BaseModel`)
- `ConfigDict` is used (not deprecated `class Config`)
- `@field_validator` is used (not deprecated `@validator`)

**Report**: List models not following patterns.

### 5. Docstring Style

Check for Google-style docstrings:
- Functions have docstrings
- Args, Returns, Raises sections are present

Use ruff:
```bash
ruff check --select=D .
```

**Report**: List functions with missing or malformed docstrings.

### 6. Naming Conventions

Verify snake_case naming:
- File names are snake_case
- Directory names are snake_case
- No camelCase or PascalCase in file/directory names

**Report**: List files/directories with naming violations.

### 7. Exception Hierarchy

For each domain in `core/`:
- Check if `exceptions.py` exists
- Verify exceptions follow the pattern (base exception per domain)

**Report**: List domains missing proper exception handling.

## Output Format

Present results as a summary table:

| Check | Status | Issues |
|-------|--------|--------|
| Directory Structure | PASS/FAIL | X issues |
| Import Ordering | PASS/FAIL | X issues |
| Type Annotations | PASS/FAIL | X issues |
| Pydantic Patterns | PASS/FAIL | X issues |
| Docstring Style | PASS/FAIL | X issues |
| Naming Conventions | PASS/FAIL | X issues |
| Exception Hierarchy | PASS/FAIL | X issues |

Then provide detailed findings for each failing check.

## Fixing Issues

After reporting, offer to fix issues automatically where possible:
- Import ordering: `ruff check --fix --select=I .`
- Create missing directories
- Add missing `__init__.py` files
