---
name: doom-emacs-config
description: Configure Doom Emacs correctly — module system, package management, safe patterns, and verification steps. Load before modifying any Doom config file.
metadata:
  version: "1.2.1"
  author: Code Sigils
  tier: powerful
  hermes:
    tags: [doom, emacs, emacs-lisp, config, elisp]
    related_skills: [emacs-lisp-expert]
    trigger_keywords: [doom, config.el, init.el, packages.el, emacs config, doom sync, doom doctor, doom upgrade, use-package, after!]
---

# Doom Emacs Config

Skill for correctly modifying a Doom Emacs configuration. Load this whenever
touching files under `~/.config/doom/` or when the user asks about Emacs config.

**Companion skill:** If `emacs-lisp-expert` is installed, load it too — it
covers Emacs Lisp fundamentals that this skill builds on. If it is not
installed, do not block: use this skill's Doom-specific guidance plus the
fallback Emacs Lisp checklist below. When working with a user who does not have
it installed, briefly suggest installing `emacs-lisp-expert` as an optional
companion for deeper Emacs Lisp work. This repo must remain self-contained for
new users and agents.

**Critical:** Before making any change, read `~/.config/doom/AGENTS.md` if it
exists — it contains user-specific policies (completion preference, window
management rules, Markdown style, verification steps, etc.).

## AI Agent Operating Loop

Agents should work sequentially and make the smallest safe change that solves
the user's request. Prefer one concern per edit and one concern per commit.

1. Load this skill before editing files under `~/.config/doom/`.
2. Read `~/.config/doom/AGENTS.md` for repo-specific policy.
3. Check `git status --short` before changing files.
4. Inspect the relevant file before patching; do not guess from memory.
5. Edit one concern at a time.
6. For changed `.el` files, run `check-parens` before `doom sync`.
7. Run `doom sync` after requested Doom config edits unless the user says not to.
8. Run `doom doctor` after `doom sync`.
9. If Markdown changed, run the repo Markdown linter before reporting done.
10. If this skill changed, copy the repo skill to the Hermes runtime mirror with
    `cp` from repo to `~/.hermes`; do not hand-edit the mirror.
11. Finish with `git diff --check`, `git status --short`, and a concise summary.

## File Roles — Know What Goes Where

Doom splits config across three files. Putting the wrong thing in the wrong
file is the most common mistake.

| File          | Purpose                                                  | `doom sync` needed?                |
| :------------ | :------------------------------------------------------- | :--------------------------------- |
| `init.el`     | Declare which Doom modules are enabled, with their flags | Yes                                |
| `packages.el` | Install external packages (MELPA, git repos)             | Yes                                |
| `config.el`   | Settings, keybinds, hooks, advice, custom functions      | Normally no; this repo prefers yes |

## Writing Conventions

Patterns established in this config that must be followed when adding new code:

- Every `.el` file starts with `;;; <path> -*- lexical-binding: t; -*-`
- Use `after!` for deferred config — never `with-eval-after-load`
- Use `use-package!` for package configuration — never standard `use-package`
- Use `map!` for keybindings; `:leader` prefix for global bindings
- Use `set-popup-rule!` for popup buffer display rules
- Use `fboundp` guards for optional package entrypoints (e.g.
  `org-roam-db-autosync-mode`)
- Comment out unused modules in `init.el` — never delete lines
- Run `doom sync` after `init.el` or `packages.el` changes
- Snippets live in `~/.config/doom/snippets/<major-mode>/` and are organized by
  major mode

## Config Modularity (When config.el Grows)

As `config.el` grows, consider splitting it into topic-specific files loaded
from the main config via `load!`. This pattern is used in Diogo Doreto's config
(see `~/.config/doom/dd/`):

```elisp
;; In config.el near the bottom:
(load! "dd/org")
(load! "dd/lsp")
(load! "dd/terminal")
```

Each file under `~/.config/doom/dd/<topic>.el` gets its own lexical-binding
cookie. This keeps `config.el` readable and makes it easy to temporarily disable
an area by commenting its `load!` line.

This config currently keeps its main runtime customization in `config.el`.
Suggest splitting when a single topic block exceeds ~50 lines.

## Doom Framework Architecture

Understanding how Doom is structured helps you make correct decisions beyond
which file to edit.

### The `doom!` Module System

