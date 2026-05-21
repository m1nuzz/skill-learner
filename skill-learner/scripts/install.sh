#!/usr/bin/env bash
# Cross-host installer for skill-learner.
#
# One-line install (no clone required):
#   curl -fsSL https://raw.githubusercontent.com/m1nuzz/skill-learner/main/skill-learner/scripts/install.sh | bash
#
# Or, from a local clone:
#   bash skill-learner/scripts/install.sh
#
# Modes:
#   --all       Install into every known host path (hermes, OpenClaw, Claude Code,
#               and the generic AgentSkills path).
#   --remote    Force download from GitHub even when run from a local clone.
#   --dev       Symlink from the local clone instead of copying (developer mode).
#               Refuses to symlink from /tmp or /var/tmp.
#   --ref REF   Use a specific git ref (branch, tag, or commit). Default: main.
#   -h, --help  Print this help and exit.

set -euo pipefail

REPO="m1nuzz/skill-learner"
REF="${SKILL_LEARNER_REF:-main}"
SKILL_NAME="skill-learner"

mode_all=false
mode_remote=false
mode_dev=false

print_help() {
  sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --all)     mode_all=true; shift ;;
    --remote)  mode_remote=true; shift ;;
    --dev)     mode_dev=true; shift ;;
    --ref)     REF="$2"; shift 2 ;;
    -h|--help) print_help; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; echo "Run with --help to see usage." >&2; exit 2 ;;
  esac
done

detect_host() {
  if command -v hermes >/dev/null 2>&1 || [ -d "$HOME/.hermes" ]; then
    echo hermes
  elif command -v openclaw >/dev/null 2>&1 || [ -d "$HOME/.openclaw" ]; then
    echo openclaw
  elif [ -d "$HOME/.claude/skills" ] || command -v claude >/dev/null 2>&1; then
    echo claude-code
  else
    echo generic
  fi
}

# Try to locate the local clone (when this script lives next to a SKILL.md).
SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
LOCAL_SRC=""
if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/../SKILL.md" ]; then
  LOCAL_SRC="$(cd "$SCRIPT_DIR/.." && pwd)"
fi

# --dev requires a local clone
if $mode_dev && [ -z "$LOCAL_SRC" ]; then
  echo "--dev requires running install.sh from a local clone." >&2
  exit 3
fi

# If there's no local clone, force remote mode.
if [ -z "$LOCAL_SRC" ] && ! $mode_dev; then
  mode_remote=true
fi

# Resolve the source directory we will install from.
SRC=""
CLEANUP_TMP=""

if $mode_dev; then
  case "$LOCAL_SRC" in
    /tmp/*|/var/tmp/*)
      echo "Refusing to symlink from a temp directory: $LOCAL_SRC" >&2
      echo "Move your clone to a stable location (e.g. ~/code/skill-learner) and re-run." >&2
      exit 4
      ;;
  esac
  SRC="$LOCAL_SRC"
elif $mode_remote; then
  command -v curl >/dev/null 2>&1 || { echo "curl is required for --remote install" >&2; exit 5; }
  command -v tar  >/dev/null 2>&1 || { echo "tar is required for --remote install" >&2; exit 5; }
  CLEANUP_TMP="$(mktemp -d)"
  trap 'rm -rf "$CLEANUP_TMP"' EXIT
  echo "Downloading $REPO@$REF from GitHub..."
  curl -fsSL "https://github.com/$REPO/archive/$REF.tar.gz" \
    | tar -xz -C "$CLEANUP_TMP"
  SRC="$(find "$CLEANUP_TMP" -mindepth 2 -maxdepth 3 -type d -name "$SKILL_NAME" \
        -path "*/skill-learner-*/$SKILL_NAME" | head -n1)"
  if [ -z "$SRC" ] || [ ! -f "$SRC/SKILL.md" ]; then
    echo "Failed to locate $SKILL_NAME folder inside the downloaded archive." >&2
    exit 6
  fi
else
  SRC="$LOCAL_SRC"
fi

install_one() {
  local dest="$1"
  local label="$2"
  mkdir -p "$(dirname "$dest")"

  # Remove existing install (regular dir or symlink) before writing.
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    rm -rf "$dest"
  fi

  if $mode_dev; then
    ln -sn "$SRC" "$dest"
    echo "Symlinked -> $dest -> $SRC  ($label)"
  else
    cp -R "$SRC" "$dest"
    echo "Installed -> $dest  ($label)"
  fi
}

if $mode_all; then
  install_one "$HOME/.hermes/skills/$SKILL_NAME"   "hermes-agent"
  install_one "$HOME/.openclaw/skills/$SKILL_NAME" "OpenClaw"
  install_one "$HOME/.agents/skills/$SKILL_NAME"   "AgentSkills generic"
  install_one "$HOME/.claude/skills/$SKILL_NAME"   "Claude Code"
else
  host="$(detect_host)"
  case "$host" in
    hermes)      install_one "$HOME/.hermes/skills/$SKILL_NAME"   "hermes-agent" ;;
    openclaw)    install_one "$HOME/.openclaw/skills/$SKILL_NAME" "OpenClaw" ;;
    claude-code) install_one "$HOME/.claude/skills/$SKILL_NAME"   "Claude Code" ;;
    generic|*)   install_one "$HOME/.agents/skills/$SKILL_NAME"   "AgentSkills generic" ;;
  esac
  echo
  echo "Detected host: $host"
fi

echo
if $mode_dev; then
  echo "Mode: developer (symlink from $LOCAL_SRC)."
elif $mode_remote; then
  echo "Mode: remote install (downloaded $REPO@$REF, copied into target)."
else
  echo "Mode: local install (copied from $LOCAL_SRC into target)."
fi

if ! $mode_all; then
  echo "Tip: re-run with --all to install into every known host path."
fi
