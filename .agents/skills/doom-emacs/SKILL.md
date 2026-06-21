---
name: doom-emacs-config
description: Configure Doom Emacs correctly — module system, package management, safe patterns, and verification steps. Load before modifying any Doom config file.
metadata:
  version: "1.4.0"
  author: Code Sigils
  tier: powerful
  hermes:
    tags: [doom, emacs, emacs-lisp, config, elisp]
    related_skills: [emacs-lisp-expert]
    trigger_keywords:
      [
        doom,
        config.el,
        init.el,
        packages.el,
        emacs config,
        doom sync,
        doom doctor,
        doom upgrade,
        use-package,
        after!,
        config.sh,
        cross-platform grep,
      ]
---

# Doom Emacs Skill

A general guide for configuring and troubleshooting Doom Emacs. Load this
whenever touching files under `~/.config/doom/` or when the user asks about
Emacs config. This skill is meant to serve a new user — it teaches Doom
conventions, not just this repo's specific choices.

**Companion skill:** If `emacs-lisp-expert` is installed, load it too — it
covers Emacs Lisp fundamentals that this skill builds on. If it is not
installed, do not block: use this skill's Doom-specific guidance plus the
Emacs Lisp guide at `domains/ELISP.md` for non-trivial elisp. Suggest
installing `emacs-lisp-expert` once as an optional companion for deeper Emacs
Lisp work. This repo must remain self-contained for new users and agents.

**Critical:** Before making any change, read `~/.config/doom/AGENTS.md` if it
exists — it contains user-specific policies (completion preference, Markdown
style, verification steps, etc.).

## Quick Index

This skill is organised as a compact core (task-agnostic essentials) with
domain files for specific needs. Read only what your task needs:

| When your task is...               | Read this section or file                          |
| :--------------------------------- | :------------------------------------------------- |
| First time in this repo            | Agent Workflow, Writing Conventions, Safety Checks |
| Editing `init.el`                  | `domains/ARCHITECTURE.md`, Safety Checks           |
| Adding a module or package         | `domains/PROCEDURES.md` (A, B)                     |
| Setting a keybinding               | `domains/PROCEDURES.md` (E), Doom API Essentials   |
| Emacs won't start or something breaks | `domains/TROUBLESHOOTING.md`                   |
| Writing custom Elisp               | `domains/ELISP.md`, Pitfalls                       |
| Upgrading Doom framework           | `domains/PROCEDURES.md` (G), Safety Checks         |
| Maintaining config repo scripts    | Skill Script Conventions                           |

## Agent Workflow

Follow the workflow defined in `AGENTS.md` ("Agent Workflow" section). That
is the single source of truth for how agents should operate in this repo.

The key steps are:

1. Check `git status --short` before changing files.
2. Inspect the relevant file before patching; do not guess from memory.
3. Run `check-parens` on changed `.el` files before `doom sync`.
4. Run `doom sync` after requested edits (including config-only), unless told
   not to.
5. Run `doom doctor` after `doom sync`.
6. Finish with `git diff --check`, `git status --short`, concise summary.

See AGENTS.md for the full workflow with edge cases (failed commands, reference
consultation, skill mirror sync).

## File Roles — Know What Goes Where

Doom splits config across three files. Putting the wrong thing in the wrong file is the most common mistake.

| File          | Purpose                                                  | `doom sync` needed? |
| :------------ | :------------------------------------------------------- | :------------------ |
| `init.el`     | Declare which Doom modules are enabled, with their flags | Yes                 |
| `packages.el` | Install external packages (MELPA, git repos)             | Yes                 |
| `config.el`   | Settings, keybinds, hooks, advice, custom functions      | Depends on config   |

## Writing Conventions

Patterns that apply to any Doom config:

- Every `.el` file starts with `;;; <path> -*- lexical-binding: t; -*-`
- Use `after!` for deferred config — never `with-eval-after-load`
- Use `use-package!` for package configuration — never standard `use-package`
- Use `map!` for keybindings; `:leader` prefix for global bindings
- Use `fboundp` guards for optional package entrypoints (e.g. `(when (fboundp 'some-command) (some-command 1))`)
- Comment out unused modules in `init.el` — never delete lines
- Snippets live under `<doom-user-dir>/snippets/<major-mode>/`

