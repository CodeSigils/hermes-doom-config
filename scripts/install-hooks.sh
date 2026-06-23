#!/usr/bin/env bash
# install-hooks.sh: Install pre-commit hook into .git/hooks/.
# Usage: bash scripts/install-hooks.sh
# Run from repo root or any subdirectory.
set -euo pipefail

# Resolve repo root from script location
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

HOOK_SRC="$SCRIPT_DIR/pre-commit-hook.sh"
HOOK_DST="$REPO_ROOT/.git/hooks/pre-commit"

if [ ! -d "$REPO_ROOT/.git" ]; then
    printf 'ERROR: %s is not inside a git repository.\n' "$REPO_ROOT" >&2
    exit 1
fi

if [ ! -f "$HOOK_SRC" ]; then
    printf 'ERROR: Source hook %s not found.\n' "$HOOK_SRC" >&2
    exit 1
fi

if [ -f "$HOOK_DST" ] && [ ! -L "$HOOK_DST" ]; then
    printf 'Backing up existing hook to %s.bak\n' "$HOOK_DST"
    cp "$HOOK_DST" "$HOOK_DST.bak"
fi

cp "$HOOK_SRC" "$HOOK_DST"
chmod +x "$HOOK_DST"
printf 'Installed pre-commit hook at %s\n' "$HOOK_DST"
printf '  (source: %s)\n' "$HOOK_SRC"
