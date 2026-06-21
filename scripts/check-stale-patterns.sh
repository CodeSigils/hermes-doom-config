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
. "$(dirname "$0")/config.sh"
ensure_in_repo

errors=0

##################################################
# PASS 1: Stale pattern scan
##################################################

# Patterns use ERE syntax (compatible with grep -E).
# Fixed strings use -F for speed and safety.
stale_patterns=(
  "doom rollback:Removed in Doom 3 (stub only, does nothing)"
  "doom clean:Removed in Doom 3 (use doom gc)"
  "pinfile[.]el:No longer exists -- pins are declared via :pin in packages.el"
  "straight/versions/:Directory no longer exists in Doom 3"
  "setopt:Dodged migration -- Doom 3 kept setq! as the standard"
  "[+]babel:Not a valid :lang org flag in Doom 3"
)

printf '=== Stale Pattern Scan ===\n\n'

for entry in "${stale_patterns[@]}"; do
  pattern="${entry%%:*}"
  explanation="${entry#*:}"
  matches=$(grep_md "$pattern")
  if [[ -n "$matches" ]]; then
    printf 'STALE: %s\n' "$explanation"
    printf '%s\n' "$matches" | head -10
    match_count=$(printf '%s\n' "$matches" | wc -l)
    if [[ "$match_count" -gt 10 ]]; then
      printf '  ... and %d more matches\n' "$((match_count - 10))"
    fi
    printf '\n'
    errors=1
  fi
done

if [[ "$errors" -eq 0 ]]; then
  printf 'No stale patterns found.\n'
fi
printf '\n'

##################################################
# PASS 2: Cross-reference integrity
##################################################

printf '=== Cross-Reference Integrity ===\n\n'

ref_errors=0

check_path() {
  local path="$1"
  local source_file="$2"
  local source_line="$3"
  local resolved

  # Paths starting with . or ./ are repo-root relative; resolve as-is
  if [[ "$path" == .* ]]; then
    resolved="${path#./}"
  else
    # Relative paths: determine base directory from source file location
    local filedir
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
    resolved="${filedir}/${path}"
    resolved="${resolved#./}"
  fi

  if [[ -e "$resolved" ]]; then
    return 0
  fi

  # Fallback for references from within the skill directory: the file may
  # live at repo root instead of under the skill dir (e.g. references/INDEX.md,
  # DOOM-API.md, scripts/check-stale-patterns.sh).
  if [[ "$source_file" == ./.agents/skills/doom-emacs/* ]] && [[ -e "$path" ]]; then
    return 0
  fi

  printf "BROKEN: '%s' from %s:%s -- not found at '%s'\n" \
    "$path" "$source_file" "$source_line" "$resolved"
  ref_errors=1
}

while IFS=: read -r file line _rest; do
  content=$(sed -n "${line}p" "$file" 2>/dev/null || true)
  paths=$(printf '%s\n' "$content" | extract_paths)
  if [[ -z "$paths" ]]; then
    continue
  fi
  for path in $paths; do
    # Skip paths containing shell placeholders like [file] or <name>
    if [[ "$path" == *'['* ]] || [[ "$path" == *'<'* ]]; then
      continue
    fi
    check_path "$path" "$file" "$line"
  done
done < <(find_path_refs)

if [[ "$ref_errors" -eq 0 ]]; then
  printf 'All cross-references resolve.\n'
fi

##################################################
# PASS 3: Script inventory coverage
##################################################

printf '=== Script Inventory Coverage ===\n\n'

inv_errors=0
# scripts/config.sh is a support library, not invoked directly — exclude
for script in scripts/*.sh; do
  name=$(basename "$script")
  [[ "$name" == "config.sh" ]] && continue

  in_skill=$(grep -cF "$name" .agents/skills/doom-emacs/SKILL.md || true)

  if [[ "$in_skill" -eq 0 ]]; then
    printf 'MISSING: %s not referenced in SKILL.md Scripts table\n' "$name"
    inv_errors=1
  fi
done

if [[ "$inv_errors" -eq 0 ]]; then
  printf 'All scripts referenced in SKILL.md Scripts table.\n'
fi
printf '\n'

if [[ "$errors" -eq 1 ]] || [[ "$ref_errors" -eq 1 ]] || [[ "$inv_errors" -eq 1 ]]; then
  exit 1
fi
exit 0
