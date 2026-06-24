# Doom Emacs Agent Instructions

## Read First — Agent Entry Order

When opening this repo cold, read files in this order:

| Step | File | What it tells you | Why this order |
| :--- | :--- | :--- | :--- |
| 1 | `PROFILE.md` | What this config is — modules, packages, environment | Understand the setup before suggesting changes |
| 2 | `DOOM-API.md` | Idiomatic Doom patterns — which macros to use when | Learn the dialect before editing `.el` files |
| 3 | This file (`AGENTS.md`) | Agent behavior policies and workflow for this repo | Know the rules before making changes |
| 4 | `.agents/skills/doom-emacs/SKILL.md` | Compact core: file roles, API essentials, pitfalls; plus `domains/` for depth | Deep reference on demand |
| 5 | `references/INDEX.md` | External Doom resources and community configs | Find what's possible outside this config |

`README.md` is human-facing; read it when you need quick-start or dependency info. Beyond these 5 entry files, additional reference files exist in depth layers (`references/` and `.agents/skills/doom-emacs/domains/`). The Reference Map below is the full landscape.

## Source-First Reference Policy

The installed Doom source at `~/.config/emacs/` is the authoritative reference for this config — not upstream docs, not community configs. Before editing `config.el`, `sections/*.el`, `init.el`, or `packages.el`, consult the corresponding module source at `~/.config/emacs/modules/<cat>/<mod>/` to verify flags, patterns, and configuration options. External references supplement, never replace, the installed source.

**Agent config is config.** `.agents/` files (SKILL.md and domains/) govern how the agent operates in this repo. Include them in reviews, audits, and consistency checks alongside `init.el`, `config.el`, and `packages.el` — stale agent guidance compounds across sessions.

## Reference Map

Guide to every reference file in this repo, organized by depth tier. Read this at step 3 to see the full landscape before you need depth.

| Tier | File | Purpose |
| :--- | :--- | :--- |
| 1 — Root | `PROFILE.md` | Config profile — modules, packages, environment |
| 1 — Root | `DOOM-API.md` | Idiomatic Doom patterns |
| 1 — Root | `AGENTS.md` | Agent behavior, workflow, drift prevention |
| 1 — Root | `README.md` | Human quick-start |
| 2 — references/ | `INDEX.md` | External resources, community configs |
| 2 — references/ | `package-management.md` | Package lifecycle, pinning, straight |
| 2 — references/ | `best-practices.md` | Consolidated Doom config best practices |
| 2 — references/ | `yasnippets.md` | Snippet inventory, template syntax |
| 2 — references/ | `jinx.md` | Jinx spell-checking reference |
| 2 — references/ | `snippet-validation.md` | Parser-level snippet validation |
| 2 — references/ | `drift-prevention.md` | Source-to-dependent drift map |
| 3 — Skill entry | `.agents/skills/doom-emacs/SKILL.md` | Core: file roles, API essentials, pitfalls, domains index |
| 4 — domains/ | `domains/ARCHITECTURE.md` | Doom framework, module system, reload semantics |
| 4 — domains/ | `domains/ELISP.md` | Emacs Lisp for Doom config |
| 4 — domains/ | `domains/PROCEDURES.md` | Task procedures (add module, install package) |
| 4 — domains/ | `domains/TROUBLESHOOTING.md` | Diagnostic guide for Emacs failures |

Tier 1 is loaded in the entry order. Tier 2 is read on demand. Tier 3-4 is read when the SKILL.md Quick Index points to a domain file.

## Agent Workflow

- Work sequentially — one concern per edit, one concern per commit.
- Check `git status --short` before changing files. Inspect before patching.
- New settings/hooks/advice go in the matching `sections/*.el` file (register new sections with `(load! ...)` in `config.el`). All keybindings in `sections/keys.el`.
- Run `check-parens` on changed `.el` files before `doom sync`. Run `doom sync` after config edits, then `doom doctor`.
- When skill or domain files change: sync the Hermes runtime mirror before committing (`scripts/sync-doom-skill-mirror.sh`, then `scripts/check-doom-skill-mirror.sh`). The mirror is generated state — do not hand-edit it.
- Verify `DOOM-API.md` patterns against Doom source. If they conflict, propose a fix.
- When `DOOM-API.md` macro patterns change, audit `SKILL.md` Doom API Essentials and `domains/PROCEDURES.md` (sections C, D, E) for consistency.
- Cross-check `.agents/` files in every review and audit. After editing project config files, re-evaluate `.agents/` for stale examples, paths, and patterns. This is now automated (advisory check in validate-docs.py).
- The pre-commit hook runs `check-stale-patterns.sh` + `compileall` automatically. Before committing script changes, also run `scripts/run-offline-contracts.sh`.
- Follow "Learn, Don't Copy" — understand first, propose, implement only on request.
- On failure, stop and present output. Do not proceed past a failed step without confirmation.

All script names and invocation details live in `.agents/skills/doom-emacs/SKILL.md` (Scripts section). Do not store script paths in this file.

