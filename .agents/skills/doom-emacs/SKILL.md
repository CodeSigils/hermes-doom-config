---
name: doom-emacs-config
description: Configure Doom Emacs correctly — module system, package management, safe patterns, and verification steps. Load before modifying any Doom config file.
metadata:
  version: "1.3.0"
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
Emacs Lisp for Doom Config section below. Suggest installing
`emacs-lisp-expert` once as an optional companion for deeper Emacs Lisp work.
This repo must remain self-contained for new users and agents.

**Critical:** Before making any change, read `~/.config/doom/AGENTS.md` if it
exists — it contains user-specific policies (completion preference, Markdown
style, verification steps, etc.).

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

Doom splits config across three files. Putting the wrong thing in the wrong
file is the most common mistake.

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
- Use `fboundp` guards for optional package entrypoints (e.g.
  `(when (fboundp 'some-command) (some-command 1))`)
- Comment out unused modules in `init.el` — never delete lines
- Snippets live under `<doom-user-dir>/snippets/<major-mode>/`

## Config Modularity

Split `config.el` into topic-specific files when a topic block exceeds ~50
lines. Load them with `load!`:

```elisp
;; In config.el near the bottom:
(load! "modules/org")
(load! "modules/lsp")
```

Each topic file gets its own lexical-binding cookie. This keeps `config.el`
readable and makes it easy to temporarily disable an area by commenting its
`load!` line.

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
| `:lang`       | Language support: python, org, rust, latex  |
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
`K` (`C-c c k`) for inline docs, or `gd` (`C-c c d`) to jump to its
definition in `~/.config/emacs/modules/<cat>/<mod>/+<flag>.el`.

See `DOOM-API.md` for a table of common flags used in this repo and the
canonical Doom API guide.

### Doom Variables

| Variable           | Value                                    |
| :----------------- | :--------------------------------------- |
| `doom-user-dir`    | `~/.config/doom/`                        |
| `doom-cache-dir`   | `~/.config/emacs/.local/cache/`          |
| `doom-modules-dir` | `~/.config/emacs/modules/`               |

These are safe to reference in config.el, e.g.
`(expand-file-name "foo.el" doom-user-dir)`.

### Reload Without Restarting

- **Inside Emacs:** `M-x doom/reload` — reloads config, no restart
- **From terminal:** `emacsclient -e '(doom/reload)'`
- **After `doom sync`:** run `doom/reload` last to avoid format-on-save
  indentation issues (see Pitfalls)

### `:tools lsp` — Two Backends

| Flag        | Backend  | When                          |
| :---------- | :------- | :---------------------------- |
| `+eglot`    | eglot    | Simpler, built-in integration |
| `+lsp-mode` | lsp-mode | More features, more config    |

Language modules like `(python +lsp)` inherit whichever backend is active —
they don't select their own. Configure only the backend you've enabled, not
both.

### Diagnostic Commands

| Command              | Use                                |
| :------------------- | :--------------------------------- |
| `doom doctor`        | After every `doom sync`            |
| `doom info`          | Full diagnostics (for bug reports) |
| `doom env`           | Regenerate the environment file    |
| `emacs --debug-init` | Catch errors with stack trace      |
| `M-x doom/debug`     | Toggle debug logging               |

## Doom API Essentials (Compact)

See `DOOM-API.md` for the full syntax and examples. These are the patterns
agents most often get wrong — commit them to memory:

- **`after!`** — defer config until a feature loads. Use instead of
  `with-eval-after-load`. `(after! org (setq org-adapt-indentation nil))`
- **`use-package!`** — Doom's package declaration + config. Not the same as
  `use-package` from MELPA. `(use-package! foo :defer t :config ...)`
- **`map!`** — keybinding with evil state-aware prefixes:
  `:leader` (`SPC`), `:n` (normal), `:i` (insert), `:v` (visual),
  `:m` (motion). `(map! :leader :desc "Desc" "f f" #'find-file)`
- **`set-company-backend!`** — per-mode company backend configuration
- **`add-hook!`** — multi-mode hook helper.
  `(add-hook! '(a-mode b-mode) #'fn)`
- **`setq-hook!`** — set buffer-local variables in a hook, cleaner than a
  lambda. `(setq-hook! 'org-mode-hook truncate-lines nil)`
- **`load!`** — load an Elisp file relative to `doom-user-dir`.
  `(load! "modules/org")` loads `~/.config/doom/modules/org.el`
- **`featurep!`** — compile-time module check.
  `(when (featurep! :ui popup) ...)`
- **`set-popup-rule!`** — control popup buffer display
- **`setq!`** — Doom's wrapper around `setq`. Use instead of `setq-default`.

## Emacs Lisp for Doom Config

A new Doom user doesn't need full Emacs Lisp fluency. Most config work uses a
small subset of the language. This section covers what you'll encounter.

### Special Forms You Will Use

