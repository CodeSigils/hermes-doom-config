# Troubleshooting Doom Emacs

Full diagnostic guide. Read this only when something breaks — it is the longest domain file.

**Parent skill:** `SKILL.md` — compact core with file roles, API essentials, safety checks, pitfalls, and the Quick
Index for all domain files. Load SKILL.md first for the minimal context every Doom edit needs.

**Siblings:** `ARCHITECTURE.md`, `ELISP.md`, `PROCEDURES.md`, `TROUBLESHOOTING.md` — depth guides for framework,
elisp, procedures, and troubleshooting.

## Before you troubleshoot — collect diagnostics

When something breaks, gather this information before changing anything:

- **`doom info`** — prints version, system info, load path, startup time. Essential for any bug report or investigation.
- **`*doom*` buffer** — check for recipe errors, compile warnings, module flag problems after the last `doom sync`.
- **`*Messages*` buffer** (`C-h e`) — shows runtime errors, eval output, and Emacs-init messages. Start here after an
  error happens during use.
- **`emacs --debug-init`** from the terminal — shows a full stack trace at init time, bypassing Emacs as a daemon so you
  see every error.
- **What changed last?** The most common cause of a new problem is the last change. If Emacs worked before a
  `doom sync`, a `doom upgrade`, or an edit to `init.el`/`config.el`/`packages.el`, start there.

## Emacs fails to start

| Symptom                                        | Likely cause                                              | Fix                                                                        |
| :--------------------------------------------- | :-------------------------------------------------------- | :------------------------------------------------------------------------- |
| Blank screen, Emacs exits immediately          | Unbalanced parens or syntax error in a `.el` file         | `emacs --debug-init` to locate the error; `check-parens` on affected files |
| Error mentions a specific file or line         | An error in that file at that line                        | Inspect the file around that line, check recent edits                      |
| Error is a missing function or variable        | A `require` or autoload is failing                        | The stack trace shows what Emacs tried to load and where                   |
| Error about `void-variable` or `void-function` | A referenced symbol doesn't exist, or load order is wrong | Check module guards, package availability, and load order                  |
| Error about an unknown module flag             | Typo or removed flag in `init.el`                         | Check the module's README.org for valid flags                              |
| Emacs starts but shows nothing useful          | The daemon started but GUI/X11 failed                     | Run `emacs --no-window-system` or `emacs -nw` to force terminal mode       |

Steps:

1. **`emacs --debug-init`** from the terminal. The stack trace identifies the offending file, line, and symbol. Read it
   from bottom to top — the first error is at the bottom.
2. **Check parens.** A missing paren is the most common cause:
   ```sh
   emacs --batch path/to/affected-file.el --eval '(check-parens)'
   ```
   or from inside Emacs: `M-x check-parens`
3. **Check `*doom*`** for compile warnings after a `doom sync`.
4. **Isolate.** Comment out recent additions in blocks, re-test with `emacs --debug-init`, repeat until the error
   disappears. The last block you commented is the cause.
5. **`doom doctor`** after Emacs starts — catches module flag mismatches and missing system deps that may cause
   secondary failures.

## Config changes not taking effect

| Change in     | Required action                     | Typical mistake                                  |
| :------------ | :---------------------------------- | :----------------------------------------------- |
| `init.el`     | `doom sync` then restart            | Running `doom/reload` instead of `doom sync`     |
| `packages.el` | `doom sync` then restart            | Running `package-install` instead of `doom sync` |
| `config.el`   | `doom sync`, then reload or restart | Syncing without reloading the running session    |
| Snippet file  | Save file, no Emacs restart needed  | Unclear; check `SPC h i` in the target mode      |

Verify with:

- `C-h v <variable-name>` — shows the current runtime value
- `C-h m` — lists active minor modes in the current buffer
- `M-x describe-mode` — describes the current major mode and its keybindings
- If a value still shows the old setting after reload, the `setq` may be in a `after!` block that hasn't triggered yet,
  or is overridden later in config.el

**Troubleshooting `M-x doom/reload` from terminal:** If `emacsclient -e '(doom/reload)'` fails with "emacsclient: can't
find socket; have you started the server?", no Emacs server is running. This is not a config failure — tell the user to
restart Emacs or run `M-x doom/reload` from inside Emacs.

## Keybinding doesn't work

- **`C-h k <key-sequence>`** — tells you what command the key sequence runs. If it says "is undefined", the binding was
  never set or was overridden.
- **`C-h w <command>`** — tells you what keys are bound to a command.
- **Check evil state.** `:n` bindings only work in normal mode. `:i` bindings only work in insert mode. If you're in the
  wrong state, the binding is invisible.
- **Check mode-specific maps.** A binding in `org-mode-map` doesn't apply in `prog-mode`. Use `C-h b` to see all
  bindings active in the current buffer.
