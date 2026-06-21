#!/usr/bin/env bash
# ai-context.sh — Gather context for asking AI about Doom Emacs config
# Usage: ./scripts/ai-context.sh [optional: path to file being edited]
set -euo pipefail
. "$(dirname "$0")/config.sh"

cd "$DOOMDIR"
FILE="${1:-}"

printf '=== Doom Emacs Config Context ===\n\n'
printf '**Doom Version:**\n'
doom version 2>/dev/null || printf '  (doom command not found)\n'
printf '\n'
printf '**Git Status:**\n'
git status --short
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
printf '**Recent Commits:**\n'
git log --oneline -5
printf '\n'
printf '=== End Context ===\n\n'
printf 'Copy the above and paste into your AI prompt, then add:\n'
printf '  - What you are trying to achieve\n'
printf '  - What you have already tried\n'
printf '  - Any error messages\n'