`init.el` declares modules inside `(doom! ...)`, grouped into 13 categories:

| Category      | Purpose                                     |
| :------------ | :------------------------------------------ |
| `:input`      | Input methods (bidi, CJK)                   |
| `:completion` | Company, corfu, vertico, helm, ivy, ido     |
| `:ui`         | Visual layer: modeline, popup, tabs, doom   |
| `:editor`     | Evil, snippets, format, fold, word-wrap     |
| `:emacs`      | Dired, ibuffer, tramp, undo, vc, electric   |
| `:term`       | vterm, eshell, shell, term                  |
| `:checkers`   | Syntax, spell, grammar                      |
| `:tools`      | LSP, magit, lookup, direnv, docker, eval    |
| `:os`         | OS-specific: macos, tty                     |
| `:lang`       | Language support: python, org, rust, latex… |
| `:email`      | mu4e, notmuch, wanderlust                   |
| `:app`        | Calendar, emms, everywhere, rss, irc        |
| `:config`     | default (+bindings +smartparens), literate  |

Lines within each category are sorted alphabetically. Comment disabled modules,
never delete them — the commented-out line is documentation.

### Module Flags

Flags (`+keyword`) parametrize a module — switching backends (`+eglot` vs
`+lsp-mode`), enabling features (`+roam`), changing UI (`+childframe`,
`+icons`), or pulling in packages (`+dirvish`).

To resolve a flag's meaning: put cursor on the flag in `init.el` and press
`K` (`C-c c k`) for docs, or `gd` (`C-c c d`) to jump to its definition in
`~/.config/emacs/modules/<cat>/<mod>/+<flag>.el`.

See `references/doom-api.md` for a table of common flags.

### Doom Variables

| Variable           | Value                           |
| :----------------- | :------------------------------ |
| `doom-user-dir`    | `~/.config/doom/`               |
| `doom-cache-dir`   | `~/.config/emacs/.local/cache/` |
| `doom-modules-dir` | `~/.config/emacs/modules/`      |

These are safe to reference in config.el (e.g. `(expand-file-name \"foo.el\"
doom-user-dir)`).

### Reload Without Restarting

Doom runs an Emacs server by default. Instead of restarting:

- **Inside Emacs:** `M-x doom/reload` — reloads config, no restart
- **From terminal:** `emacsclient -e '(doom/reload)'`
- **After `doom sync`:** run `doom/reload` last to avoid the format-on-save
  indentation issue (see Pitfalls)

### `:tools lsp` — Two Backends

The LSP module supports two backends via flag:

| Flag        | Backend  | When                          |
| :---------- | :------- | :---------------------------- |
| `+eglot`    | eglot    | Simpler, built-in integration |
| `+lsp-mode` | lsp-mode | More features, more config    |

Language modules like `(python +lsp)` or `(rust +lsp)` inherit whichever
backend is active — they don't select their own. Configure only the backend
you've enabled, not both.

### Diagnostic Commands

| Command              | Use                                |
| :------------------- | :--------------------------------- |
| `doom doctor`        | After every `doom sync`            |
| `doom info`          | Full diagnostics (for bug reports) |
| `doom env`           | Regenerate the environment file    |
| `emacs --debug-init` | Catch errors with stack trace      |
| `M-x doom/debug`     | Toggle debug logging               |

## Doom API Essentials (Compact)

See `references/doom-api.md` for the full syntax and examples. These are the
patterns Hermes most often gets wrong — commit them to memory:

- **`after!`** — defer config until a feature loads. Use instead of
  `with-eval-after-load`. `(after! org (setq org-adapt-indentation nil))`
- **`use-package!`** — Doom's package declaration + config. Not the same as
  `use-package` from MELPA. `(use-package! foo :defer t :config ...)`
- **`map!`** — keybinding with evil state-aware prefixes:
  `:leader` (`SPC`), `:n` (normal), `:i` (insert), `:v` (visual),
  `:m` (motion). `(map! :leader :desc \"Desc\" \"f f\" #'find-file)`
  `(map! :n \"C-c C-f\" #'some-command)`
- **`set-company-backend!`** — per-mode company backend configuration
- **`add-hook!`** — multi-mode hook helper. `(add-hook! '(a-mode b-mode) #'fn)`
- **`setq-hook!`** — set buffer-local variables in a hook, cleaner than a lambda
  `(setq-hook! 'org-mode-hook truncate-lines nil)`
