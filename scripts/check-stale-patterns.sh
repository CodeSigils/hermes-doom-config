#!/usr/bin/env bash
# check-stale-patterns.sh
# Thin entry point for stale guidance, cross-reference, and script inventory
# validation. The Python implementation preserves paths containing spaces and
# checks the SKILL.md Scripts table in both directions.
#
# Usage: ./scripts/check-stale-patterns.sh
# Exit 0 = clean, 1 = stale content or broken refs found
set -euo pipefail
# shellcheck source=scripts/config.sh
. "$(dirname "$0")/config.sh"
ensure_in_repo
exec python3 "$REPO_ROOT/scripts/validate-docs.py"
