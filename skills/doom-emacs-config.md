---
name: doom-emacs-config
description: Configure Doom Emacs correctly — module system, package management, safe patterns, and verification steps. Load before modifying any Doom config file.
version: 1.0.0
author: Hermes Agent
tier: powerful
metadata:
  hermes:
    tags: [doom, emacs, emacs-lisp, config, elisp]
    related_skills: [emacs-lisp-expert]
    trigger_keywords: [doom, config.el, init.el, packages.el, emacs config, doom sync, doom doctor, doom upgrade, use-package, after!]
---

# Doom Emacs Config

Skill for correctly modifying a Doom Emacs configuration. Load this whenever
touching files under `~/.config/doom/` or when the user asks about Emacs config.

**Prerequisite:** Load the `emacs-lisp-expert` skill too — it covers Emacs Lisp
fundamentals that this skill builds on.

**Critical:** Before making any change, read `~/.config/doom/AGENTS.md` if it
exists — it contains user-specific policies (completion preference, window
management rules, package restrictions, etc.).

## File Roles — Know What Goes Where

Doom splits config across three files. Putting the wrong thing in the wrong
file is the most common mistake.

| File          | Purpose                                                  | `doom sync` needed? |
| :------------ | :------------------------------------------------------- | :------------------ |
| `init.el`     | Declare which Doom modules are enabled, with their flags | Yes                 |
| `packages.el` | Install external packages (MELPA, git repos)             | Yes                 |
| `config.el`   | Settings, keybinds, hooks, advice, custom functions      | No                  |

## Doom API Essentials (Compact)

See `references/doom-api.md` for the full details. These are the patterns
Hermes most often gets wrong — commit them to memory:

- **`after!`** — defer config until a feature loads. Use instead of
  `with-eval-after-load`. `(after! org (setq org-adapt-indentation nil))`
- **`use-package!`** — Doom's package declaration + config. Not the same as
  `use-package` from MELPA. `(use-package! foo :defer t :config ...)`
- **`map!`** — keybinding. Learn `:leader`, `:n`, `:i`, `:v` prefixes.
- **`set-company-backend!`** — per-mode company backend configuration.
- **`add-hook!`** — multi-mode hook helper. `(add-hook! '(a-mode b-mode) #'fn)`
- **`featurep!`** — compile-time module check. `(when (featurep! :ui popup) ...)`
- **`set-popup-rule!`** — control popup buffer display.
- **`+` flags** — module variants like `(company +childframe +tng)`

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

| After this              | Run this                                                                         |
| :---------------------- | :------------------------------------------------------------------------------- |
| `init.el` change        | `doom sync` (required after any module change)                                   |
| `packages.el` change    | `doom sync` (required after any package change)                                  |
| `config.el` change      | `M-x eval-buffer` or restart Emacs                                               |
| Any `.el` file change   | `check-parens` to verify balanced parens                                         |
| After `doom sync`       | `doom doctor` — catches missing deps, wrong flags, broken recipes                |
| Emacs won't start (CLI) | `emacs --batch --eval "(let ((check-parens t)) (check-parens))"` for paren check |

**Paren balancing is critical** — a missing paren in `config.el` can prevent
Emacs from starting. Always verify before declaring done.

**Run `doom doctor` after every `doom sync`** — `doom sync` compiles but doesn't
validate config. `doom doctor` catches module flag mismatches, missing system
dependencies, and package recipe errors that would otherwise fail silently.

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
- **On-save formatting** — `config.el` has `(format +onsave)` in init.el, so
  Emacs auto-formats on save. Running `doom sync` then saving `config.el` may
  break indentation. Warn the user and have them run `M-x doom/reload` after
  `doom sync` to avoid this.
