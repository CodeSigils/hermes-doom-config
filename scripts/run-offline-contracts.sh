#!/usr/bin/env bash
# Deterministic, network-free contracts for repository scripts and documentation.

set -euo pipefail
# shellcheck source=scripts/config.sh
. "$(dirname "$0")/config.sh"
ensure_in_repo

temp_root=$(mktemp -d)
trap 'rm -rf "$temp_root"' EXIT
fixture="$temp_root/repo"
mkdir -p "$fixture"
tar --exclude=.git --exclude=.open-mem -cf - . | tar -xf - -C "$fixture"
git -C "$fixture" init -q
git -C "$fixture" add .

printf '=== Python compilation ===\n'
python3 -m compileall -q "$fixture/scripts"

expect_failure() {
  local label="$1"
  shift
  if "$@" >"$temp_root/output" 2>&1; then
    printf 'FAIL: %s unexpectedly succeeded\n' "$label" >&2
    return 1
  fi
  printf 'OK: %s\n' "$label"
}

printf '=== Baseline documentation contracts ===\n'
(cd "$fixture" && bash scripts/check-stale-patterns.sh)

printf '=== Stale-guidance suppression contract ===\n'
# shellcheck disable=SC2016 # Deliberate literal backticks in Markdown fixtures.
printf '%s\n' \
  '' \
  'Historical example: `doom clean` <!-- stale-check: allow -->' \
  >>"$fixture/README.md"
(cd "$fixture" && bash scripts/check-stale-patterns.sh >/dev/null)
# shellcheck disable=SC2016 # Deliberate literal backticks in Markdown fixtures.
printf '%s\n' 'Active example: `doom clean`' >>"$fixture/README.md"
expect_failure "active stale guidance is rejected" \
  bash -c "cd '$fixture' && bash scripts/check-stale-patterns.sh"

printf '=== Cross-reference contract ===\n'
sed -i '$d' "$fixture/README.md"
printf '\nSee [missing](references/does not exist.md).\n' >>"$fixture/README.md"
expect_failure "broken path containing spaces is rejected" \
  bash -c "cd '$fixture' && bash scripts/check-stale-patterns.sh"

printf '=== Script inventory contract ===\n'
sed -i '$d' "$fixture/README.md"
printf '#!/usr/bin/env bash\n' >"$fixture/scripts/unregistered-example.sh"
expect_failure "unregistered script is rejected" \
  bash -c "cd '$fixture' && bash scripts/check-stale-patterns.sh"
rm -f "$fixture/scripts/unregistered-example.sh"



printf 'All offline contracts passed.\n'