- **Check load order.** If the binding is inside `(after! <pkg> ...)`, it doesn't take effect until that package loads.
  For launcher commands, bind outside `after!`.
- **Run `doom sync` and restart.** If the binding still doesn't appear, verify the key sequence isn't consumed by
  another prefix: `C-h k <partial-seq>` to see what the prefix is bound to.

## Package install failures and sync errors

Run `doom doctor`, inspect the exact error and `*doom*` or `*Messages*`, and
check the affected package recipe and checkout. A dirty checkout may contain
work that must be preserved. For package recovery and the distinction between
sync, update, and rebuild, see `references/package-management.md`.

If a sync hangs, inspect the log and any credential prompt before stopping it.
Consult the installed `doom help sync` for debugging options.

## LSP not working

- **`M-x eglot-reconnect`** — reconnects the LSP session without closing files.
- **`M-x eglot-shutdown-all`** then re-open the file — forces a fresh session.
- **Verify the language server in Emacs** — evaluate `(executable-find "server-name")` with `M-:` in the affected
  session. Compare with `command -v server-name` in the shell; GUI sessions can have a different `exec-path`. Inspect
  `eglot-server-programs` with `C-h v` to find the configured server and arguments for the major mode.
- **Inspect a failed server process** — read its Eglot stderr buffer and `*Messages*`. A server may exist on the path
  yet fail because its runtime or a package dependency is missing. Compare the selected executable and its install
  layout before changing package managers; see `references/environment-setup.md` for the observed YAML example.
- **Run `doom doctor`** — verifies that the LSP module has no flag conflicts. If `(python +lsp)` is enabled but
  `(lsp +eglot)` isn't, LSP won't work.
- **Check `M-x eglot-events-buffer`** — shows protocol events when event logging is enabled. This Doom setup disables
  the event buffer by default; enable logging temporarily when needed, then reconnect.

## Workflow smoke checks

Run checks for the workflows affected by a change in a running Doom session. Use disposable files and record the
date, relevant versions, test surface and observed result, including missing dependencies or any check that could not
be performed. Executable lookup, a server connection, and an actual workflow are separate observations.

- **Completion and LSP:** open a Python, shell, or YAML project file; verify Eglot connects when a server is installed,
  then invoke completion and check for a relevant candidate. Use the LSP steps above for connection failures.
- **Markdown path completion:** in a disposable Markdown file, check `major-mode` and buffer-local `company-backends`,
  then try an existing path in prose, inline code, a fenced block, and a link destination. Confirm the file backend
  offers the expected candidate; a configured backend alone does not prove runtime completion works.
- **Formatting:** save disposable Python and Markdown files with visibly unformatted content; verify Ruff and Prettier
  respectively format them. Check `executable-find` and formatter errors if the content does not change.
- **Spelling:** in a text buffer, check that Jinx marks a misspelling and offers a correction. Check both configured
  dictionaries when relevant; see `references/jinx.md` for dictionary verification.
- **Org-roam:** open or create a disposable node and confirm it can be found after the database sync. Do not alter
  existing notes solely for a smoke check.
- **Markdown preview:** open a disposable Markdown file with `markdown-open` and confirm rendered content opens in the
  configured browser. This requires the Markdown compiler and a graphical browser.
- **Frame geometry:** resize a graphical frame, exit normally, and restart; confirm its restored dimensions are close
  to the previous size. Window-manager constraints can affect the exact result.

In an isolated Doom session checked 2026-11-26, `company-files` offered paths in
fenced Markdown blocks but did not recognize paths immediately after an inline
backtick or `](`. Its prefix also treated the closing delimiter as a suffix to
replace. `sections/completion.el` adds Markdown-specific matching and preserves
those delimiters; recheck against the installed Company source after upgrades.
Automatic completion and candidate insertion were exercised in Markdown and GFM
buffers, but this does not establish behavior in every Markdown context.

## Org-roam note not found

First check the note's path against the running session's `org-roam-directory`, and inspect
`org-roam-db-autosync-mode` and `*Messages*`. A file existing on disk does not prove it is indexed, and a search can
miss a node for reasons other than database failure. If needed, reproduce with a disposable note and an isolated
directory and database; do not sync, rebuild, or delete the user's database as an initial diagnostic. Consult the
installed Org-roam documentation before choosing any recovery action.

## `void-function` errors

A `void-function` error means Emacs tried to call a function that isn't defined at runtime. The bytecode was compiled
against a definition that is no longer available.

- **Common cause:** the package calls legacy Emacs functions removed in newer Emacs versions. Example: bare
  `incf`/`decf` in Jinx 2.7 — Emacs 30 only provides the `cl-lib` names (`cl-incf`/`cl-decf`). Jinx also requires
  compat 31 for `completion-table-with-metadata`, so Doom's older compat pin can break correction UI commands with
  `(void-function completion-table-with-metadata)`.

