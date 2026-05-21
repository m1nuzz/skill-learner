#!/usr/bin/env bash
# Install skill-learner into the detected host's skills directory.
# Pass --all to install symlinks into every known host path simultaneously.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$(cd "$SCRIPT_DIR/.." && pwd)"   # absolute path to the skill folder

mode="${1:-auto}"

install_one() {
  local dest="$1"
  local label="$2"
  mkdir -p "$(dirname "$dest")"
  ln -snf "$SRC" "$dest"
  echo "Installed -> $dest  ($label)"
}

if [ "$mode" = "--all" ] || [ "$mode" = "-a" ]; then
  install_one "$HOME/.hermes/skills/skill-learner"   "hermes-agent"
  install_one "$HOME/.openclaw/skills/skill-learner" "OpenClaw (personal)"
  install_one "$HOME/.agents/skills/skill-learner"   "AgentSkills generic"
  install_one "$HOME/.claude/skills/skill-learner"   "Claude Code"
  exit 0
fi

host="$("$SCRIPT_DIR/detect_host.sh")"
case "$host" in
  hermes)      install_one "$HOME/.hermes/skills/skill-learner"   "hermes-agent" ;;
  openclaw)    install_one "$HOME/.openclaw/skills/skill-learner" "OpenClaw" ;;
  claude-code) install_one "$HOME/.claude/skills/skill-learner"   "Claude Code" ;;
  generic|*)   install_one "$HOME/.agents/skills/skill-learner"   "AgentSkills generic" ;;
esac

echo
echo "Detected host: $host"
echo "To install into every known location, re-run: $0 --all"
