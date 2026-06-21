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

### Before you troubleshoot — collect diagnostics

When something breaks, gather this information before changing anything:

- **`doom info`** — prints version, system info, load path, startup time.
  Essential for any bug report or investigation.
- **`*doom*` buffer** — check for recipe errors, compile warnings, module flag
  problems after the last `doom sync`.
- **`*Messages*` buffer** (`C-h e`) — shows runtime errors, eval output,
  and Emacs-init messages. Start here after an error happens during use.
- **`emacs --debug-init`** from the terminal — shows a full stack trace at
  init time, bypassing Emacs as a daemon so you see every error.
- **What changed last?** The most common cause of a new problem is the last
  change. If Emacs worked before a `doom sync`, a `doom upgrade`, or an edit
  to `init.el`/`config.el`/`packages.el`, start there.

### Emacs fails to start

| Symptom | Likely cause | Fix |
| :--- | :--- | :--- |
| Blank screen, Emacs exits immediately | Unbalanced parens or syntax error in a `.el` file | `emacs --debug-init` to locate the error; `check-parens` on affected files |
| Error mentions a specific file or line | An error in that file at that line | Inspect the file around that line, check recent edits |
| Error is a missing function or variable | A `require` or autoload is failing | The stack trace shows what Emacs tried to load and where |
| Error about `void-variable` or `void-function` | A referenced symbol doesn't exist, or load order is wrong | Check `featurep!` guards, ensure `use-package!` declarations precede config blocks |
| Error about an unknown module flag | Typo or removed flag in `init.el` | Check the module's README.org for valid flags |
| Emacs starts but shows nothing useful | The daemon started but GUI/X11 failed | Run `emacs --no-window-system` or `emacs -nw` to force terminal mode |

Steps:

1. **`emacs --debug-init`** from the terminal. The stack trace identifies the
   offending file, line, and symbol. Read it from bottom to top — the first
   error is at the bottom.
2. **Check parens.** A missing paren is the most common cause:
   ```sh
   emacs --batch --eval "(progn (let ((check-parens t)) (check-parens)))"
   ```
   or from inside Emacs: `M-x check-parens`
3. **Check `*doom*`** for compile warnings after a `doom sync`.
4. **Isolate.** Comment out recent additions in blocks, re-test with
   `emacs --debug-init`, repeat until the error disappears. The last block
   you commented is the cause.
5. **`doom doctor`** after Emacs starts — catches module flag mismatches and
   missing system deps that may cause secondary failures.

### Config changes not taking effect

| Change in       | Required action                      | Typical mistake |
| :-------------- | :----------------------------------- | :-------------- |
| `init.el`       | `doom sync` then restart             | Running `doom/reload` instead of `doom sync` |
| `packages.el`   | `doom sync` then restart             | Running `package-install` instead of `doom sync` |
| `config.el`     | `M-x doom/reload` or restart Emacs   | Running `doom sync` but not reloading |
| Snippet file    | Save file, no Emacs restart needed   | Unclear; check `SPC h i` in the target mode |

Verify with:
- `C-h v <variable-name>` — shows the current runtime value
- `C-h m` — lists active minor modes in the current buffer
- `M-x describe-mode` — describes the current major mode and its keybindings
- If a value still shows the old setting after reload, the `setq` may be in a
  `after!` block that hasn't triggered yet, or is overridden later in config.el

### Keybinding doesn't work

- **`C-h k <key-sequence>`** — tells you what command the key sequence runs.
  If it says "is undefined", the binding was never set or was overridden.
- **`C-h w <command>`** — tells you what keys are bound to a command.
- **Check evil state.** `:n` bindings only work in normal mode. `:i` bindings
  only work in insert mode. If you're in the wrong state, the binding is
  invisible.
- **Check mode-specific maps.** A binding in `org-mode-map` doesn't apply in
  `prog-mode`. Use `C-h b` to see all bindings active in the current buffer.
- **Check load order.** If the binding is inside `(after! <pkg> ...)`, it
  doesn't take effect until that package loads. For launcher commands, bind
  outside `after!`.
- **Run `doom sync` and restart.** If the binding still doesn't appear, verify
  the key sequence isn't consumed by another prefix: `C-h k <partial-seq>` to
  see what the prefix is bound to.

