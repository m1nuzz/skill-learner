#!/usr/bin/env bash
# Print one of: hermes | openclaw | claude-code | generic
# Used by install.sh and by the Codify phase to pick the correct skills path.

set -euo pipefail

if command -v hermes >/dev/null 2>&1 || [ -d "$HOME/.hermes" ]; then
  echo hermes
elif command -v openclaw >/dev/null 2>&1 || [ -d "$HOME/.openclaw" ]; then
  echo openclaw
elif [ -d "$HOME/.claude/skills" ] || command -v claude >/dev/null 2>&1; then
  echo claude-code
else
  echo generic
fi
