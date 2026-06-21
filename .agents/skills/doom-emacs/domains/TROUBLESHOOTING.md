# Troubleshooting Doom Emacs

Full diagnostic guide. Read this only when something breaks — it is the
longest domain file.

**Parent skill:** `SKILL.md` — compact core with file roles, API essentials,
safety checks, pitfalls, and the Quick Index for all domain files. Load
SKILL.md first for the minimal context every Doom edit needs.

## Before you troubleshoot — collect diagnostics

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

## Emacs fails to start

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

## Config changes not taking effect

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

## Keybinding doesn't work

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

## Package install failures

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

## `doom sync` fails or hangs

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

## LSP not working

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

## `void-function` errors

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

## Slow Emacs startup

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

## Missing system dependencies

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

## Font or icon display issues

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

## Emacs hangs or freezes

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

## `doom doctor` warning guide

| Warning text | What it means | Action |
| :--- | :--- | :--- |
| "Couldn't find executable" | A required CLI tool is missing | Install the tool or disable the module |
| "No module flag matches" | `init.el` has a flag that the module doesn't know about | Check the module's README.org and correct the flag |
| "Package is pinned to a version that may not exist" | `:pin` SHA doesn't match upstream | Update the SHA or remove the `:pin` |
| "Recipe error for <package>" | straight can't process the recipe | Check the recipe syntax and the package source |
| "Straight repo is dirty" | Uncommitted changes in a package checkout | `git checkout .` in the repo or re-clone |

## Recovery procedures

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
