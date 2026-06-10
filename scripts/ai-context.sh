#!/usr/bin/env bash
# ai-context.sh — Gather context for asking AI about Doom Emacs config
# Usage: ./scripts/ai-context.sh [optional: path to file being edited]

set -euo pipefail

DOOMDIR="${DOOMDIR:-$HOME/.config/doom}"
cd "$DOOMDIR"

FILE="${1:-}"

echo "=== Doom Emacs Config Context ==="
echo
echo "**Doom Version:**"
doom version 2>/dev/null || echo "  (doom command not found)"
echo
echo "**Git Status:**"
git status --short
echo
if [[ -n "$FILE" ]]; then
    echo "**File Being Edited:** $FILE"
    if [[ -f "$FILE" ]]; then
        echo
        echo "**File Content (first 80 lines):**"
        head -80 "$FILE"
    else
        echo "  (file does not exist yet)"
    fi
    echo
fi
echo "**Relevant Config Files:**"
for f in init.el config.el packages.el; do
    if [[ -f "$f" ]]; then
        echo "  $f ($(wc -l < "$f") lines)"
    fi
done
echo
echo "**Recent Commits:**"
git log --oneline -5
echo
echo "=== End Context ==="
echo
echo "Copy the above and paste into your AI prompt, then add:"
echo "  - What you're trying to achieve"
echo "  - What you've already tried"
echo "  - Any error messages"