| Form           | Purpose                          | Example                                        |
| :------------- | :------------------------------- | :--------------------------------------------- |
| `setq`         | Set a variable's value           | `(setq company-idle-delay 0.2)`                |
| `setq-local`   | Set value for current buffer     | `(setq-local truncate-lines nil)`              |
| `when`/`unless`| Conditional execution            | `(when (fboundp 'jinx-mode) (jinx-mode 1))`    |
| `let`          | Temporary local binding          | `(let ((url-package-name "foo")) ...)`          |
| `defun`        | Define a named function          | `(defun sand/my-fn () (message "hi"))`         |

### Key Patterns

**Guard optional integrations:**
```elisp
(when (fboundp 'some-command)
  (some-command 1))
```

**Prefer named functions over lambdas in hooks:**
```elisp
(defun sand/my-hook-fn () (setq-local truncate-lines nil))
(add-hook 'org-mode-hook #'sand/my-hook-fn)
```

**Custom prefix:** Use the user's custom prefix (e.g. `sand/`) for all custom
functions, variables, and private state. Never use bare `my-` or no prefix —
collisions with package-internal functions are silent and hard to debug.

### Discovering Emacs APIs

| Key / Command                | What it does                                  |
| :--------------------------- | :-------------------------------------------- |
| `C-h f`                      | Describe a function (args, docstring, source) |
| `C-h v`                      | Describe a variable (current value, docstring)|
| `C-h o`                      | Describe any symbol                           |
| `C-h m`                      | List active minor modes in current buffer     |
| `M-x find-library`           | Jump to a library's source code               |
| `M-x toggle-debug-on-error`  | Show full backtrace on next error             |

### Lexical Binding

Every `.el` file must start with:
```elisp
;;; filename.el -*- lexical-binding: t; -*-
```
Without it, closures capture variables by reference, not by value, causing
subtle bugs. The byte-compiler also produces better code with lexical binding.

### Runtime Debugging

- **`M-x toggle-debug-on-error`** — get a backtrace for errors that would
  normally show only a message
- **`M-x toggle-debug-on-quit`** (then `C-g`) — discover what's blocking on
  hang
- **`M-x profiler-start` / `M-x profiler-report`** — find performance
  bottlenecks
- **`(message "value: %s" my-var)`** — print to `*Messages*` buffer
- **`(insert (prin1-to-string my-var))`** — insert value into current buffer

## Procedures

### A. Adding a Module to init.el

1. Find the appropriate category section under `(doom! ...)`
2. Uncomment the module line (never delete commented modules)
3. Consult the module's README.org at
   `~/.config/emacs/modules/<cat>/<mod>/` to verify available flags
4. Add `+flag` suffixes as needed, e.g. `(org +roam +dragndrop)`
5. Run: `doom sync`
6. Restart Emacs

### B. Installing a Package

1. Add to `packages.el`:
   - **MELPA:** `(package! package-name)`
   - **Git repo:** `(package! name :recipe (:host github :repo "user/repo"))`
2. Run: `doom sync`
3. Restart Emacs
4. Configure in `config.el` with `use-package!` or `after!`

See `references/package-management.md` for pinning, updates, straight recipes,
and lockfile troubleshooting.

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

```elisp
(some-global-mode 1)
;; or via hooks when there's no global mode
(add-hook! '(prog-mode-hook text-mode-hook) #'some-mode)
```

### G. Upgrading the Doom Framework

1. **Backup first:** `cp -a ~/.config/doom ~/.config/doom.backup.$(date +%Y%m%d)`
2. **Run upgrade:** `doom upgrade`
3. **Verify:** `doom sync && doom doctor`
4. **Check doctor output** for deprecation warnings
5. **If something breaks:** restore `~/.config/doom.backup.*` from backup

Do not skip the backup. Framework changes can introduce API changes that break
your config.

## Troubleshooting

### Emacs fails to start

1. Run `emacs --debug-init` from the terminal. The stack trace identifies the
   offending file and line.
2. Check for unbalanced parens in recent `.el` edits:
   ```sh
   emacs --batch --eval "(progn (let ((check-parens t)) (check-parens)))"
   ```
   or in Emacs: `M-x check-parens`
3. If the error mentions a specific file, check recent changes to that file.
4. Isolate: comment out recent additions in blocks and re-test.
5. Check `*doom*` buffer for compile warnings after `doom sync`.

### Config changes not taking effect

| Change in       | Required action                      |
| :-------------- | :----------------------------------- |
| `init.el`       | `doom sync` then restart             |
| `packages.el`   | `doom sync` then restart             |
| `config.el`     | `M-x doom/reload` or restart Emacs   |

Verify with:
- `C-h v variable-name` — shows the current runtime value
- `C-h m` — lists active minor modes in the current buffer

### Keybinding doesn't work

- `C-h k <key-sequence>` — tells you what command the key runs
- `C-h w <command>` — tells you what keys are bound to a command
- Check evil state: `:n` bindings only work in normal mode
- Check mode-specific maps: an `org-mode-map` binding doesn't apply in
  `prog-mode`
- If the binding looks correct but isn't picked up, run `doom sync` and restart

