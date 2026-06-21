# Doom Emacs Agent Instructions

## Cross-References (Files Agent Must Load)

| File                                 | Purpose                                                                       |
| ------------------------------------ | ----------------------------------------------------------------------------- |
| `DOOM-API.md`                        | Idiomatic Doom patterns — which macros to use when and why                    |
| `PROFILE.md`                         | Config profile — modules, packages, custom functions, environment             |
| `references/INDEX.md`                | Reference catalogue — Doom resources, community configs, exploration          |
| `.agents/skills/doom-emacs/SKILL.md` | Compact core: file roles, API essentials, pitfalls; plus `domains/` for depth |
| `README.md`                          | Human quick-start (verify module lists against `init.el`)                     |

## Read First — Agent Entry Order

When opening this repo cold, read files in this order:

| Step | File                                 | What it tells you                                                             | Why this order                                 |
| :--- | :----------------------------------- | :---------------------------------------------------------------------------- | :--------------------------------------------- |
| 1    | `PROFILE.md`                         | What this config is — modules, packages, environment                          | Understand the setup before suggesting changes |
| 2    | `DOOM-API.md`                        | Idiomatic Doom patterns — which macros to use when                            | Learn the dialect before editing `.el` files   |
| 3    | This file (`AGENTS.md`)              | Agent behavior policies and workflow for this repo                            | Know the rules before making changes           |
| 4    | `references/INDEX.md`                | External Doom resources and community configs                                 | Find what's possible outside this config       |
| 5    | `.agents/skills/doom-emacs/SKILL.md` | Compact core: file roles, API essentials, pitfalls; plus `domains/` for depth | Deep reference on demand                       |

`README.md` is human-facing; read it when you need quick-start or dependency info.

## Source-First Reference Policy

The installed Doom source at `~/.config/emacs/` is the authoritative reference for this config — not upstream docs, not
community configs. Before editing `config.el`, `init.el`, or `packages.el`, consult the corresponding module source at
`~/.config/emacs/modules/<cat>/<mod>/` to verify flags, patterns, and configuration options. When the user asks about a
package, flag, or feature, answer from the module source (README.org for flags, config.el for implementation patterns,
lisp/ for core macros). External references supplement, never replace, the installed source.

If `emacs-lisp-expert` is available, load it for general Emacs Lisp guidance; if missing, suggest it once as an optional
companion, then continue without blocking.

## Agent Workflow

