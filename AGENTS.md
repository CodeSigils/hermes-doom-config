# Doom Emacs Agent Instructions

## Cross-References (Files Agent Must Load)

| File                                 | Purpose                                                              |
| ------------------------------------ | -------------------------------------------------------------------- |
| `DOOM-API.md`                        | Idiomatic Doom patterns — which macros to use when and why           |
| `PROFILE.md`                         | Config profile — modules, packages, custom functions, environment    |
| `references/INDEX.md`                | Reference catalogue — Doom resources, community configs, exploration |
| `.agents/skills/doom-emacs/SKILL.md` | Full Doom skill with procedures, pitfalls, extended API reference    |
| `README.md`                          | Human quick-start (verify module lists against `init.el`)            |

`PROFILE.md` is the first file an agent should read when entering this repo
for the first time — it describes what this config is. `DOOM-API.md` teaches
the idiomatic Doom patterns. `references/INDEX.md` is the file to browse when
exploring what is possible. The Doom skill at
`.agents/skills/doom-emacs/SKILL.md` provides deeper API details and procedures.

If `emacs-lisp-expert` is available, load it for general Emacs Lisp guidance;
if missing, suggest it once as an optional companion, then continue without
blocking.

## Agent Workflow

- Work sequentially. Prefer one concern per edit and one concern per commit.
- Check `git status --short` before changing files.
- Inspect the relevant file before patching; do not guess from memory.
- When README.md lists modules or feature inventory, verify against `init.el`.
- For changed `.el` files, run `check-parens` before `doom sync`.
- Run `doom sync` after requested Doom config edits unless explicitly told not
  to, including config-only edits.
- Run `doom doctor` after `doom sync`.
- If the repo skill changes, run `scripts/sync-doom-skill-mirror.sh`, then
  `scripts/check-doom-skill-mirror.sh`. The Hermes runtime mirror at
  `~/.hermes/skills/emacs/doom-emacs-config/` is generated state; do not
  hand-edit it.
- When consulting `DOOM-API.md`, verify its patterns against official Doom
  sources (`~/.config/emacs/core/`, `~/.config/emacs/modules/`, `K` and `gd`
  lookups in `init.el`). If the file is wrong or outdated, propose a fix — it
  is a living document meant to stay current with Doom upstream.
- Finish with `git diff --check`, `git status --short`, and a concise summary.
- When consulting reference material (`references/INDEX.md`, community configs,
  Doom upstream), follow the "Learn, Don't Copy" pattern: understand the
  feature, evaluate compatibility against PROFILE.md policies, suggest to the
  user, and implement only on request. Never transplant external code without
  evaluation.
- When a command fails (`check-parens`, `doom sync`, `doom doctor`), stop and
  present the failure output. Do not proceed past a failed validation step
  without confirmation. See `README.md` for `doom rollback` and backup recovery
  procedures.

## Decision Thresholds

| Authority level | What the agent does | Examples |
| --------------- | ------------------- | -------- |
| Do automatically | Routine maintenance within documented patterns | Comment/uncomment modules in `init.el`, add `package!` to `packages.el`, add custom functions with `sand/` prefix, run `doom sync` + `doom doctor` |
| Propose (ask first) | Structural changes that affect behavior or files beyond the edit target | Create new top-level files, introduce new modules, change completion backend, override Doom's core macro usage, modify popup rules broadly |
| Never without explicit user request | Destructive or irreversible operations | `doom upgrade`, `doom rollback`, removing lines from `init.el` instead of commenting, editing generated state under `.agents/skills/`, running `chezmoi` operations |

When in doubt, propose and wait. The cost of asking is lower than the cost of
reverting.

## Completion Policy

- The preferred completion backend is Doom's `:completion company` module for
  the fuller Company experience: snippets, code completion, file-path
  completion, and mature completion backends.
- Company path completion is intentionally expanded in `config.el` with
  `company-files` via `set-company-backend!`; preserve that when editing
  completion behavior.
- Keep Corfu present as a commented `init.el` module line, but do not switch
  the completion system to Corfu/Cape (the `company-capf` backends in
  `config.el` are Company backends, not Corfu configuration -- leave them
  untouched).
- Do not remove lines from `init.el`; comment disabled modules/settings instead
  so the original Doom module list stays visible and recoverable.
- Do not run chezmoi sync/update actions for Doom work (`chezmoi add`,
  `chezmoi apply`, `chezmoi forget`, etc.) until the user explicitly says so.
- After changing `init.el` completion modules, `packages.el`, or requested
  config-only behavior, run `doom sync` unless explicitly told not to.

## Window Management Policy

- Do not advise low-level window primitives such as `window-split`.
- Prefer documented window/display controls: `split-window-preferred-function`,
  `display-buffer-alist`, Doom `set-popup-rule!`, explicit keybindings, and
  mode/package hooks.
- Preserve monitor-aware initial frame sizing through `sand/initial-frame-size`;
  do not replace it with a single fixed frame size unless explicitly requested.
- Prefer targeted popup rules for known transient buffers over broad catch-all
  star-buffer rules.

## Defensive Config Policy

- Use `fboundp` guards for optional package entrypoints when practical, such as
  `org-roam-db-autosync-mode`.
- Keep global defaults global. For example, `delete-by-moving-to-trash` belongs
  in the main defaults section and should not be duplicated inside package
  blocks unless a package needs a different value.

## Markdown Policy

- Do not use emoji in any Markdown file in this repository, including generated
  memory summaries, status labels, tables, and agent notes.
- Markdown files are auto-formatted on save via prettier (`--parser markdown`).
  This handles tables, list indentation, and fence consistency without touching
  prose content.
- Prettier is installed globally via `pnpm add -g prettier` at
  `~/.local/share/pnpm/bin/prettier` -- survives fnm Node migrations.

## Python Policy

- Ruff is the Python formatter and linter (not prettier -- prettier is for
  markdown only). Installed globally via `pnpm add -g ruff` at
  `~/.local/bin/ruff`.
- Format on save is configured in `config.el` via `(format +onsave)` with
  explicit `set-formatter! 'ruff` for Python buffers.
- Type checking is done via `mypy` (run in CI/terminal), not via LSP in the
  editor.

## Drift Prevention

When you change a source of truth, update its dependent files in the same
change:

| Source of truth | Dependent files | What to update |
| --------------- | --------------- | -------------- |
| `init.el` | `PROFILE.md` module table, `README.md` notable modules | Add/remove modules, adjust flags |
| `packages.el` | `PROFILE.md` packages table | Add/remove packages with purpose notes |
| `config.el` | `PROFILE.md` custom functions table, `DOOM-API.md` patterns | Update function signatures, add new patterns |
| `AGENTS.md` | `PROFILE.md` Config Policies Summary | Update policy one-liners if bounds change |
| `.agents/skills/` skill files | `AGENTS.md` workflow (sync-command references) | Update script paths if reorganized |

Run `git diff --check` before committing. Stale documentation is worse than
missing documentation because the agent cannot distinguish it from truth.