### Package install failures

1. **`doom doctor`** — catches most recipe and dependency issues. If it reports
   a broken recipe, the error text tells you what's wrong.
2. **`doom sync -u`** — updates straight.el and retries the recipe against the
   latest package source.
3. **Check `*doom*` buffer** — recipe errors are logged there. The exact cause
   (missing git ref, failed compile, version conflict) is in the log.
4. **Missing git ref.** If a recipe fails with an error about a commit SHA or
   tag that doesn't exist, the package may have been renamed, force-pushed, or
   removed upstream. Update the recipe with a current ref or switch to a stable
   tag.
5. **Hard reset for a single package:**
   ```sh
   rm -rf ~/.config/emacs/.local/straight/repos/<package>
   doom sync
   ```
   This forces straight to reclone from scratch. Useful when the local git
   checkout is in a bad state.

See `references/package-management.md` for pin recovery, lockfile repair,
and straight internals.

### `doom sync` fails or hangs

- **Hangs during cloning.** A large package or a slow connection can cause it.
  Check `*doom*` for which repo it's stuck on. Kill and retry with `doom sync`.
- **Hangs indefinitely.** Often a git credential prompt. Check if a recipe
  references a private repo. Run `doom sync -d` for debug output.
- **Error about dirty checkout.** straight refuses to update a package whose
  local repo has uncommitted changes. Clean it:
  ```sh
  cd ~/.config/emacs/.local/straight/repos/<package>
  git checkout .
  ```
  Then retry `doom sync`.
- **Error about locked package.** A `:pin` in packages.el sets a fixed version.
  Remove the `:pin` line or update the SHA to unlock.
- **Full reset of straight:**
  ```sh
  rm -rf ~/.config/emacs/.local/straight/build-*/
  doom sync
  ```
  This rebuilds all packages from their cached repos. If repos themselves are
  corrupted, also remove `~/.config/emacs/.local/straight/repos/` (longer).

See `references/package-management.md` for the full straight lifecycle.

### LSP not working

- **`M-x eglot-reconnect`** — reconnects the LSP session without closing files.
- **`M-x eglot-shutdown-all`** then re-open the file — forces a fresh session.
- **Verify the language server binary** — `which <language-server>` should
  return a path. If not, install the server separately.
- **Check `.eglot/` workspace logs** — in the project root, `.eglot/` contains
  server logs with protocol messages and errors.
- **Run `doom doctor`** — verifies that the LSP module has no flag conflicts.
  If `(python +lsp)` is enabled but `(lsp +eglot)` isn't, LSP won't work.
- **Check `M-x eglot-events-buffer`** — shows the raw LSP protocol exchange.
  Server-side errors (incapable server, unsupported capability) appear here.

### `void-function` errors

A `void-function` error means Emacs tried to call a function that isn't
defined at runtime. The bytecode was compiled against a definition that is
no longer available.

- **Common cause:** the package calls legacy Emacs functions removed in newer
  Emacs versions. Example: bare `incf`/`decf` in Jinx 2.7 — Emacs 30 only
  provides the `cl-lib` names (`cl-incf`/`cl-decf`).
- **Fix:** install aliases before the package loads:
  ```elisp
  (unless (fboundp 'incf) (defalias 'incf #'cl-incf))
  ```
- **After adding aliases,** run `doom sync` and restart Emacs so bytecode is
  recompiled against the aliases.
- **Check the user's PROFILE.md** or `.agents/skills/doom-emacs/references/`
  for config-specific workarounds (this repo has one for Jinx).

### Slow Emacs startup

| Symptom | Likely cause | Fix |
| :--- | :--- | :--- |
| Startup > 3 seconds | Packages loading eagerly | Add `:defer t` to `use-package!` forms |
| Specific package takes long | Expensive `:config` block runs at load | Move `:config` to an `after!` block; use `:defer t` |
| Startup slow only in GUI | Font or tooltip initialization | Check font cache, disable unneeded UI features |
| Startup slow only in terminal | Frame initialization differences | Check for terminal-specific config that waits on X |

Steps:
- **`doom info`** includes a "Startup time" section with per-phase timing.
- **`benchmark-init`** — enable in init.el for a detailed report of which
  packages contribute to startup time. Not installed by default.
