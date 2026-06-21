#!/usr/bin/env bash
# sync-doom-skill-mirror.sh — Sync repo skill tree to Hermes runtime mirror
# Usage: ./scripts/sync-doom-skill-mirror.sh
set -euo pipefail
. "$(dirname "$0")/config.sh"

confirm_skill_src

case "$SKILL_DST" in
  "$HOME/.hermes/skills/"*) ;;
  *)
    printf 'Refusing to replace unexpected destination: %s\n' "$SKILL_DST" >&2
    exit 1
    ;;
esac

rm -rf -- "$SKILL_DST"
mkdir -p -- "$(dirname "$SKILL_DST")"
cp -a -- "$SKILL_SRC" "$SKILL_DST"
diff -qr -- "$SKILL_SRC" "$SKILL_DST"

printf 'Doom skill mirror synced: %s -> %s\n' "$SKILL_SRC" "$SKILL_DST"
