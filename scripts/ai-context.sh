#!/usr/bin/env bash
# ai-context.sh — Gather context for asking AI about Doom Emacs config
# Usage: ./scripts/ai-context.sh [--include-file PATH]
set -euo pipefail
# shellcheck source=scripts/config.sh
. "$(dirname "$0")/config.sh"

cd "$DOOMDIR"
FILE=""
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --include-file)
      [[ "$#" -ge 2 ]] || {
        printf 'Error: --include-file requires a path\n' >&2
        exit 2
      }
      FILE="$2"
      shift 2
      ;;
    --help)
      printf 'Usage: %s [--include-file PATH]\n' "$0"
      exit 0
      ;;
    *)
      printf 'Error: unknown argument: %s\n' "$1" >&2
      printf 'Use --include-file PATH to opt in to file content.\n' >&2
      exit 2
      ;;
  esac
done

printf '=== Doom Emacs Config Context ===\n\n'
printf '**Doom Version:**\n'
doom_command=""
if command -v doom >/dev/null 2>&1; then
  doom_command=$(command -v doom)
elif [[ -x "$HOME/.config/emacs/bin/doom" ]]; then
  doom_command="$HOME/.config/emacs/bin/doom"
fi
if [[ -n "$doom_command" ]]; then
  "$doom_command" version 2>/dev/null || printf '  (doom version failed)\n'
else
  printf '  (doom command not found)\n'
fi
printf '\n'
printf '**Source Git State:**\n'
printf '  HEAD: %s\n' "$(git log -1 --oneline --decorate)"
git status --short
printf '\n'
printf '**Skill Mirror:**\n'
if "$REPO_ROOT/scripts/check-doom-skill-mirror.sh" >/dev/null 2>&1; then
  printf '  in sync: %s\n' "$SKILL_DST"
elif [[ -e "$SKILL_DST" ]]; then
  printf '  DRIFT or invalid identity: %s\n' "$SKILL_DST"
else
  printf '  not installed: %s\n' "$SKILL_DST"
fi
printf '\n'
if [[ -n "$FILE" ]]; then
    printf '**File Being Edited:** %s\n' "$FILE"
    if [[ -f "$FILE" ]]; then
        printf '\n**File Content (first 80 lines):**\n'
        head -80 "$FILE"
    else
        printf '  (file does not exist yet)\n'
    fi
    printf '\n'
fi
printf '**Relevant Config Files:**\n'
for f in init.el config.el packages.el; do
    if [[ -f "$f" ]]; then
        printf '  %s (%s lines)\n' "$f" "$(wc -l < "$f")"
    fi
done
printf '\n'
printf '**Active init.el Declarations:**\n'
if [[ -f init.el ]]; then
    awk '
      /^[[:space:]]*;/ { next }
      /^[[:space:]]+[(]?[[:alnum:]+-]+/ {
        line = $0
        sub(/^[[:space:]]+/, "", line)
        print "  " line
      }
    ' init.el
else
    printf '  (init.el not found)\n'
fi
printf '\n'
printf '**Tool Availability:**\n'
for tool in git emacs python3 shellcheck prettier ruff; do
    if command -v "$tool" >/dev/null 2>&1; then
        printf '  %-12s %s\n' "$tool" "$(command -v "$tool")"
    else
        printf '  %-12s (not found)\n' "$tool"
    fi
done
printf '\n'
printf '**Recent Commits:**\n'
git log --oneline -5
printf '\n'
printf '=== End Context ===\n\n'
printf 'Copy the above and paste into your AI prompt, then add:\n'
printf '  - What you are trying to achieve\n'
printf '  - What you have already tried\n'
printf '  - Any error messages\n'
if [[ -z "$FILE" ]]; then
    printf '  - Add --include-file PATH only when sharing file content is appropriate\n'
fi
