#!/usr/bin/env bash
set -euo pipefail

SRC="${DOOM_SKILL_SRC:-$HOME/.config/doom/.agents/skills/doom-emacs}"
DST="${DOOM_SKILL_DST:-$HOME/.hermes/skills/emacs/doom-emacs-config}"

if [[ ! -f "$SRC/SKILL.md" ]]; then
  printf 'Source skill missing SKILL.md: %s\n' "$SRC" >&2
  exit 1
fi

if [[ ! -f "$DST/SKILL.md" ]]; then
  printf 'Mirror skill missing SKILL.md: %s\n' "$DST" >&2
  exit 1
fi

diff -qr -- "$SRC" "$DST"
printf 'Doom skill mirror is in sync: %s == %s\n' "$SRC" "$DST"
