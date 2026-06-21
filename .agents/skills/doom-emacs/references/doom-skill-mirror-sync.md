# Doom Skill Mirror Sync

## Context

The Doom config repo carries the canonical project skill at:

```text
~/.config/doom/.agents/skills/doom-emacs/
```

Hermes auto-loads the runtime mirror from:

```text
~/.hermes/skills/emacs/doom-emacs-config/
```

This mirror is generated state, not an independently edited source tree.

## Durable Lesson

A vague instruction such as "copy the repo skill to the mirror" is too easy to forget and too easy to implement as an
additive copy. Additive copies allow stale mirror-only files to survive, which makes future agents load knowledge that
is not present in the repo.

The invariant should be stronger:

```text
runtime mirror == exact generated copy of repo skill
```

## Recommended Sync Pattern

Use destructive replacement of the mirror followed by a recursive diff:

```sh
SRC="$HOME/.config/doom/.agents/skills/doom-emacs"
DST="$HOME/.hermes/skills/emacs/doom-emacs-config"

test -f "$SRC/SKILL.md"
rm -rf "$DST"
mkdir -p "$(dirname "$DST")"
cp -a "$SRC" "$DST"
diff -qr "$SRC" "$DST"
```

Why this shape:

- removes stale mirror-only files
- copies all references and support files
- keeps repo as the only canonical source
- fails loudly when the mirror is not byte-for-byte equivalent

## Suggested Repo Scripts

For repeatability, add small scripts to the Doom config repo:

```text
scripts/sync-doom-skill-mirror.sh
scripts/check-doom-skill-mirror.sh
```

The sync script should perform the destructive replace above. The check script should run only:

```sh
diff -qr "$HOME/.config/doom/.agents/skills/doom-emacs" \
  "$HOME/.hermes/skills/emacs/doom-emacs-config"
```

## Workflow Rule

When any file under `.agents/skills/doom-emacs/` changes:

1. Run the sync script before reporting done.
2. Run the check script and require no diff.
3. Do not manually edit the runtime mirror.

---

**Parent skill:** `SKILL.md` — compact core with file roles, API essentials, safety checks, pitfalls, and the Quick
Index for all domain files. 4. If a mirror-only reference file looks valuable, copy it into the repo source first, then
sync from repo to mirror.