## Doom API Essentials (Compact)

See `DOOM-API.md` for the full syntax and examples. These are the patterns agents most often get wrong — commit them to
memory:

- **`after!`** — defer config until a feature loads. Use instead of `with-eval-after-load`.
  `(after! org (setq org-adapt-indentation nil))`
- **`use-package!`** — Doom's package declaration + config. Not the same as `use-package` from MELPA.
  `(use-package! foo :defer t :config ...)`
- **`map!`** — keybinding with evil state-aware prefixes: `:leader` (`SPC`), `:n` (normal), `:i` (insert), `:v`
  (visual), `:m` (motion). `(map! :leader :desc "Desc" "f f" #'find-file)`
- **`set-company-backend!`** — per-mode company backend configuration
- **`add-hook!`** — multi-mode hook helper. `(add-hook! '(a-mode b-mode) #'fn)`
- **`setq-hook!`** — set buffer-local variables in a hook, cleaner than a lambda.
  `(setq-hook! 'org-mode-hook truncate-lines nil)`
- **`load!`** — load an Elisp file relative to `doom-user-dir`. `(load! "modules/org")` loads
  `~/.config/doom/modules/org.el`
- **`featurep!`** — compile-time module check. `(when (featurep! :ui popup) ...)`
- **`set-popup-rule!`** — control popup buffer display
- **`setq!`** — Doom's wrapper around `setq`. Use instead of `setq-default`.

## Safety Checks — Always Run After Changes

| After this              | Run this                                                                    |
| :---------------------- | :-------------------------------------------------------------------------- |
| Any requested Doom edit | `check-parens` for changed `.el` files, then `doom sync` unless told not to |
| `init.el` change        | `doom sync` (required after any module change)                              |
| `packages.el` change    | `doom sync` (required after any package change)                             |
| `config.el` change      | `M-x eval-buffer` or restart; `doom sync` works but check parens first      |
| Any `.el` file change   | `check-parens` to verify balanced parens                                    |
| After `doom sync`       | `doom doctor` — catches missing deps, wrong flags, broken recipes           |
| Emacs won't start (CLI) | `emacs --debug-init` for stack trace; `emacs --batch` for paren check       |

**Paren balancing is critical** — a missing paren in `config.el` can prevent Emacs from starting. Always verify before
declaring done.

**Run `doom doctor` after every `doom sync`** — it catches module flag mismatches, missing system dependencies, and
package recipe errors that would otherwise fail silently.

## Pitfalls

- **Do not edit `early-init.el` or `~/.emacs.d/init.el`** — Doom manages those. All user config goes in
  `~/.config/doom/`.
- **Do not use `with-eval-after-load`** — use Doom's `after!` macro instead.
- **Do not use standard `use-package`** — use Doom's `use-package!` (with trailing bang). They have different deferral
  semantics.
- **`(setq-default ...)`** is rarely needed in Doom. Prefer `(setq ...)`.
- **`straight.el` (not `package.el`)** is Doom's package manager. If a user runs `package-install`, it goes to the wrong
  place. Always use `package!` in `packages.el` followed by `doom sync`.
- **Never delete lines from `init.el`** — comment them out instead. Users rely on seeing the full module list to know
  what's available.
- **On‑save formatting** — if `format +onsave` is enabled, saving after `doom sync` can break indentation. Run
  `M-x doom/reload` after `doom sync`.
- **Stale template comments can mislead** — if restored upstream comments recommend `with-eval-after-load` or standard
  `use-package`, replace or annotate them to match your config's conventions.
- **Bind launcher keys outside `after!`** — putting a keybinding inside `(after! <pkg> ...)` delays the binding until
  the package loads. For commands meant to be run immediately, bind them directly and defer only the package
  configuration.