- **`load!`** — load an Elisp file relative to `doom-user-dir`
  `(load! \"dd/org\")` loads `~/.config/doom/dd/org.el`
- **`featurep!`** — compile-time module check
  `(when (featurep! :ui popup) ...)`
- **`set-popup-rule!`** — control popup buffer display

## Emacs Lisp Companion Skill Strategy

`emacs-lisp-expert` is a useful optional companion skill, not a hard dependency
of this repo. When working with users or agents who do not have it installed,
suggest it once as an optional add-on for deeper Emacs Lisp help, then continue
without blocking. New users who have Hermes installed can try to install it from
their configured skill sources:

```sh
hermes skills search emacs-lisp-expert
hermes skills install <matching-skill-id>
```

If no matching skill is available, continue with this fallback checklist before
editing Emacs Lisp:

1. Prefer Doom macros over vanilla equivalents: `after!`, `use-package!`,
   `map!`, `add-hook!`, `setq-hook!`, `set-popup-rule!`.
2. Check whether a symbol exists before calling optional package entrypoints:
   `(when (fboundp 'some-command) ...)`.
3. Keep package installation in `packages.el`; keep runtime configuration in
   `config.el`.
4. Validate changed `.el` files with `check-parens` before running `doom sync`.
5. When unsure about a function or variable, read its source in
   `~/.config/emacs/` or `~/.config/emacs/.local/straight/repos/` instead of
   guessing.

Repo policy: mention the companion skill as optional in AGENTS.md/README.md,
but never require a missing local skill for basic repo maintenance.

## Procedures

### A. Adding a Module to init.el

1. Find the appropriate section under `(doom! ...)`
2. Uncomment the module line (comment disabled modules, never delete them)
3. Add `+flag` suffixes as needed: `(org +roam +babel +dragndrop)`
4. Run: `doom sync`
5. Restart Emacs

### B. Installing a Package

1. Add to `packages.el`:
   - **MELPA:** `(package! package-name)`
   - **Git repo:** `(package! name :recipe (:host github :repo "user/repo"))`
2. Run: `doom sync`
3. Restart Emacs
4. Configure in `config.el` with `use-package!` or `after!`

### C. Adding a Mode Hook

Use Doom's `add-hook!` helper from `config.el`:

```elisp
(add-hook! '(mode1-mode-hook mode2-mode-hook) #'some-minor-mode)
(add-hook! 'prog-mode-hook #'some-global-thing)
```

### D. Configuring a Built-in Module

Use `after!` in `config.el`:

```elisp
(after! company
  (setq company-idle-delay 0.2)
  (set-company-backend! 'prog-mode 'company-files ...))
```

Do not try to `use-package!` modules that Doom already manages. Use `after!`.

### E. Setting a Keybinding

Use `map!` in `config.el`:

```elisp
(map! :leader :desc "Description" "f f" #'some-command)
(map! :n "C-c C-f" #'find-file)  ; Normal mode only
```

### F. Enabling a Minor Mode Globally

In `config.el`:

```elisp
(some-global-mode 1)
;; or via hooks when there's no global mode
(add-hook! '(prog-mode-hook text-mode-hook) #'some-mode)
```

### G. Upgrading the Doom Framework

When `doom upgrade` is needed:

1. **Backup first:** `cp -a ~/.config/doom ~/.config/doom.backup.$(date +%Y%m%d)`
2. **Run upgrade:** `doom upgrade`
3. **Verify:** `doom sync && doom doctor`
4. **Check doctor output** for deprecation warnings — macros sometimes change between versions
5. **If something breaks:** `doom rollback` reverts the framework; restore `~/.config/doom.backup.*` if config files were affected

Do not skip the backup. `doom upgrade` modifies `~/.config/emacs/` but
`~/.config/doom/` is yours — framework updates can introduce API changes that
break your config.

### H. Dirvish Launcher Binding

When Doom's `dired +dirvish` module is enabled, configure Dirvish behavior in
`config.el` with `after! dirvish`, but keep launcher keybindings outside the
`after!` block so they are available immediately and can autoload the command.

Preferred pattern for this config:

