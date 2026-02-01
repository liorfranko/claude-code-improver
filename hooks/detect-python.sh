#!/bin/bash
# Detect if current directory is a Python project and output reminder

set -euo pipefail

# Check for Python files
py_files=$(find . -maxdepth 3 -name "*.py" -type f 2>/dev/null | head -1)

if [ -n "$py_files" ]; then
  echo "Python project detected. Python development standards are active."
  echo ""
  echo "Key conventions:"
  echo "- Structure: hierarchical src/ with utils/, models/, tests/ at each level"
  echo "- Typing: full annotations, Pydantic v2 with BaseSchema"
  echo "- Imports: stdlib → third-party → local"
  echo "- Docstrings: Google style"
  echo "- Logging: structlog"
  echo "- Errors: domain-specific exceptions per module"
  echo "- Files: one class/concern per file, snake_case naming"
  echo ""
  echo "Commands: /python-init (scaffold), /python-check (validate)"
fi

exit 0
