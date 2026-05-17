#!/usr/bin/env bash
set -euo pipefail

SRC="${DOOM_SKILL_SRC:-$HOME/.config/doom/.agents/skills/doom-emacs}"
DST="${DOOM_SKILL_DST:-$HOME/.hermes/skills/emacs/doom-emacs-config}"

if [[ ! -f "$SRC/SKILL.md" ]]; then
  printf 'Source skill missing SKILL.md: %s\n' "$SRC" >&2
  exit 1
fi

case "$DST" in
  "$HOME/.hermes/skills/"*) ;;
  *)
    printf 'Refusing to replace unexpected destination: %s\n' "$DST" >&2
    exit 1
    ;;
esac

rm -rf -- "$DST"
mkdir -p -- "$(dirname "$DST")"
cp -a -- "$SRC" "$DST"
diff -qr -- "$SRC" "$DST"

printf 'Doom skill mirror synced: %s -> %s\n' "$SRC" "$DST"
