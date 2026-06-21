#!/usr/bin/env bash
# sync-doom-skill-mirror.sh — Sync repo skill tree to Hermes runtime mirror
# Usage: ./scripts/sync-doom-skill-mirror.sh
set -euo pipefail
# shellcheck source=scripts/config.sh
. "$(dirname "$0")/config.sh"

confirm_skill_src
confirm_skill_target

if [[ -e "$SKILL_DST" ]]; then
  confirm_skill_dst
fi

destination_parent=$(dirname "$SKILL_DST")
mkdir -p -- "$destination_parent"
stage_dir=$(mktemp -d "$destination_parent/.doom-emacs-config.stage.XXXXXX")
backup_dir=""
swapped=0

cleanup() {
  local status=$?
  if [[ "$status" -ne 0 && "$swapped" -eq 1 ]]; then
    rm -rf -- "$SKILL_DST"
  fi
  if [[ "$status" -ne 0 && -n "$backup_dir" && -d "$backup_dir" ]]; then
    mv -- "$backup_dir" "$SKILL_DST"
    backup_dir=""
  fi
  if [[ -d "$stage_dir" ]]; then
    rm -rf -- "$stage_dir"
  fi
  if [[ -n "$backup_dir" && -d "$backup_dir" ]]; then
    rm -rf -- "$backup_dir"
  fi
  exit "$status"
}
trap cleanup EXIT INT TERM

cp -a -- "$SKILL_SRC/." "$stage_dir/"
if [[ "$(skill_name "$stage_dir/SKILL.md")" != "$EXPECTED_SKILL_NAME" ]]; then
  printf 'Staged skill identity validation failed\n' >&2
  exit 1
fi
diff -qr -- "$SKILL_SRC" "$stage_dir"

if [[ -e "$SKILL_DST" ]]; then
  backup_dir=$(mktemp -d "$destination_parent/.doom-emacs-config.backup.XXXXXX")
  rmdir -- "$backup_dir"
  mv -- "$SKILL_DST" "$backup_dir"
fi
mv -- "$stage_dir" "$SKILL_DST"
stage_dir=""
swapped=1
diff -qr -- "$SKILL_SRC" "$SKILL_DST"

if [[ -n "$backup_dir" && -d "$backup_dir" ]]; then
  rm -rf -- "$backup_dir"
  backup_dir=""
fi
trap - EXIT INT TERM

printf 'Doom skill mirror synced: %s -> %s\n' "$SKILL_SRC" "$SKILL_DST"
