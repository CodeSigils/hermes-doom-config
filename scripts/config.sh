#!/usr/bin/env bash
# config.sh — Shared variables and utilities for doom-emacs-config scripts
# Source from other scripts with: . "$(dirname "$0")/config.sh"
#
# Cross-platform grep rules:
# - Use grep -E (ERE) instead of BRE with \|, \?, \+ — it's cleaner and
#   works on both GNU and BSD grep. Never use grep -P (Perl regex).
# - Use grep -F for fixed-string searches to avoid accidental regex.
# - Use grep -o (GNU extension) only when you know the platform supports it;
#   stdin-based sed/awk workarounds are available for strict POSIX needs.
# - \xNN hex escapes are -P-only; use literal characters or printf instead.
# - --include is a GNU extension; for strict portability use find ... -exec.

set -euo pipefail

# ── Resolve repo root (caller location-agnostic) ──────────────────────
# Works whether script is called via ./scripts/foo.sh or bash scripts/foo.sh
REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

# ── Directories ───────────────────────────────────────────────────────
DOOMDIR="${DOOMDIR:-$HOME/.config/doom}"

# ── Helpers ───────────────────────────────────────────────────────────

# ensure_in_repo: die if cwd is outside the repo tree
ensure_in_repo() {
  if [[ "$(pwd)" != "$REPO_ROOT"* ]]; then
    printf 'Error: must be run from within the doom-emacs-config repo\n' >&2
    exit 1
  fi
  cd "$REPO_ROOT"
}
