#!/usr/bin/env bash
# check-stale-patterns.sh
# Greps for known stale/dead patterns in markdown files.
# These are commands, flags, or paths that no longer exist in Doom 3
# but may be re-introduced through careless editing.
#
# Also checks cross-reference integrity — that file paths in backtick
# quotes actually exist relative to the file that references them.
#
# Usage: ./scripts/check-stale-patterns.sh
# Exit 0 = clean, 1 = stale content or broken refs found

set -euo pipefail

errors=0
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$REPO_ROOT"

##################################################
# PASS 1: Stale pattern scan
##################################################

stale_patterns=(
  "doom rollback:Removed in Doom 3 (stub only, does nothing)"
  "doom clean:Removed in Doom 3 (use doom gc)"
  "pinfile\\.el:No longer exists -- pins are declared via :pin in packages.el"
  "straight/versions/:Directory no longer exists in Doom 3"
  "setopt:Dodged migration -- Doom 3 kept setq! as the standard"
  "\\+babel:Not a valid :lang org flag in Doom 3"
)

echo "=== Stale Pattern Scan ==="
echo ""

for entry in "${stale_patterns[@]}"; do
  pattern="${entry%%:*}"
  explanation="${entry#*:}"
  matches=$(grep -rn "$pattern" --include='*.md' . | grep -v '.git/' || true)
  if [ -n "$matches" ]; then
    echo "STALE: $explanation"
    echo "$matches" | head -10
    # If more than 10 matches, show count
    match_count=$(echo "$matches" | wc -l)
    if [ "$match_count" -gt 10 ]; then
      echo "  ... and $((match_count - 10)) more matches"
    fi
    echo ""
    errors=1
  fi
done

if [ $errors -eq 0 ]; then
  echo "No stale patterns found."
fi
echo ""

##################################################
# PASS 2: Cross-reference integrity
##################################################

echo "=== Cross-Reference Integrity ==="
echo ""

ref_errors=0

check_path() {
  local path="$1"
  local source_file="$2"
  local source_line="$3"
  local filedir

  # Determine the base directory for resolution
  case "$source_file" in
    ./.agents/skills/doom-emacs/*)
      filedir=".agents/skills/doom-emacs"
      ;;
    ./.agents/*)
      filedir=".agents"
      ;;
    *)
      filedir="."
      ;;
  esac

  local resolved="${filedir}/${path}"
  # Normalize: remove leading ./ if any
  resolved="${resolved#./}"

  if [ -f "$resolved" ] || [ -d "$resolved" ]; then
    return 0
  fi
  # If SKILL.md references DOOM-API.md, it lives at repo root, not in skill dir
  if [[ "$filedir" == ".agents/skills/doom-emacs" ]] && [ -f "DOOM-API.md" ] && [[ "$resolved" == ".agents/skills/doom-emacs/DOOM-API.md" ]]; then
    return 0
  fi
  echo "BROKEN: '$path' from $source_file:$source_line -- not found at '$resolved'"
  ref_errors=1
}

while IFS=: read -r file line _rest; do
  content=$(sed -n "${line}p" "$file" 2>/dev/null || true)
  # Match backtick-quoted paths: references/... or scripts/... or ./.agents/...
  # But not URLs (http://), not email-like paths, not version strings
  paths=$(echo "$content" \
    | grep -oP '\x60(?:\x2e/)?(?:references/|scripts/|\.agents/)[^\x60]+\x60' \
    | tr -d '\x60' || true)
  if [ -z "$paths" ]; then
    continue
  fi
  for path in $paths; do
    # Known false positives to skip
    case "$path" in
      DOOM-API.md) continue ;;  # always at repo root
      references/DOOM-API.md) continue ;;
      *) check_path "$path" "$file" "$line" ;;
    esac
  done
done < <(grep -rn '\x60\(\./\)\?\(references/\|scripts/\|\.agents/\)' --include='*.md' . | grep -v '.git/' || true)

if [ $ref_errors -eq 0 ]; then
  echo "All cross-references resolve."
fi

if [ $errors -eq 1 ] || [ $ref_errors -eq 1 ]; then
  exit 1
fi
exit 0