```elisp
;;; DIRVISH
;; Keep the launcher binding available immediately; the command is autoloaded.
(map! :leader :desc "Dirvish dwim" "d d" #'dirvish-dwim)

(after! dirvish
  (setq dirvish-attributes '(vc-state nerd-icons subtree-state collapse git-msg file-size))
  (setq dirvish-subtree-state-style 'nerd)
  (setq dirvish-path-separators
        (list (format " %s " (nerd-icons-codicon "nf-cod-home"))
              (format " %s " (nerd-icons-codicon "nf-cod-root_folder"))
              (format " %s " (nerd-icons-faicon "nf-fa-angle_right")))))
```

Pitfall: putting `SPC d d` inside `(after! dirvish ...)` can delay the binding
until Dirvish has already loaded. For launcher commands, bind first; customize
after load.

### I. Enabling Spell Checking with Jinx

This repo uses Jinx for spelling. Treat Flyspell as historical context unless
the user explicitly asks to restore it.

Jinx is async, avoids one subprocess per check, and supports multiple languages
simultaneously. It is not a Doom module flag: keep Doom's `(spell +flyspell)`
line commented in `init.el`, install Jinx in `packages.el`, and configure it in
`config.el` with `use-package!`.

Before recommending Jinx, check system support. Jinx needs Enchant and a backend
spell dictionary; on Debian/PikaOS-style systems the useful probes are:

```sh
command -v enchant-2 || command -v enchant
command -v pkg-config
command -v hunspell || command -v nuspell
```

Do not persist missing-package warnings as durable skill facts; they are local
setup state. If missing, recommend the corresponding OS packages. For Jinx
builds, the runtime Enchant package is not enough; the development package must
provide the `enchant-2.pc` pkg-config file. On Debian/PikaOS-style systems this
is typically `libenchant-2-dev` plus `pkg-config` and a Hunspell/Nuspell
dictionary such as `hunspell-en-us`. If `pkg-config --exists enchant-2` fails,
install `libenchant-2-dev` before running `doom sync`.

Use this Doom-native configuration:

```elisp
;; init.el — keep the spell module commented; do not delete the line
;; (spell +flyspell)

;; packages.el
(package! jinx)

;; config.el
(use-package! jinx
  :hook ((text-mode prog-mode conf-mode yaml-mode) . jinx-mode)
  :config
  (setq jinx-languages "en_US")
  (map! :map jinx-mode-map
        "M-$" #'jinx-correct
        :leader
        (:prefix ("s" . "spelling")
         :desc "Correct word" "c" #'jinx-correct
         :desc "Next misspelling" "n" #'jinx-next
         :desc "Previous misspelling" "p" #'jinx-previous)))
```

Then run `doom sync`, restart or `doom/reload`, and run `doom doctor`. If using
`emacsclient -e '(doom/reload)'`, remember it only works when the Emacs server
is already running; otherwise tell the user to restart Emacs or run
`M-x doom/reload` inside Emacs.

Useful Jinx verification after `doom sync`:

```sh
emacs --batch -L ~/.config/emacs/.local/straight/repos/jinx \
  --eval "(progn (require 'jinx) (message \"jinx loads OK: %s\" (featurep 'jinx)))"
```

For multilingual setups, extend `jinx-languages`, e.g. `"en_US de_DE"`, but
start with the user's primary dictionary unless they ask for more.

Flyspell legacy pattern, for reference only:

```elisp
;; init.el
(spell +flyspell)

;; config.el
(add-hook! '(org-mode-hook markdown-mode-hook text-mode-hook) #'flyspell-mode)
(add-hook! '(prog-mode-hook conf-mode-hook yaml-mode-hook) #'flyspell-prog-mode)
```

Do not reintroduce Flyspell hooks while this repo is on Jinx.

## Keeping the Config Repo Self-Contained

This skill lives at `.agents/skills/doom-emacs/SKILL.md` — the repo itself
is the canonical source. Anyone who clones this repo gets the full skill and
API reference.

The Hermes runtime mirror at `~/.hermes/skills/emacs/doom-emacs-config/` exists
only for auto-loading. When you update this skill, sync repo to mirror with
`cp` so Hermes agents can discover it without reading the repo first. Do not
hand-edit the mirror line by line.

### AGENTS.md / README.md Sync Protocol

AGENTS.md is the authoritative source for user-specific policies (completion
preference, window rules, Markdown style, verification steps). Whenever
you add a new policy or safety step to AGENTS.md in the same session:

