#!/usr/bin/env bash
# check-doom-skill-mirror.sh — Verify skill mirror matches repo source
# Usage: ./scripts/check-doom-skill-mirror.sh
set -euo pipefail
. "$(dirname "$0")/config.sh"

confirm_skill_src
confirm_skill_dst

diff -qr -- "$SKILL_SRC" "$SKILL_DST"
printf 'Doom skill mirror is in sync: %s == %s\n' "$SKILL_SRC" "$SKILL_DST"
