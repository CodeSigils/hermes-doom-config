# doom-emacs-config

My personal Doom Emacs configuration repo. Designed for org-mode, GTD workflows, and general development with Company
completion on a dual-monitor setup.

## Quick Start

Requires [Doom Emacs](https://github.com/doomemacs/doomemacs) installed.

```sh
git clone <remote-url> ~/.config/doom
doom sync
doom doctor
```

If you're an AI agent working in this repo, read `PROFILE.md` first (what this config is), then `DOOM-API.md` (idiomatic Doom patterns), then `AGENTS.md` (workflow and policies — also contains a [complete Reference Map](AGENTS.md#reference-map) of all documentation files).

This repo is also a Hermes agent skill. The `.agents/skills/doom-emacs/` directory contains the skill definition — clone and run `scripts/sync-doom-skill-mirror.sh` to make it loadable by agents. The repo's required Doom skill lives at `.agents/skills/doom-emacs/SKILL.md` — a compact core with `domains/ARCHITECTURE.md`, `domains/PROCEDURES.md`, `domains/ELISP.md`, and `domains/TROUBLESHOOTING.md` for depth on demand.

For consolidated best practices, see `references/best-practices.md`. If your Hermes installation also has `emacs-lisp-expert`, load it as an optional companion skill for general Emacs Lisp guidance. If it is missing, consider installing it for deeper Emacs Lisp help, but do not require it for basic repo maintenance.

For first-time local Hermes use by agents, install the repo skill into the runtime mirror:

```sh
scripts/sync-doom-skill-mirror.sh
scripts/check-doom-skill-mirror.sh
```

For the full agent workflow and configuration policies, see `AGENTS.md`.

## File Layout

| Path                         | Purpose                                                         |
| ---------------------------- | --------------------------------------------------------------- |
| `init.el`                    | Module declarations (single `doom!` form)                       |
| `packages.el`                | Package declarations (`package!` forms)                         |
| `config.el`                  | Thin loader with universal defaults and section `load!` calls   |
| `sections/appearance.el`     | Font, theme, line numbers                                       |
| `sections/spellcheck.el`     | Jinx spell-checking                                             |
| `sections/org.el`            | Org, Org-Roam, Org-Roam-UI                                      |
| `sections/completion.el`     | Company backends, dabbrev                                       |
| `sections/navigation.el`     | Browser, window management, popups, frame                       |
| `sections/ui.el`             | Dirvish, which-key, smartparens, rainbow-delimiters             |
| `sections/formatting.el`     | Ruff (Python), Prettier (Markdown)                              |
| `sections/keys.el`           | All keybindings (loaded last)                                   |
| `snippets/`                  | Yasnippet templates per major-mode                              |
| `scripts/`                   | Repo tooling (validation, mirror sync, CI)                      |
| `references/`                | Best-practices, package management, external resource catalogue |
| `.agents/skills/doom-emacs/` | Agent skill with domain files for depth                         |

Add new settings and hooks to the matching section file. Add new keybindings to
`sections/keys.el`. Register a new section file with `(load! ...)` in `config.el`.

```text
                    Config Edit Workflow

  ┌──────────┐   ┌──────────┐   ┌────────────┐   ┌──────────┐
  │ git stat │   │ check-   │   │ doom sync  │   │ doom     │
  │ +inspect │──>│ parens   │──>│ (if mods   │──>│ doctor   │
  │ +edit .el│   │          │   │  or pkgs)  │   │          │
  └──────────┘   └──────────┘   └────────────┘   └────┬─────┘
                                                      │
                                                      v
  ┌──────────────┐       ┌──────────┐     ┌────────────────┐
  │ stale        │       │ git diff │     │ commit with    │
  │ patterns     │──────>│ --check  │────>│ decision aware │
  │ + sync mirror│       │          │     │ message        │
  └──────────────┘       └──────────┘     └────────────────┘
```

## Agent Script Awareness

All repo scripts live under `scripts/`. The canonical reference for every script -- purpose, invocation, and when to run
-- is the Scripts table in `.agents/skills/doom-emacs/SKILL.md`.

```text
  AGENTS.md > workflow bullets     --  generic prose, no paths stored here
  AGENTS.md > Scripts section      --  points to SKILL.md table
  ───
  SKILL.md > Scripts table         --  single source of truth for all scripts
  ───
  scripts/check-stale-patterns.sh  --  delegates to validate-docs.py, which checks stale
                                       guidance, local references, script registration,
                                       domain inventory, and section inventory
```

- `AGENTS.md` workflow bullets reference scripts generically ("run the stale check") without storing concrete paths --
  nothing to drift if a script is renamed.
- `SKILL.md` is the single source for script metadata. Add or rename a script there, update the table.
- `check-stale-patterns.sh` enforces script-table coverage in both directions and preserves paths containing spaces.
- It also checks that every `sections/*.el` file is loaded from `config.el`, and every section loaded from `config.el`
  exists on disk.
- `scripts/config.sh` is a support library sourced by other scripts; it is never invoked directly and is excluded from
  the coverage check.

Run the network-free contracts before committing script changes:

```sh
scripts/run-offline-contracts.sh
```

CI follows the same boundaries: documentation/script checks run only for Markdown or script changes, shellcheck runs
only for shell changes, and the Emacs `check-parens` job runs only for changed `.el` files. Snippet-only changes do not
start the workflow.

## Notable Enabled Modules

See `PROFILE.md` for the full module table with flags by category, and `DOOM-API.md` section 3 for how the module system
works. `init.el` is the source of truth.

Not currently enabled: Doom's `mu4e`, `irc`, `rss`, `rest`, `web`, `treemacs`, `nav-flash`, `multiple-cursors`,
`rotate-text`, and `editorconfig` modules are commented out in `init.el`.

## Key Features

- **Company completion** with file path expansion — `company-files` added to `prog-mode`, `org-mode`, and
  `org-capture-mode`
- **Split config layout** — `config.el` is a thin loader with universal defaults; per-feature config lives under
  `sections/*.el`, and all keybindings live in `sections/keys.el`
- **Dirvish** — `SPC d d` launches `dirvish-dwim`
- **Jinx spell checking** — fast Enchant/Hunspell-backed spell checking for prose and code comments/strings
- **Org mode** — org-roam, org-roam-ui, org-tempo (`<s` Tab for src blocks), habit tracking, and GTD workflows
- **Popup targets** — targeted rules for help, apropos, warnings, backtraces, messages, completions, compilation/shell
  command output, and `*doom:*` buffers
- **Snippets** — Yasnippet snippets live under `snippets/<major-mode>/`; the TypeScript snippets inherit JavaScript
  snippets through `.yas-parents`
- **Defensive setup** — `fboundp` guards on optional packages, `delete-by-moving-to-trash` globally

## Optional System Dependencies

`doom doctor` reports missing optional tools for some enabled modules and workflows. Install only what you use.

| Tool or package                        | Used by                       | Notes                                        |
| :------------------------------------- | :---------------------------- | :------------------------------------------- |
| Symbola or equivalent Unicode font     | Doom font checks              | Optional fallback symbol font                |
| `ansible`                              | `:tools ansible`              | Needed for Ansible editing helpers           |
| `dockfmt`                              | `:tools docker`               | Formats Dockerfiles                          |
| Markdown compiler                      | Markdown preview/export       | Use the compiler expected by your Doom setup |
| `maim`, `scrot`, or `gnome-screenshot` | org-download clipboard images | Needed only for `org-download-clipboard`     |
| `pyflakes`                             | Python syntax checking        | Optional Python checker                      |
| `isort`                                | Python import sorting         | Optional formatter/import sorter             |
| `pipenv`                               | Python environments           | Only needed for Pipenv projects              |

## Maintenance

```sh
# Before upgrading Doom, back up your config
cp -a ~/.config/doom ~/.config/doom.backup.$(date +%Y%m%d)

doom upgrade
doom sync
doom doctor
```

If something breaks, restore `~/.config/doom.backup.*` from the backup.

## Notes

- Runtime SQLite artifacts under `.open-mem/` are ignored; keep durable notes in human-readable files instead of
  committing WAL/SHM database state
- The repo skill is canonical; after skill edits, sync the Hermes runtime mirror (see
  `.agents/skills/doom-emacs/SKILL.md` Scripts table). Treat the runtime mirror as generated state, not an editable
  source tree. Sync stages and validates a replacement before swapping it into place
- Markdown files in this repo should not contain emoji, including generated status summaries or agent notes
- Unused modules are commented out in `init.el`, never deleted
- Add new settings/hooks/advice to the appropriate `sections/*.el` file; add keybindings to `sections/keys.el`
