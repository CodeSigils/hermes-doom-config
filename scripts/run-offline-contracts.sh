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
printf 'test\n' >"$fixture/references/space file.md"
printf '\nSee [present](<references/space file.md>) and [encoded](references/space%%20file.md).\n' >>"$fixture/README.md"
(cd "$fixture" && bash scripts/check-stale-patterns.sh >/dev/null)
sed -i '$d' "$fixture/README.md"
printf '\nSee [missing](<references/missing file.md>).\n' >>"$fixture/README.md"
expect_failure "missing angle-bracketed path is rejected" \
  bash -c "cd '$fixture' && bash scripts/check-stale-patterns.sh"
grep -F 'references/missing file.md' "$temp_root/output" >/dev/null

sed -i '$d' "$fixture/README.md"
# Bounded non-goals: anchors, external URLs, and external mailto are ignored;
# local file targets with fragments resolve by file path.
printf '\n[anchor](#local-section) [external](https://example.com/path) [mail](mailto:test@example.com) [fragmented](<references/space file.md#heading>)\n' >>"$fixture/README.md"
(cd "$fixture" && bash scripts/check-stale-patterns.sh >/dev/null)
sed -i '$d' "$fixture/README.md"
# Local image/link targets are still checked when present.
printf '\n![missing image](references/missing-image.png)\n' >>"$fixture/README.md"
expect_failure "missing local image path is rejected" \
  bash -c "cd '$fixture' && bash scripts/check-stale-patterns.sh"
grep -F 'references/missing-image.png' "$temp_root/output" >/dev/null
sed -i '$d' "$fixture/README.md"

printf '\nSee [wrong relative target](README.md).\n' >>"$fixture/references/jinx.md"
expect_failure "nested Markdown link does not resolve against repository root" \
  bash -c "cd '$fixture' && bash scripts/check-stale-patterns.sh"
grep -F 'references/jinx.md:' "$temp_root/output" >/dev/null
sed -i '$d' "$fixture/references/jinx.md"

printf '=== Script inventory contract ===\n'
printf '#!/usr/bin/env bash\n' >"$fixture/scripts/unregistered-example.sh"
expect_failure "unregistered script is rejected" \
  bash -c "cd '$fixture' && bash scripts/check-stale-patterns.sh"
rm -f "$fixture/scripts/unregistered-example.sh"

printf '=== Skill identity contract ===\n'
sed -i 's/^name: doom-emacs$/name: wrong-name/' "$fixture/.agents/skills/doom-emacs/SKILL.md"
expect_failure "skill name must match its directory" \
  bash -c "cd '$fixture' && bash scripts/check-stale-patterns.sh"
grep -F 'SKILL.md name does not match its directory' "$temp_root/output" >/dev/null


printf 'All offline contracts passed.\n'
