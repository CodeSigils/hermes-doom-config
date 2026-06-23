#!/usr/bin/env bash
# check-curator-drift.sh — Compare repo source skill vs Hermes mirror.
#
# The Hermes curator daemon may autonomously update the mirror skill at
# ~/.hermes/skills/emacs/doom-emacs-config/. This script reports any
# differences between the mirror and the repo source BEFORE the sync
# script overwrites them. It is informational — it does not modify either
# side.
#
# Usage: bash scripts/check-curator-drift.sh
# Exit: 0 (always informational)

set -euo pipefail

# ── Source shared config ────────────────────────────────────────────
cd "$(dirname "$0")"
. ./config.sh

ensure_in_repo

# ── Validate both sides exist ──────────────────────────────────────
if [[ ! -d "$SKILL_SRC" ]]; then
  printf 'Repo skill source not found: %s\n' "$SKILL_SRC"
  exit 1
fi

if [[ ! -d "$SKILL_DST" ]]; then
  printf 'Mirror skill not found: %s\n' "$SKILL_DST"
  exit 1
fi

# ── Build file inventories (relative paths only) ───────────────────
mapfile -t src_files < <(cd "$SKILL_SRC" && find . -type f | sort)
mapfile -t dst_files < <(cd "$SKILL_DST" && find . -type f | sort)

declare -A src_set dst_set
for f in "${src_files[@]}"; do src_set["$f"]=1; done
for f in "${dst_files[@]}"; do dst_set["$f"]=1; done

added=()
removed=()
common=()

for f in "${dst_files[@]}"; do
  if [[ -z "${src_set["$f"]:-}" ]]; then
    added+=("$f")
  else
    common+=("$f")
  fi
done

for f in "${src_files[@]}"; do
  if [[ -z "${dst_set["$f"]:-}" ]]; then
    removed+=("$f")
  fi
done

# ── Report ──────────────────────────────────────────────────────────
drift=false

if [[ ${#added[@]} -gt 0 ]]; then
  drift=true
  printf '=== Files in mirror only (curator additions) ===\n'
  for f in "${added[@]}"; do
    size=$(wc -c < "$SKILL_DST/$f" | tr -d ' ')
    printf '  + %s  (%s bytes)\n' "$f" "$size"
  done
  printf '\n'
fi

if [[ ${#removed[@]} -gt 0 ]]; then
  drift=true
  printf '=== Files in repo only (missing from mirror) ===\n'
  for f in "${removed[@]}"; do
    printf '  - %s\n' "$f"
  done
  printf '\n'
fi

if [[ ${#common[@]} -gt 0 ]]; then
  changed=0
  for f in "${common[@]}"; do
    if ! diff -q "$SKILL_SRC/$f" "$SKILL_DST/$f" >/dev/null 2>&1; then
      if [[ $changed -eq 0 ]]; then
        printf '=== Common files with content differences ===\n'
        changed=1
      fi
      src_lines=$(wc -l < "$SKILL_SRC/$f" | tr -d ' ')
      dst_lines=$(wc -l < "$SKILL_DST/$f" | tr -d ' ')
      printf '  ~ %s  (repo: %s lines, mirror: %s lines)\n' "$f" "$src_lines" "$dst_lines"
      drift=true
    fi
  done
  if [[ $changed -gt 0 ]]; then
    printf '\n'
  fi
fi

if [[ "$drift" == false ]]; then
  printf 'No drift — mirror matches repo source exactly.\n'
fi
