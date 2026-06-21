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
SKILL_SRC="${SKILL_SRC:-$DOOMDIR/.agents/skills/doom-emacs}"
EXPECTED_SKILL_DST="$HOME/.hermes/skills/emacs/doom-emacs-config"
SKILL_DST="${SKILL_DST:-$EXPECTED_SKILL_DST}"
EXPECTED_SKILL_NAME="doom-emacs-config"

# ── Helpers ───────────────────────────────────────────────────────────

# ensure_in_repo: die if cwd is outside the repo tree
ensure_in_repo() {
  if [[ "$(pwd)" != "$REPO_ROOT"* ]]; then
    printf 'Error: must be run from within the doom-emacs-config repo\n' >&2
    exit 1
  fi
  cd "$REPO_ROOT"
}

canonical_existing_path() {
  local path="$1"
  local dir
  dir=$(cd "$(dirname "$path")" && pwd -P)
  printf '%s/%s\n' "$dir" "$(basename "$path")"
}

skill_name() {
  local skill_file="$1"
  sed -nE 's/^name:[[:space:]]*["'\'']?([^"'\'']+)["'\'']?[[:space:]]*$/\1/p' \
    "$skill_file" | head -1
}

# confirm_skill_src: verify the canonical in-repository source and skill identity
confirm_skill_src() {
  local git_root
  git_root=$(git -C "$REPO_ROOT" rev-parse --show-toplevel 2>/dev/null) || {
    printf 'Source repository is not a Git checkout: %s\n' "$REPO_ROOT" >&2
    exit 1
  }
  if [[ "$(cd "$git_root" && pwd -P)" != "$REPO_ROOT" ]]; then
    printf 'Script root does not match Git repository root: %s\n' "$REPO_ROOT" >&2
    exit 1
  fi
  if [[ ! -f "$SKILL_SRC/SKILL.md" ]]; then
    printf 'Source skill missing SKILL.md: %s\n' "$SKILL_SRC" >&2
    exit 1
  fi
  local expected_src actual_src actual_name
  expected_src=$(canonical_existing_path "$REPO_ROOT/.agents/skills/doom-emacs")
  actual_src=$(canonical_existing_path "$SKILL_SRC")
  if [[ "$actual_src" != "$expected_src" ]]; then
    printf 'Refusing unexpected skill source: %s (expected %s)\n' \
      "$actual_src" "$expected_src" >&2
    exit 1
  fi
  actual_name=$(skill_name "$SKILL_SRC/SKILL.md")
  if [[ "$actual_name" != "$EXPECTED_SKILL_NAME" ]]; then
    printf 'Source skill identity mismatch: %s (expected %s)\n' \
      "${actual_name:-missing}" "$EXPECTED_SKILL_NAME" >&2
    exit 1
  fi
}

# confirm_skill_target: verify the destination is exactly the configured mirror
confirm_skill_target() {
  if [[ "$SKILL_DST" != "$EXPECTED_SKILL_DST" ]]; then
    printf 'Refusing unexpected skill destination: %s (expected %s)\n' \
      "$SKILL_DST" "$EXPECTED_SKILL_DST" >&2
    exit 1
  fi
  if [[ -L "$SKILL_DST" ]]; then
    printf 'Refusing symlinked skill destination: %s\n' "$SKILL_DST" >&2
    exit 1
  fi
  local component
  for component in \
    "$HOME/.hermes" \
    "$HOME/.hermes/skills" \
    "$HOME/.hermes/skills/emacs"; do
    if [[ -L "$component" ]]; then
      printf 'Refusing destination beneath symlinked directory: %s\n' \
        "$component" >&2
      exit 1
    fi
  done
}

# confirm_skill_dst: verify an existing mirror has the expected skill identity
confirm_skill_dst() {
  confirm_skill_target
  if [[ ! -f "$SKILL_DST/SKILL.md" ]]; then
    printf 'Mirror skill missing SKILL.md: %s\n' "$SKILL_DST" >&2
    exit 1
  fi
  local actual_name
  actual_name=$(skill_name "$SKILL_DST/SKILL.md")
  if [[ "$actual_name" != "$EXPECTED_SKILL_NAME" ]]; then
    printf 'Mirror skill identity mismatch: %s (expected %s)\n' \
      "${actual_name:-missing}" "$EXPECTED_SKILL_NAME" >&2
    exit 1
  fi
}
