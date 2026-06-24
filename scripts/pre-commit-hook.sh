#!/usr/bin/env bash
# pre-commit-hook.sh: Canonical copy of the pre-commit hook.
# Source of truth; install to .git/hooks/pre-commit via scripts/install-hooks.sh.
# Usage: git calls this automatically on commit; run it directly for a dry check.
set -euo pipefail

# Where to report violations -- use stderr so regular commit messages remain
# visible and git plumbing is unaffected.
exec 1>&2

# -------- stale-patterns check (always run) --------

if ! bash scripts/check-stale-patterns.sh; then
    printf '\nBLOCKING: documentation or script validation failed. Fix before committing.\n'
    exit 1
fi

# -------- Python compile-all (always run) --------

if ! python3 -m compileall -q scripts/ 2>/dev/null; then
    printf '\nBLOCKING: Python syntax error in scripts/. Fix before committing.\n'
    exit 1
fi

# -------- helpers --------

# Return staged .el files (added, copied, modified, renamed).
el_files_staged() {
    git diff --cached --name-only --diff-filter=ACMR -- ':*.el' | sort -u
}

# check <pattern> <message> <files>
# Grep each file for <pattern>.  Print <message> for every match.
# Returns 1 if any file matched, 0 if none did.
check() {
    local pattern="$1" msg="$2"
    shift 2
    local rc=0 file
    for file in "$@"; do
        # grep -n with no match exits 1 (valid) or >1 (error)
        if grep -nF "$pattern" "$file" 2>/dev/null; then
            printf '  >> %s: %s\n\n' "$file" "$msg"
            rc=1
        fi
    done
    return "$rc"
}

# check_no_match <pattern> <message> <file>
# Require <pattern> to exist in <file>.  Returns 1 (blocking) when missing.
check_no_match() {
    local pattern="$1" msg="$2" file="$3"
    local hit
    hit=$(grep -nF "$pattern" "$file" 2>/dev/null || true)
    if [ -z "$hit" ]; then
        printf '  >> %s: %s\n' "$file" "$msg"
        return 1
    fi
    return 0
}

# -------- main --------

# Early exit when nothing to check
mapfile -t FILES < <(el_files_staged)
if [ ${#FILES[@]} -eq 0 ]; then
    exit 0
fi

BLOCKED=0

printf '== Doom config best-practices check (%d .el file(s)) ==\n' "${#FILES[@]}"

# --- Blocking violations (must-fix) ---
# check returns 1 when a violation is found; || BLOCKED=1 handles it.

check 'with-eval-after-load' \
    'Use (after! ...) instead of with-eval-after-load (best-practices.md §1)' \
    "${FILES[@]}" || BLOCKED=1

check "featurep!" \
    'featurep! is deprecated; use (modulep! ...) instead (best-practices.md §1)' \
    "${FILES[@]}" || BLOCKED=1

check '(setq-default ' \
    'Use setq! instead of setq-default (best-practices.md §1)' \
    "${FILES[@]}" || BLOCKED=1

check '(define-key ' \
    'Use (map! ...) instead of define-key (best-practices.md §1, §6)' \
    "${FILES[@]}" || BLOCKED=1

check '(advice-add ' \
    'Use (defadvice! ...) instead of defun + advice-add (best-practices.md §1)' \
    "${FILES[@]}" || BLOCKED=1

# Lexical-binding cookie: every .el file must have -*- lexical-binding: t; -*-
for file in "${FILES[@]}"; do
    if ! check_no_match 'lexical-binding: t' \
        'Missing lexical-binding cookie (best-practices.md §3)' \
        "$file"; then
        BLOCKED=1
    fi
done

# --- Non-blocking warnings (review items) ---

check '(setq ' \
    'WARNING: bare (setq ...) found. Should this be (setq! ...)? (best-practices.md §1)' \
    "${FILES[@]}" || true

check '(require' \
    'WARNING: top-level (require ...) found. Should this be inside (after! ...)? (best-practices.md §4)' \
    "${FILES[@]}" || true

check '(lambda' \
    'WARNING: lambda found. Should this be a named function with user/ prefix? (best-practices.md §4)' \
    "${FILES[@]}" || true

# -------- exit --------

if [ "$BLOCKED" -ne 0 ]; then
    printf '\nBLOCKING violations found. Fix them or bypass with git commit --no-verify.\n'
    exit 1
fi

printf 'OK\n'
exit 0