- Work sequentially. One concern per edit, one concern per commit.
- Check `git status --short` before changing files.
- Inspect the relevant file before patching; do not guess from memory.
- Verify `README.md` module inventory against `init.el`.
- For changed `.el` files, run `check-parens` before `doom sync`.
- Run `doom sync` after config edits unless told not to.
- Run `doom doctor` after `doom sync`.
- When the skill changes, sync the Hermes runtime mirror (see [Scripts](#scripts) table). It is generated state; do not
  hand-edit it.
- Verify `DOOM-API.md` patterns against Doom source (`~/.config/emacs/`). If wrong, propose a fix.
- Before every commit, run the stale-patterns check (see [Scripts](#scripts) table).
- Before committing script changes, run the network-free contracts (see [Scripts](#scripts) table).
- When consulting references, follow "Learn, Don't Copy" — understand first, propose, implement only on request.
- On failure, stop and present output. Do not proceed past a failed step without confirmation.

All script names and invocation details live in `.agents/skills/doom-emacs/SKILL.md` (Scripts section, linked above). Do
not store script paths in this file.

## Scripts

The canonical reference for all repo scripts — purpose, invocation, and when to run — is
`.agents/skills/doom-emacs/SKILL.md` (Scripts section).

The Hermes runtime mirror at `~/.hermes/skills/emacs/doom-emacs-config/` is generated state — do not hand-edit it.
`sync-doom-skill-mirror.sh` stages and validates a complete replacement before swapping it into place; stale
mirror-only files cannot survive, and the previous mirror is restored if replacement fails. The invariant is:

```text
~/.hermes/skills/emacs/doom-emacs-config/ == ~/.config/doom/.agents/skills/doom-emacs/
```

## Decision Thresholds

| Authority level                     | What the agent does                                                     | Examples                                                                                                                                           |
| ----------------------------------- | ----------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| Do automatically                    | Routine maintenance within documented patterns                          | Comment/uncomment modules in `init.el`, add `package!` to `packages.el`, add custom functions with `sand/` prefix, run `doom sync` + `doom doctor` |
| Propose (ask first)                 | Structural changes that affect behavior or files beyond the edit target | Create new top-level files, introduce new modules, change completion backend, override Doom's core macro usage, modify popup rules broadly         |
| Never without explicit user request | Destructive or irreversible operations                                  | `doom upgrade`, removing lines from `init.el` instead of commenting, hand-editing the generated runtime mirror under `~/.hermes/skills/`           |

When in doubt, propose and wait. The cost of asking is lower than the cost of reverting.

## Completion Policy

- The preferred completion backend is Doom's `:completion company` module for the fuller Company experience: snippets,
  code completion, file-path completion, and mature completion backends.
- Company path completion is intentionally expanded in `config.el` with `company-files` via `set-company-backend!`;
  preserve that when editing completion behavior.
- Keep Corfu present as a commented `init.el` module line, but do not switch the completion system to Corfu/Cape (the
  `company-capf` backends in `config.el` are Company backends, not Corfu configuration -- leave them untouched).
- Do not remove lines from `init.el`; comment disabled modules/settings instead so the original Doom module list stays
  visible and recoverable.
- After changing `init.el` completion modules, `packages.el`, or requested config-only behavior, run `doom sync` unless
  explicitly told not to.

## Defensive Config Policy

- Use `fboundp` guards for optional package entrypoints when practical, such as `org-roam-db-autosync-mode`.
- Keep global defaults global. For example, `delete-by-moving-to-trash` belongs in the main defaults section and should
  not be duplicated inside package blocks unless a package needs a different value.

## Markdown Policy

- Do not use emoji in any Markdown file in this repository, including generated memory summaries, status labels, tables,
  and agent notes.
- Markdown files are auto-formatted on save via prettier (`--parser markdown`). This handles tables, list indentation,
  and fence consistency without touching prose content.
- Prettier is installed globally via `pnpm add -g prettier` at `~/.local/share/pnpm/bin/prettier` -- survives fnm Node
  migrations.

## Python Policy

- Ruff is the Python formatter and linter (not prettier -- prettier is for markdown only). Installed globally via
  `pnpm add -g ruff` at `~/.local/bin/ruff`.
- Format on save is configured in `config.el` via `(format +onsave)` with explicit `set-formatter! 'ruff` for Python
  buffers.
- Type checking is done via `mypy` (run in CI/terminal), not via LSP in the editor.

## Drift Prevention

When you change a source of truth, update its dependent files in the same change:

| Source of truth                       | Dependent files                                                       | What to update                                           |
| ------------------------------------- | --------------------------------------------------------------------- | -------------------------------------------------------- |
| `init.el`                             | `PROFILE.md` module table, `README.md` notable modules                | Add/remove modules, adjust flags                         |
| `packages.el`                         | `PROFILE.md` packages table                                           | Add/remove packages with purpose notes                   |
| `config.el`                           | `PROFILE.md` custom functions table, `DOOM-API.md` patterns           | Update function signatures, add new patterns             |
| `AGENTS.md`                           | `PROFILE.md` Config Policies Summary, `README.md` agent entry section | Update reading order, companion skill mentions           |
| `scripts/` files                      | `SKILL.md` Scripts table, `AGENTS.md` workflow, CI routing            | Register scripts, update generic workflow and path gates |
| `.github/workflows/ci.yml`            | `README.md` maintenance guidance, script contracts                    | Keep path routing aligned with invoked checks            |
| `SKILL.md` Scripts table              | `README.md` Agent Script Awareness section                            | Update diagram, path descriptions                        |
| `domains/` files                      | `SKILL.md` Quick Index table                                          | Add/remove/rename rows to match domain files             |
| Doom module source (README.org)       | `references/INDEX.md` flags/features tables                           | Flag changes, new module features                        |
| Doom CLI (`~/.config/emacs/bin/doom`) | `references/package-management.md`                                    | Command changes, new subcommands                         |

Run `git diff --check` before committing. Stale documentation is worse than missing documentation because the agent
cannot distinguish it from truth.

## Doom API Compliance

When editing or reviewing `.el` files, ensure they follow `DOOM-API.md` patterns. Doom's macros (`setq!`,
`use-package!`, `after!`, `map!`, `add-hook!`, etc.) are preferred over their Emacs equivalents. If existing code uses
the Emacs form, convert it as part of the edit.

## AI Context for Config Questions

When asking an AI (or another agent) about this Doom config, provide context to get accurate, verifiable answers:

**Minimum context to include:**

- Doom version: `doom version` output
- File being edited: `config.el`, `init.el`, or `packages.el`
- What you're trying to achieve
- What you've already tried
- Any error messages (exact text)

**Helper script:** Run the AI context helper script (see [Scripts](#scripts) table) to auto-generate this context block.

**Note on doom CLI:** The `doom` binary lives at `~/.config/emacs/bin/doom`. If `doom doctor` or other `doom` commands fail
with "command not found," use the full path or ensure the bin directory is on `$PATH`:
`export PATH="$HOME/.config/emacs/bin:$PATH"`.

**Why this works:** AI agents have no persistent memory of your config. The context window is limited and
position-biased — see `agent-concepts-study` memory surfaces note. Explicit context eliminates guessing.