## Decision Thresholds

| Authority level | What the agent does | Examples |
| :--- | :--- | :--- |
| Do automatically | Routine maintenance within documented patterns | Comment/uncomment modules in `init.el`, add `package!` to `packages.el`, add `user/` functions, run `doom sync` + `doom doctor`, sync runtime mirror after skill edits |
| Propose (ask first) | Structural changes beyond the edit target | New top-level files, new modules, change completion backend, override Doom's core macros, modify popup rules broadly |
| Never without explicit request | Destructive or irreversible operations | `doom upgrade`, removing lines from `init.el` instead of commenting, hand-editing the runtime mirror |

When in doubt, propose and wait. The cost of asking is lower than the cost of reverting.

**Automation threshold:** Every automated check must earn its keep on damage prevented, not
abstract consistency. A gate that blocks commits only for cosmetic violations or hypothetical
mistakes that have never occurred is not worth the friction it introduces. When proposing a new
check, state what actual harm it prevents and whether that harm has occurred in this project.
This principle was established by removing an emoji detection check after it was written and
committed — it didn't survive the cost-of-omission test.

## Completion Policy

- Preferred backend: `:completion company +childframe +tng` for the fuller Company experience. Company path completion in `sections/completion.el` uses `company-files` via `set-company-backend!` — preserve that.
- Keep Corfu as a commented `init.el` module line. Do not switch to Corfu/Cape (the `company-capf` backends in `sections/completion.el` are Company backends, not Corfu config).
- Do not remove lines from `init.el`; comment disabled modules instead.
- Run `doom sync` after changing `init.el` completion modules, `packages.el`, or config-only behavior unless told not to.

## Defensive Config Policy

- Use `fboundp` guards for optional package entrypoints when practical (`org-roam-db-autosync-mode`).
- Keep global defaults global — do not duplicate `delete-by-moving-to-trash` inside package blocks unless a package needs a different value.

## Markdown Policy

- No emoji in any Markdown file in this repo, including generated memory summaries, tables, and agent notes.
- Prettier auto-formats on save (`--parser markdown`). Installed globally via pnpm at `~/.local/share/pnpm/bin/prettier`.
- Pipe-display pitfall is caught automatically: the pre-commit hook and CI run `pipe_artifact_findings()` which blocks commits with `||` at line start in markdown table rows.

## Python Policy

- Ruff is the Python formatter and linter (not prettier). Installed globally at `~/.local/bin/ruff`.
- Format on save via `(format +onsave)` with explicit `set-formatter! 'ruff` for Python buffers.
- Type checking via `mypy` (run in CI/terminal), not via LSP in the editor.
- **Sibling-script consistency** — when editing one script in `scripts/`, grep its constants,
  paths, and patterns across sibling `.py` and `.sh` files before concluding. Shared values
  (`ROOT`, `SKILL_ROOT`, etc.) belong in a `_*.py` library module imported by all.
- **`_`-prefix convention** — files starting with `_` (e.g. `_repo.py`, `_checks.py`) are
  library modules, not standalone entry points. They are excluded from the script inventory
  check and do not appear in the SKILL.md Scripts table.
- **Compile-all gate** — run `python3 -m compileall -q scripts/` after editing Python;
  catches syntax errors the linter misses. (Also runs automatically in the
  pre-commit hook.)

## Drift Prevention

When you change a source of truth, update its dependents in the same change. The full mapping is in `references/drift-prevention.md`. The automated checks (pre-commit hook and CI via validate-docs.py) enforce:
- No stale active guidance patterns
- All cross-references resolve
- Script/domain/section/snippet inventory is in sync
- Skill essentials cover all DOOM-API.md core macros
- No pipe-display artifacts in markdown
- SKILL.md YAML frontmatter is valid and parseable
- README.md disabled module claims match init.el
- PROFILE.md module counts match init.el per category
- Section files have non-empty purpose comments
- Snippet files have `# key:`/`# name:` and `# --` separator; tab-stops in order
| **Cross-commit drift** (advisory): warns when staged changes miss their drift targets
| **Agent cross-check** (advisory): reminds to re-evaluate `.agents/` when config files change
| **Compile-all** hook blocks commits with Python syntax errors

Run `git diff --check` before committing. Stale documentation is worse than missing — the agent cannot distinguish it from truth.

## Doom API Compliance

When editing or reviewing `.el` files, follow `DOOM-API.md` patterns. Doom macros (`setq!`, `use-package!`, `after!`, `map!`, `add-hook!`, etc.) are preferred over Emacs equivalents. If existing code uses the Emacs form, convert it as part of the edit.

## AI Context for Config Questions

When asking an AI about this config, include: Doom version (`doom version`), file being edited, what you're trying to achieve, what you've tried, and exact error text. Run `scripts/ai-context.sh` to auto-generate this block.

The `doom` binary lives at `~/.config/emacs/bin/doom`. If commands fail with "command not found," use the full path or add the bin directory to `$PATH`.