- **`M-x profiler-start`** then **`M-x profiler-report`** after startup
  identifies expensive operations during use.
- **Check `:defer t`** — every `use-package!` form should have `:defer t`
  unless the package must load at startup. Without defer, the package loads
  immediately.
- **Verify `lexical-binding: t`** in all `.el` files — dynamic binding slows
  the byte-compiler and increases memory per buffer.

### Missing system dependencies

`doom doctor` reports most missing dependencies, but not all are obvious:

- **Language servers** for LSP modules — install via the system package
  manager (`pip`, `npm`, `apt`, `brew` depending on the server).
- **Spell checking** — Jinx needs Enchant and a dictionary. See PROFILE.md
  for this config's system dependencies.
- **PDF tools** — the `:tools pdf` module needs `pdf-tools` epdfinfo
  compiled (done by `doom sync` if the build toolchain is present).
- **Docker, direnv** — CLI tools must be on `$PATH`. `doom doctor` checks
  these but the error message says "not found" rather than "install this."

Verify with: `doom doctor` — run it after any `doom sync` and check the
warnings section. A green check means passing; a yellow warning means a
missing dep that may affect that module's feature.

### Font or icon display issues

- **Box characters or missing icons** (`\xf026`-like display) — all-the-icons
  or nerd-icons font not installed. Run `M-x all-the-icons-install-fonts` or
  `M-x nerd-icons-install-fonts`. On Linux, this copies the font to
  `~/.local/share/fonts/`, followed by `fc-cache -f`.
- **Modeline shows `X` instead of icons** — same cause. Reinstall fonts and
  restart Emacs.
- **Font size too large/small in GUI** — set the default font in `config.el`
  via `(set-fontset-font ...)` or customize `doom-font`.
- **CJK or special characters render as blank** — a font with those glyphs
  isn't configured. Use `set-fontset-font` in `config.el` to specify fallback
  fonts.

### Emacs hangs or freezes

- **Infinite loop in a hook or mode.** `M-x toggle-debug-on-quit` then
  press `C-g` — the debugger shows what Emacs is executing when you quit.
- **LSP session stuck.** `M-x eglot-shutdown-all` to kill all LSP processes.
- **Process not responding.** `M-x list-processes` (`C-h p`) to see running
  subprocesses. Kill stuck ones with `k`.
- **Hang on file open.** Tramp or a file watcher may be waiting on a remote
  connection. Check `*tramp/...*` buffers.
- **Profiler can identify the culprit.** `M-x profiler-start` before the
  operation, `M-x profiler-report` after. If you can't start the profiler
  before the hang, start it on next Emacs start and reproduce.

### `doom doctor` warning guide

| Warning text | What it means | Action |
| :--- | :--- | :--- |
| "Couldn't find executable" | A required CLI tool is missing | Install the tool or disable the module |
| "No module flag matches" | `init.el` has a flag that the module doesn't know about | Check the module's README.org and correct the flag |
| "Package is pinned to a version that may not exist" | `:pin` SHA doesn't match upstream | Update the SHA or remove the `:pin` |
| "Recipe error for <package>" | straight can't process the recipe | Check the recipe syntax and the package source |
| "Straight repo is dirty" | Uncommitted changes in a package checkout | `git checkout .` in the repo or re-clone |

### Recovery procedures

**After a failed `doom upgrade`:**

1. Restore from backup:
   ```sh
   cp -a ~/.config/doom.backup.2026???? ~/.config/doom
   ```
2. Revert the Doom install:
   ```sh
   cd ~/.config/emacs
   git reset --hard HEAD@{1}
   ```
3. Run `doom sync && doom doctor`
4. If Emacs still won't start, restore `~/.config/doom` from the backup and
   pin the working Doom version.

**After a git-revert of config changes:**

1. `git log --oneline -5` to find the commit to revert.
2. `git revert <commit>` or `git checkout <file>` for individual files.
3. Run `doom sync` if `init.el` or `packages.el` changed with the revert.
4. Restart Emacs.

**Clean rebuild of all packages (last resort):**

```sh
rm -rf ~/.config/emacs/.local/straight
doom sync
```

This forces straight to re-clone every package. Requires a network connection
and takes several minutes. Afterward, run `doom doctor` to verify.

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
