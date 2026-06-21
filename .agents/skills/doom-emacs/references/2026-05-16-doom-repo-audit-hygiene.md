# Doom repo audit and hygiene notes — 2026-05-16

Session-specific detail for maintaining `~/.config/doom/` as both a working Doom config and a documented repo.

## Audit signals worth checking

- `README.md` module lists can drift from `init.el`. Treat `init.el` as source of truth for enabled/commented Doom
  modules.
- If README claims modules/features are enabled, verify each against the active `(doom! ...)` form before reporting the
  repo as accurate.
- `doom doctor` warnings should usually become either:
  - documented optional system dependencies, when the enabled module is intentional; or
  - disabled/commented modules, when the feature is not actually used.
- Runtime state such as SQLite DB/WAL/SHM files under repo-local tool directories is usually repo noise and may contain
  personal/session data.

## Concrete patterns from this audit

- README listed enabled modules that were actually commented in `init.el` (`nav-flash`, `treemacs`, `multiple-cursors`,
  `rotate-text`, `editorconfig`, `rest`, `web`, `mu4e`, `irc`, `rss`). Future audits should compare README claims
  directly to `init.el`.
- `.open-mem/memory.db`, `.open-mem/memory.db-wal`, and `.open-mem/memory.db-shm` were tracked. Prefer ignoring runtime
  DB artifacts; if durable memory is useful, export it to Markdown instead of committing SQLite files.
- Stale upstream Doom template comments can conflict with this repo's policy. In particular, comments recommending
  `with-eval-after-load` should be replaced or annotated so agents use `after!`.
- The snippet directory is substantial repo content. README should mention where snippets live and how they are
  organized when documenting the config.

## Recommended review checklist

1. Read `init.el` and derive the actual enabled module inventory.
2. Compare README feature/module claims against that inventory.
3. Check `git status --short` and tracked runtime artifacts (`git ls-files` is useful when available).
4. Run Markdown lint when README/AGENTS/docs change.
5. Run Elisp paren checks for changed `.el` files.
6. Run `doom doctor`; classify warnings as expected optional dependencies or config issues.

---

**Parent skill:** `SKILL.md` — compact core with file roles, API essentials, safety checks, pitfalls, and the Quick
Index for all domain files. 7. Check comments for stale upstream advice that contradicts repo policy
(`with-eval-after-load`, standard `use-package`, deleting module lines, etc.).
