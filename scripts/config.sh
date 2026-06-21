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
SKILL_DST="${SKILL_DST:-$HOME/.hermes/skills/emacs/doom-emacs-config}"

# ── Helpers ───────────────────────────────────────────────────────────

# grep_rn: portable recursive grep wrapper
# Usage: grep_rn <pattern> [extra_grep_args...]
# Recursively searches markdown files from repo root, excluding .git/
grep_rn() {
  local pattern="$1"
  shift
  grep -Ern --include='*.md' "$@" "$pattern" "$REPO_ROOT" \
    | grep -vF "$REPO_ROOT/.git/" || true
}

# grep_md: same as grep_rn but for ERE patterns with no extra args
# Shorthand for simple stale-pattern searches
grep_md() {
  grep_rn "$1"
}

# extract_paths: from stdin, extract backtick-quoted path references
#   (references/, scripts/, .agents/ — leading ./ optional)
# Usage: echo "$line" | extract_paths
extract_paths() {
  grep -Eo '`(\./)?(references/|scripts/|\.agents/)[^`]+`' \
    | tr -d '`' || true
}

# find_path_refs: find all markdown files in REPO_ROOT containing
# backtick-quoted path references. Used to drive cross-reference checks.
# Output: file:line:content  (same format as grep -rn)
find_path_refs() {
  grep -Ern --include='*.md' \
    '`(\./)?(references/|scripts/|\.agents/)' \
    "$REPO_ROOT" \
    | grep -vF "$REPO_ROOT/.git/" \
    || true
}

# ensure_in_repo: die if cwd is outside the repo tree
ensure_in_repo() {
  if [[ "$(pwd)" != "$REPO_ROOT"* ]]; then
    printf 'Error: must be run from within the doom-emacs-config repo\n' >&2
    exit 1
  fi
  cd "$REPO_ROOT"
}

# confirm_skill_src: die if SKILL_SRC/SKILL.md missing
confirm_skill_src() {
  if [[ ! -f "$SKILL_SRC/SKILL.md" ]]; then
    printf 'Source skill missing SKILL.md: %s\n' "$SKILL_SRC" >&2
    exit 1
  fi
}

# confirm_skill_dst: die if SKILL_DST/SKILL.md missing
confirm_skill_dst() {
  if [[ ! -f "$SKILL_DST/SKILL.md" ]]; then
    printf 'Mirror skill missing SKILL.md: %s\n' "$SKILL_DST" >&2
    exit 1
  fi
}
