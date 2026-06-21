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

printf '=== Mirror replacement contracts ===\n'
test_home="$temp_root/home"
mkdir -p "$test_home"
HOME="$test_home" DOOMDIR="$fixture" bash "$fixture/scripts/sync-doom-skill-mirror.sh"
HOME="$test_home" DOOMDIR="$fixture" bash "$fixture/scripts/check-doom-skill-mirror.sh"

mirror="$test_home/.hermes/skills/emacs/doom-emacs-config"
printf 'stale\n' >"$mirror/stale-only.txt"
HOME="$test_home" DOOMDIR="$fixture" bash "$fixture/scripts/sync-doom-skill-mirror.sh"
[[ ! -e "$mirror/stale-only.txt" ]] || {
  printf 'FAIL: staged replacement retained a stale mirror-only file\n' >&2
  exit 1
}
printf 'OK: staged replacement removes stale mirror-only files\n'

foreign_home="$temp_root/foreign-home"
foreign_mirror="$foreign_home/.hermes/skills/emacs/doom-emacs-config"
mkdir -p "$foreign_mirror"
printf '%s\n' 'name: unrelated-skill' >"$foreign_mirror/SKILL.md"
printf 'preserve\n' >"$foreign_mirror/sentinel"
expect_failure "foreign destination identity is rejected" \
  env HOME="$foreign_home" DOOMDIR="$fixture" \
  bash "$fixture/scripts/sync-doom-skill-mirror.sh"
[[ -f "$foreign_mirror/sentinel" ]] || {
  printf 'FAIL: foreign destination was mutated\n' >&2
  exit 1
}

expect_failure "destination override is rejected" \
  env HOME="$test_home" DOOMDIR="$fixture" SKILL_DST="$temp_root/evil" \
  bash "$fixture/scripts/sync-doom-skill-mirror.sh"

symlink_home="$temp_root/symlink-home"
symlink_target="$temp_root/symlink-target"
mkdir -p "$symlink_home/.hermes/skills/emacs" "$symlink_target"
ln -s "$symlink_target" \
  "$symlink_home/.hermes/skills/emacs/doom-emacs-config"
expect_failure "symlink destination is rejected" \
  env HOME="$symlink_home" DOOMDIR="$fixture" \
  bash "$fixture/scripts/sync-doom-skill-mirror.sh"

expect_failure "source override outside the repository is rejected" \
  env HOME="$test_home" DOOMDIR="$fixture" SKILL_SRC="$mirror" \
  bash "$fixture/scripts/sync-doom-skill-mirror.sh"

fake_bin="$temp_root/fake-bin"
mkdir -p "$fake_bin"
printf '#!/usr/bin/env bash\nexit 1\n' >"$fake_bin/cp"
chmod +x "$fake_bin/cp"
printf 'preserve\n' >"$mirror/pre-failure"
expect_failure "copy failure leaves the prior mirror intact" \
  env HOME="$test_home" DOOMDIR="$fixture" PATH="$fake_bin:$PATH" \
  bash "$fixture/scripts/sync-doom-skill-mirror.sh"
[[ -f "$mirror/pre-failure" ]] || {
  printf 'FAIL: prior mirror was lost after staged copy failure\n' >&2
  exit 1
}

real_diff=$(command -v diff)
diff_bin="$temp_root/diff-bin"
diff_count="$temp_root/diff-count"
mkdir -p "$diff_bin"
cat >"$diff_bin/diff" <<EOF
#!/usr/bin/env bash
count=0
[[ -f "$diff_count" ]] && count=\$(cat "$diff_count")
count=\$((count + 1))
printf '%s\n' "\$count" >"$diff_count"
if [[ "\$count" -ge 2 ]]; then
  exit 1
fi
exec "$real_diff" "\$@"
EOF
chmod +x "$diff_bin/diff"
printf 'restore\n' >"$mirror/restore-after-validation"
expect_failure "post-swap validation failure restores the prior mirror" \
  env HOME="$test_home" DOOMDIR="$fixture" PATH="$diff_bin:$PATH" \
  bash "$fixture/scripts/sync-doom-skill-mirror.sh"
[[ -f "$mirror/restore-after-validation" ]] || {
  printf 'FAIL: prior mirror was not restored after validation failure\n' >&2
  exit 1
}

printf 'All offline contracts passed.\n'