### Package install failures

1. Run `doom doctor` — catches most recipe and dependency issues.
2. Run `doom sync -u` — updates straight.el and retries the recipe.
3. Check `*doom*` buffer for recipe errors — the exact cause is logged there.
4. If a recipe fails with a missing git ref, the package may have been renamed
   or removed upstream.
5. Hard reset for a single package:
   ```sh
   rm -rf ~/.config/emacs/.local/straight/repos/<package>
   doom sync
   ```

See `references/package-management.md` for pin recovery, lockfile repair,
and straight internals.

### LSP not working

- `M-x eglot-reconnect` — reconnects the LSP session
- `M-x eglot-shutdown-all` then re-open the file
- Verify the language server binary is installed: `which <language-server>`
- Check `.eglot/` workspace logs in the project root
- Run `doom doctor` to verify the LSP module has no flag conflicts

### `void-function` errors

- Package bytecode references a function that doesn't exist at runtime.
- Common cause: the package calls legacy Emacs functions removed in newer
  Emacs versions (e.g. bare `incf`/`decf` in older packages).
- Fix: install aliases before the package loads:
  ```elisp
  (unless (fboundp 'incf) (defalias 'incf #'cl-incf))
  ```
- After adding aliases, run `doom sync` and restart Emacs.
- Check the user's PROFILE.md or `references/` for config-specific workarounds.

### Slow Emacs startup

- Check `doom info` for the "Startup time" section.
- Look for packages that don't use `:defer t` in their `use-package!` form.
- `M-x profiler-start` then `M-x profiler-report` after startup identifies
  expensive operations.
- Verify `lexical-binding: t` is present in all `.el` files — dynamic binding
  slows the byte-compiler.

## Restoring Official Template Content

Doom ships canonical example files at `~/.config/emacs/static/`:

- `config.example.el`
- `init.example.el`
- `packages.example.el`

These contain the original template comments and example settings. If a file
has been trimmed of template boilerplate, restore the comment blocks from the
example — preserving the user's actual values, overwriting only comments.

## Safety Checks — Always Run After Changes

| After this              | Run this                                                                           |
| :---------------------- | :--------------------------------------------------------------------------------- |
| Any requested Doom edit | `check-parens` for changed `.el` files, then `doom sync` unless told not to        |
| `init.el` change        | `doom sync` (required after any module change)                                     |
| `packages.el` change    | `doom sync` (required after any package change)                                    |
| `config.el` change      | `M-x eval-buffer` or restart; `doom sync` works but check parens first             |
| Any `.el` file change   | `check-parens` to verify balanced parens                                           |
| After `doom sync`       | `doom doctor` — catches missing deps, wrong flags, broken recipes                  |
| Emacs won't start (CLI) | `emacs --debug-init` for stack trace; `emacs --batch` for paren check              |

**Paren balancing is critical** — a missing paren in `config.el` can prevent
Emacs from starting. Always verify before declaring done.

**Run `doom doctor` after every `doom sync`** — it catches module flag
mismatches, missing system dependencies, and package recipe errors that would
otherwise fail silently.

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
- **On‑save formatting** — if `format +onsave` is enabled, saving after
  `doom sync` can break indentation. Run `M-x doom/reload` after `doom sync`.
- **Stale template comments can mislead** — if restored upstream comments
  recommend `with-eval-after-load` or standard `use-package`, replace or
  annotate them to match your config's conventions.
- **Bind launcher keys outside `after!`** — putting a keybinding inside
  `(after! <pkg> ...)` delays the binding until the package loads. For
  commands meant to be run immediately, bind them directly and defer only
  the package configuration.

## Keeping the Config Repo Self-Contained

This skill lives at `.agents/skills/doom-emacs/SKILL.md`. Anyone who clones
this repo gets the full skill with it. After editing the skill, sync the Hermes
runtime mirror:

```sh
scripts/sync-doom-skill-mirror.sh
scripts/check-doom-skill-mirror.sh
```

See `AGENTS.md` for the two-clone protocol, source-destruction invariant, and
drift-detection steps.

## Reference Sources

When you need to understand how a package or Doom module works, the source
code is at your fingertips:

- **Doom framework source:** `~/.config/emacs/` — clone of the
  [official Doom Emacs repo](https://github.com/doomemacs/doomemacs). Browse
  `modules/` for built-in module definitions, `lisp/` for core libraries,
  and `core/` for the module system.
- **Installed package source:** `~/.config/emacs/.local/straight/repos/` —
  each package has its own directory with full source.
- **Doom Emacs Issues & Docs:** upstream GitHub repository for recent changes,
  open issues, and pull requests.
- **This repo's references:**
  - `references/INDEX.md` — external resource catalogue (community configs, keybinding reference, performance tips)
  - `references/package-management.md` — package lifecycle, pinning, straight internals, recovery
  - `.agents/skills/doom-emacs/references/` — session notes and config-specific troubleshooting
  - `AGENTS.md` — user-specific policies, workflow, drift prevention