## Domain Drift Governance

The Quick Index table above is the single entry point to domain files. When a domain file is added, removed, renamed, or
its purpose changes, **update the Quick Index in the same change**:

- **Added domain** → add a row with file path, description, and trigger condition.
- **Removed domain** → remove its row from the Quick Index.
- **Renamed domain** → update the file path in its row.
- **Scope change** → update the description and trigger to match.
- Always verify the Reference Sources entry for `domains/` mentions every domain file. Stale pointers are blocking —
  agents discover depth files through this table, not by enumerating the filesystem.

## Scripts

All repo scripts live under `scripts/`. Sourcing `scripts/config.sh` provides shared variables and grep wrappers; the
other four are workflow tools you invoke directly:

| Script                       | Purpose                                                              | When to run                                |
| :--------------------------- | :------------------------------------------------------------------- | :----------------------------------------- |
| `sync-doom-skill-mirror.sh`  | Copy skill tree to Hermes runtime mirror                             | After editing skill or domain files        |
| `check-doom-skill-mirror.sh` | Verify mirror matches source                                         | After sync                                 |
| `check-stale-patterns.sh`    | Scan for dead Doom 3 flags + broken cross-refs                       | Before committing markdown changes         |
| `ai-context.sh`              | Generate AI prompt context block (version, git status, file content) | On demand when enlisting an external model |

## Skill Script Conventions

Scripts under `scripts/` source `scripts/config.sh` for shared variables:
`SKILL_SRC`, `SKILL_DST`, `DOOMDIR`, `REPO_ROOT`. Never duplicate paths.

Grep within scripts follows cross-platform conventions:
- Use `grep -E` (ERE), not `-P` (Perl) — not available on BSD/macOS.
- Use `grep -F` for fixed-string searches — faster, no accidental regex.
- Use literal backtick characters `` ` ``, never `\x60` hex escapes.
- Avoid BRE `\|`, `\?`, `\+` — use `grep -E` with unescaped `|`, `?`, `+`.
- Brackets for literal metacharacters: `[+]enable` not `\\+enable`.

Available via `config.sh` after sourcing:
- `grep_md <pattern>` — ERE grep over repo markdown, excluding `.git/`
- `extract_paths` — extracts backtick-quoted path refs from stdin
- `find_path_refs` — finds markdown files with path references
- `ensure_in_repo`, `confirm_skill_src`, `confirm_skill_dst`

## Keeping the Config Repo Self-Contained

This skill lives at `.agents/skills/doom-emacs/SKILL.md`. Anyone who clones
this repo gets the full skill with it. After editing the skill, sync the Hermes
runtime mirror:

```sh
scripts/sync-doom-skill-mirror.sh
scripts/check-doom-skill-mirror.sh
```

The sync uses destructive replacement (`rm -rf` then `cp -a`) to keep the
mirror byte-for-byte identical to the repo — no stale mirror-only files can
survive. See `AGENTS.md` for the two-clone protocol, source-destruction
invariant, and drift-detection steps.

## Reference Sources

When you need to understand how a package or Doom module works, the source code is at your fingertips:

- **Doom framework source:** `~/.config/emacs/` — clone of the
  [official Doom Emacs repo](https://github.com/doomemacs/doomemacs). Browse `modules/` for built-in module definitions,
  `lisp/` for core libraries, and `core/` for the module system.
- **Installed package source:** `~/.config/emacs/.local/straight/repos/` — each package has its own directory with full
  source.
- **Doom Emacs Issues & Docs:** upstream GitHub repository for recent changes, open issues, and pull requests.
- **This repo's references:**
  - `references/INDEX.md` — external resource catalogue (community configs, keybinding reference, performance tips)
  - `references/package-management.md` — package lifecycle, pinning, straight internals, recovery
  - `.agents/skills/doom-emacs/references/` — session notes and config-specific troubleshooting
  - `AGENTS.md` — user-specific policies, workflow, drift prevention
  - `domains/` — depth guides (architecture, procedures, elisp, troubleshooting)