- For this configuration's aliases, compat pin, dependencies and verification,
  see `references/jinx.md`, `sections/spellcheck.el`, and `packages.el`. Recheck
  installed package versions before changing the workaround.

## Slow Emacs startup

| Symptom                       | Likely cause                       | Fix                                                |
| :---------------------------- | :--------------------------------- | :------------------------------------------------- |
| Startup feels slow            | Several possible causes            | Measure startup before choosing a change           |
| A package takes long to load  | Expensive loading or configuration | Profile it; defer only with an appropriate trigger |
| Startup slow only in GUI      | Font or tooltip initialization     | Check font cache, disable unneeded UI features     |
| Startup slow only in terminal | Frame initialization differences   | Check for terminal-specific config that waits on X |

Steps:

- **`doom info`** includes a "Startup time" section with per-phase timing.
- **`benchmark-init`** — enable in init.el for a detailed report of which packages contribute to startup time. Not
  installed by default.
- **`M-x profiler-start`** then **`M-x profiler-report`** after startup identifies expensive operations during use.
- **Check loading triggers** — defer work where appropriate, and verify a hook,
  command, or other trigger still loads the package when it is needed.
- **Verify `lexical-binding: t`** in runtime config files — dynamic binding can limit compiler optimizations and increase memory per
  buffer.

## Missing system dependencies

`doom doctor` reports most missing dependencies, but not all are obvious:

- **Language servers** for LSP modules — install via the system package manager (`pip`, `npm`, `apt`, `brew` depending
  on the server).
- **Spell checking** — Jinx needs Enchant and a dictionary. See `references/jinx.md` in the config checkout for dependencies.
- **PDF tools** — the `:tools pdf` module needs `pdf-tools` epdfinfo compiled (done by `doom sync` if the build
  toolchain is present).
- **Docker, direnv** — CLI tools must be on `$PATH`. `doom doctor` checks these but the error message says "not found"
  rather than "install this."

Verify with: `doom doctor` — run it after any `doom sync` and check the warnings section. A green check means passing; a
yellow warning means a missing dep that may affect that module's feature.

## Font or icon display issues

- **Box characters or missing icons** (`\xf026`-like display) — all-the-icons or nerd-icons font not installed. Run
  `M-x all-the-icons-install-fonts` or `M-x nerd-icons-install-fonts`. On Linux, this copies the font to
  `~/.local/share/fonts/`, followed by `fc-cache -f`.
- **Modeline shows `X` instead of icons** — same cause. Reinstall fonts and restart Emacs.
- **Font size too large/small in GUI** — set the default font in `config.el` via `(set-fontset-font ...)` or customize
  `doom-font`.
- **CJK or special characters render as blank** — a font with those glyphs isn't configured. Use `set-fontset-font` in
  `config.el` to specify fallback fonts.

## Emacs hangs or freezes

- **Infinite loop in a hook or mode.** `M-x toggle-debug-on-quit` then press `C-g` — the debugger shows what Emacs is
  executing when you quit.
- **LSP session stuck.** `M-x eglot-shutdown-all` to kill all LSP processes.
- **Process not responding.** `M-x list-processes` (`C-h p`) to see running subprocesses. Kill stuck ones with `k`.
- **Hang on file open.** Tramp or a file watcher may be waiting on a remote connection. Check `*tramp/...*` buffers.
- **Profiler can identify the culprit.** `M-x profiler-start` before the operation, `M-x profiler-report` after. If you
  can't start the profiler before the hang, start it on next Emacs start and reproduce.

## `doom doctor` warning guide

| Warning text                                        | What it means                                           | Action                                                |
| :-------------------------------------------------- | :------------------------------------------------------ | :---------------------------------------------------- |
| "Couldn't find executable"                          | A required CLI tool is missing                          | Install the tool or disable the module                |
| "No module flag matches"                            | `init.el` has a flag that the module doesn't know about | Check the module's README.org and correct the flag    |
| "Package is pinned to a version that may not exist" | `:pin` SHA doesn't match upstream                       | Update the SHA or remove the `:pin`                   |
| "Recipe error for <package>"                        | straight can't process the recipe                       | Check the recipe syntax and the package source        |
| "Straight repo is dirty"                            | Uncommitted changes in a package checkout               | Inspect and preserve changes before deciding recovery |

## Recovery procedures

After a failed upgrade, inspect the config and Doom checkout status, logs, and
available backups. Identify the exact pre-upgrade revision and any local work
before proposing recovery. A reflog entry is not automatically that revision;
do not reset, overwrite, or delete changes without explicit authorization.

For package-specific sync, rebuild, and recovery choices, see
`references/package-management.md`. After an authorized config recovery, follow
`AGENTS.md` for sync and doctor, then reload or restart the running session.