1. Add a condensed version to README.md (same key information, less detail)
2. If the change introduces a new verification command (e.g. `doom doctor`),
   add it to both the AGENTS.md table and README.md's bullet list
3. Lint both files before declaring done

README.md is not a full mirror — it skips the detailed tables and commentary
that AGENTS.md carries. But every actionable policy in AGENTS.md should have
a corresponding line in README.md so agents and humans alike find the rule
from either entry point.

## Restoring Official Template Content

Doom ships canonical example files at `~/.config/emacs/static/`:

- `config.example.el`
- `init.example.el`
- `packages.example.el`

These contain the original template comments and example settings. If a file
has been trimmed of template boilerplate, fetch the relevant `.example.el` and
restore the missing comments. The examples are also available in the Doom repo
under `static/` on the master branch.

When restoring template comments, preserve the user's actual values — re-add
only the comment blocks, not the example code.

## Safety Checks — Always Run After Changes

| After this              | Run this                                                                           |
| :---------------------- | :--------------------------------------------------------------------------------- |
| Any requested Doom edit | `check-parens` for changed `.el` files, then `doom sync` unless user says not to   |
| `init.el` change        | `doom sync` (required after any module change)                                     |
| `packages.el` change    | `doom sync` (required after any package change)                                    |
| `config.el` change      | `M-x eval-buffer` or restart Emacs; `doom sync` is still acceptable/preferred here |
| Any `.el` file change   | `check-parens` to verify balanced parens                                           |
| After `doom sync`       | `doom doctor` — catches missing deps, wrong flags, broken recipes                  |
| Emacs won't start (CLI) | `emacs --batch --eval "(let ((check-parens t)) (check-parens))"` for paren check   |

**Paren balancing is critical** — a missing paren in `config.el` can prevent
Emacs from starting. Always verify before declaring done.

**Run `doom doctor` after every `doom sync`** — `doom sync` compiles but doesn't
validate config. `doom doctor` catches module flag mismatches, missing system
dependencies, and package recipe errors that would otherwise fail silently.

**For this user's Doom repo, run `doom sync` after edits even when only
`config.el` changed unless explicitly told not to.** It is cheap, safe, and
matches the expected workflow; still run the paren check first so syntax errors
are caught locally before Doom rebuilds the profile.

## Pitfalls

- **Do not edit `early-init.el` or `~/.emacs.d/init.el`** — Doom manages those.
  All user config goes in `~/.config/doom/`.
- **Do not use `with-eval-after-load`** — use Doom's `after!` macro instead.
- **Do not use standard `use-package`** — use Doom's `use-package!` (with
  trailing bang). They have different deferral semantics.
- **`(setq-default ...)`** is rarely needed in Doom. Prefer `(setq ...)`.
- **`straight.el` (not `package.el`)** is Doom's package manager. If a user
  runs `package-install`, it goes to the wrong place. Always use `package!`
  in `packages.el` followed by `doom sync`.
- **Never delete lines from `init.el`** — comment them out instead. Users rely
  on seeing the full module list to know what's available.
- **On‑save formatting** — `config.el` has `(format +onsave)` in init.el, so
  Emacs auto-formats on save. Running `doom sync` then saving `config.el` may
  break indentation. Warn the user and have them run `M-x doom/reload` after
  `doom sync` to avoid this.

## Session Reference Notes

- `references/2026-05-16-doom-config-evolution.md` captures the session where
  this repo was named `doom-emacs-config`, Flyspell was replaced with Jinx,
  `SPC d d` was made an immediate Dirvish launcher binding, and the user
  clarified that `doom sync` should be run after requested Doom edits.

## Reference Sources

When you need to understand how a package or Doom module works, the source
code is at your fingertips — reading it is far more reliable than guessing at
API surfaces.

- **Doom framework source:** `~/.config/emacs/` — This is a clone of the
  [official Doom Emacs repo](https://github.com/doomemacs/doomemacs). Browse
  `modules/` for built-in module definitions, `lisp/` for core libraries
  (including macro definitions), and `core/` for the module system. You can
  also browse the repo on GitHub to check issues, PRs, and docs online.
- **Installed package source:** `~/.config/emacs/.local/straight/repos/` —
  each package (company, corfu, consult, etc.) has its own directory. Read the
  source to understand available functions, variables, hooks, and faces.

Use `M-x find-library` from within Emacs to jump to any loaded library's
source directly.
