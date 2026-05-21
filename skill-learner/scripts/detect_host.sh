#!/usr/bin/env bash
# Print one of: hermes | openclaw | claude-code | generic
#
# Standalone utility — the logic is also inlined in install.sh so that the
# `curl ... | bash` install path works without needing two files.

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
