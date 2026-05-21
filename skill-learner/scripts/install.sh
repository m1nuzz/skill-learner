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
#   --all          Install into every host that is already present on this
#                  machine (hermes, OpenClaw, Claude Code). If none is
#                  detected, install only into the generic ~/.agents path.
#                  Never creates host directories for agents you don't have.
#   --with LIST    Install into an explicit comma-separated list of hosts.
#                  Valid host names: hermes, openclaw, claude-code, agents.
#                  Example: --with hermes,agents
#   --remote       Force download from GitHub even when run from a local clone.
#   --dev          Symlink from the local clone instead of copying (developer
#                  mode). Refuses to symlink from /tmp or /var/tmp.
#   --ref REF      Use a specific git ref (branch, tag, or commit). Default: main.
#   -h, --help     Print this help and exit.

set -euo pipefail

REPO="m1nuzz/skill-learner"
REF="${SKILL_LEARNER_REF:-main}"
SKILL_NAME="skill-learner"

mode_all=false
mode_remote=false
mode_dev=false
with_list=""

print_help() {
  sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --all)     mode_all=true; shift ;;
    --with)    with_list="$2"; shift 2 ;;
    --remote)  mode_remote=true; shift ;;
    --dev)     mode_dev=true; shift ;;
    --ref)     REF="$2"; shift 2 ;;
    -h|--help) print_help; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; echo "Run with --help to see usage." >&2; exit 2 ;;
  esac
done

# Whether a given host appears to be installed on this machine.
host_present() {
  case "$1" in
    hermes)      command -v hermes   >/dev/null 2>&1 || [ -d "$HOME/.hermes" ] ;;
    openclaw)    command -v openclaw >/dev/null 2>&1 || [ -d "$HOME/.openclaw" ] ;;
    claude-code) command -v claude   >/dev/null 2>&1 || [ -d "$HOME/.claude" ] ;;
    agents)      [ -d "$HOME/.agents" ] ;;
    *) return 1 ;;
  esac
}

# Install path for a given host name.
host_path() {
  case "$1" in
    hermes)      echo "$HOME/.hermes/skills/$SKILL_NAME" ;;
    openclaw)    echo "$HOME/.openclaw/skills/$SKILL_NAME" ;;
    claude-code) echo "$HOME/.claude/skills/$SKILL_NAME" ;;
    agents)      echo "$HOME/.agents/skills/$SKILL_NAME" ;;
    *) return 1 ;;
  esac
}

# Friendly label for a host name.
host_label() {
  case "$1" in
    hermes)      echo "hermes-agent" ;;
    openclaw)    echo "OpenClaw" ;;
    claude-code) echo "Claude Code" ;;
    agents)      echo "AgentSkills generic" ;;
    *) echo "$1" ;;
  esac
}

# Auto-detect the single best host for default mode.
detect_host() {
  if host_present hermes;      then echo hermes;      return; fi
  if host_present openclaw;    then echo openclaw;    return; fi
  if host_present claude-code; then echo claude-code; return; fi
  echo agents
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
  local host="$1"
  local dest
  dest="$(host_path "$host")"
  local label
  label="$(host_label "$host")"

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

# Determine target hosts.
targets=()

if [ -n "$with_list" ]; then
  # Explicit list — install into exactly these hosts.
  IFS=',' read -r -a __with_arr <<<"$with_list"
  for h in "${__with_arr[@]}"; do
    h="$(echo "$h" | tr -d '[:space:]')"
    case "$h" in
      hermes|openclaw|claude-code|agents) targets+=("$h") ;;
      *) echo "Unknown host in --with: $h (valid: hermes, openclaw, claude-code, agents)" >&2; exit 7 ;;
    esac
  done
elif $mode_all; then
  # Only install into hosts that already exist on this machine.
  for h in hermes openclaw claude-code; do
    if host_present "$h"; then
      targets+=("$h")
    fi
  done
  # If nothing detected, fall back to the generic LCD path only.
  if [ ${#targets[@]} -eq 0 ]; then
    targets=(agents)
  fi
else
  # Default: single best detected host.
  targets=("$(detect_host)")
fi

for h in "${targets[@]}"; do
  install_one "$h"
done

echo
if $mode_dev; then
  echo "Mode: developer (symlink from $LOCAL_SRC)."
elif $mode_remote; then
  echo "Mode: remote install (downloaded $REPO@$REF, copied into target)."
else
  echo "Mode: local install (copied from $LOCAL_SRC into target)."
fi

if [ -z "$with_list" ] && ! $mode_all; then
  # Show the --all tip only if other hosts are actually present.
  other_present=false
  for h in hermes openclaw claude-code; do
    if [ "$h" != "${targets[0]}" ] && host_present "$h"; then
      other_present=true
      break
    fi
  done
  if $other_present; then
    echo "Tip: re-run with --all to install into every detected host on this machine."
  fi
fi
