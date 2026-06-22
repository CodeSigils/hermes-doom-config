# Doom Emacs Best Practices

Consolidated guidance for writing correct, maintainable Doom Emacs config.
Pulls together patterns from DOOM-API.md (performance, style), SKILL.md
(conventions, pitfalls), and AGENTS.md (repo-specific policies) into one
scannable reference.

---

## 1. Macro Decisions — Doom API Over Emacs API

| Doom macro         | Replaces                          | Why prefer it                                                       |
| ------------------ | --------------------------------- | ------------------------------------------------------------------- |
| `use-package!`     | `use-package`                     | Different deferral semantics via straight.el; wrong one causes bugs |
| `after!`           | `with-eval-after-load` / `require`| Handles Doom's deferred ordering; never `require` in config         |
| `setq!`            | `setq` / `setq-default`          | Tracks variables set via Doom's system; handles default semantics   |
| `map!`             | `define-key` / `global-set-key`  | Evil-state aware, which-key descriptions, mode unloading            |
| `add-hook!`        | `add-hook` (repeated)             | Multi-mode, local variables, `:append` in one form                  |
| `setq-hook!`       | `add-hook` + lambda               | Buffer-local var in a hook, cleaner than a lambda                   |
| `set-company-backend!` | `setq company-backends`       | Per-mode company backends                                           |
| `set-popup-rule!`  | `display-buffer-alist`            | Transient buffer display rules                                      |
| `featurep!`        | `(when (require ... nil 'noerror))`| Compile-time check; disabled modules never compiled                 |
| `load!`            | `load-file`                       | Relative to `doom-user-dir` — portable, no hardcoded paths          |
| `defadvice!`       | `defun` + `advice-add`           | Named advice with docstring, manageable                             |

The ordering principle: **lazy by default**. Every macro choice should defer
loading unless there is a specific reason not to.

---

## 2. Config Hygiene

**Namespace everything.** All custom functions, variables, and private state
use the `sand/` prefix (defined in PROFILE.md). Never use bare `my-`, no
prefix at all, or package-internal-looking names.

```elisp
(defun sand/my-function () ...)
(setq sand-my-var t)
```

**Guard optional integrations.** When enabling a minor mode or calling a
function from an optional package, wrap it in `fboundp`:

```elisp
(when (fboundp 'org-roam-db-autosync-mode)
  (org-roam-db-autosync-mode))
```

This lets the file byte-compile cleanly even when the package isn't loaded.

**Comment, never delete.** In `init.el`, disabled modules stay as comments.
The comment IS documentation — it tells the next reader "this was considered
and turned off." Same principle applies to any config line that represents
a choice, not a mistake.

**One concern per edit.** Don't fix two unrelated things in the same commit.
Adding a package and fixing a keybinding are separate changes.

**Keep global defaults global.** `delete-by-moving-to-trash` and similar
broad preferences belong in the main defaults section, not inside package
blocks. Only override at the package level when a package needs a different
value.

---

## 3. File Organization

| File            | Purpose                                                 | `doom sync` needed? |
| :-------------- | :------------------------------------------------------ | :------------------ |
| `init.el`       | Module declarations only — single `(doom! ...)` form    | Yes                 |
| `packages.el`   | Package declarations via `(package! ...)`               | Yes                 |
| `config.el`     | Settings, keybinds, hooks, advice, custom functions     | Depends on config   |
| `sections/`     | Split config (see SECTIONS_PLAN.md) — loaded via `load!`| No                  |

**Splitting rule:** When a topic block in `config.el` exceeds ~50 lines,
split it into a section file under `sections/<topic>.el` and load it from
`config.el`:

```elisp
(load! "sections/org")
```

Each `.el` file must start with a lexical-binding cookie:

```elisp
;;; $DOOMDIR/sections/org.el -*- lexical-binding: t; -*-
```

---

## 4. Startup Performance

| Principle                            | Practice                                                                                         |
| ------------------------------------ | ------------------------------------------------------------------------------------------------ |
| Defer everything                     | Every `use-package!` gets `:defer t` unless the package is needed at startup                    |
| Prefer `after!` over `(require '...)` | `after!` runs when the feature loads; `(require)` force-loads at config time                    |
| Use `:commands` for autoloads        | Declare entry-point commands that autoload the package on first use                             |
| Use `:hook` in `use-package!`        | Cleaner and more efficient than a separate `(add-hook! ...)` outside the declaration             |
| Keep `:init` blocks lean             | `:init` runs at startup even with `:defer t`. Put expensive setup in `:config` (post-load)       |
| Prefer `featurep!` over runtime check| Compile-time — disabled modules are never compiled, producing zero startup cost                  |
| Avoid lambdas in hooks               | `(lambda () ...)` creates a new closure each time the hook runs. Prefer a named function         |
| Bind launcher keys outside `after!`  | `(map! ...)` inside `(after! <pkg> ...)` delays the binding until the package loads             |
| Use `setq-hook!` for buffer-local    | Cleaner than `(add-hook! ... (lambda () (setq-local ...)))`                                     |

**Hot take:** If you can't justify why a piece of code needs to run at startup,
it shouldn't run at startup.

---

## 5. Code Quality Toolchain

| Tool              | When to Use                                  | What It Catches                                                 |
| ----------------- | -------------------------------------------- | --------------------------------------------------------------- |
| `check-parens`    | After every `.el` edit                       | Mismatched parentheses                                          |
| `byte-compile`    | Before committing non-trivial `.el` changes  | Free variable refs, unused lexical vars, type mismatches        |
| `doom doctor`     | After every `doom sync`                      | Config errors, module conflicts, missing binaries               |
| `doom sync`       | After init.el / packages.el changes          | Recompiles, updates autoloads, resolves straight recipes        |
| `M-x doom/reload` | After config changes in a running Emacs      | Verifies config loads without restart                           |
| `M-x checkdoc`    | Before submitting package-quality code       | Docstring formatting, missing arguments                         |

**Workflow for any change:**
1. Edit the `.el` file
2. Run `check-parens`
3. If `init.el` or `packages.el`: run `doom sync`
4. Run `doom doctor`
5. Restart or `M-x doom/reload`
6. Commit

---

## 6. Keybinding Conventions

- **Place bindings in the config section they modify** — an Org keybinding goes
  in the Org section of `config.el` (or `sections/org.el` post-split), not in a
  centralized keybinding file. This keeps related config together and makes
  `git blame` tell you why a binding exists.
- **Build on top of Doom's defaults; do not replace them.** Only shadow a
  binding when you have a deliberate reason, and document why in a comment.
  Doom ships carefully chosen defaults — overriding them without understanding
  the trade-off creates a maintenance burden on upgrade.
- Always use `map!` — never `define-key` or `global-set-key`.
- Global bindings use `:leader` (SPC prefix).
- Major-mode bindings use `:localleader` (SPC m prefix).
- Always provide a `:desc` string for which-key discoverability.
- For commands meant to run immediately, bind outside `after!` (both belong in
  the same config section, alongside the package config they modify):

```elisp
;;; Dirvish section — binding + config live here, not in a separate keybindings file
(map! :leader :desc "Dirvish dwim" "d d" #'dirvish-dwim)  ; outside after! — autoloads
(after! dirvish
  (setq dirvish-attributes '(vc-state nerd-icons ...)))
```

---

## 7. Package Management Principles

| Pattern                                                   | When to Use                                                       |
| --------------------------------------------------------- | ----------------------------------------------------------------- |
| `(package! foo)`                                          | Install from MELPA or ELPA                                       |
| `(package! foo :disable t)`                               | Disable a package that Doom ships enabled                        |
| `(package! foo :recipe (:host github :repo "user/foo"))`  | Install from an external git repo                                |
| `(unpin! foo)`                                            | Unpin a package to get latest (needed when Doom's pin is too old)|

**Never** use `package-install` interactively. Always add `(package! ...)` to
`packages.el`, then run `doom sync`.

See `references/package-management.md` for the full lifecycle reference
(pinning, straight recipes, lockfile troubleshooting).

---

## 8. Repo-Specific Conventions

These are enforced in this config repo and may differ from general Doom
practice:

| Area     | Convention                                                                 |
| -------- | -------------------------------------------------------------------------- |
| Markdown | No emoji. Prettier for formatting (`--parser markdown`).                   |
| Python   | Ruff for linting and formatting. Mypy for type checking (CI/terminal).    |
| Git      | One concern per commit. `git diff --check` before committing.              |
| Scripts  | `grep -E` (ERE), not `-P` (Perl). `grep -F` for fixed strings.            |

---

## 9. Common Pitfalls

| Pitfall                                                           | Fix                                                                                          |
| ----------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| Using `with-eval-after-load` instead of `after!`                  | Use `after!` — handles Doom's deferred ordering correctly                                    |
| Using standard `use-package` instead of `use-package!`            | Note the trailing `!` — different deferral semantics                                         |
| Editing `early-init.el` or `~/.emacs.d/init.el`                   | Doom manages those. All user config goes in `~/.config/doom/`                                |
| Missing lexical-binding cookie on `.el` file                      | Add `;;; file.el -*- lexical-binding: t; -*-` as first line                                 |
| `(setq-default ...)` when `setq!` suffices                        | Doom handles default-value semantics internally — use `setq!`                                |
| Deleting `init.el` lines instead of commenting                    | Comment them out — the comment documents a considered-and-rejected option                   |
| `package-install` interactively                                   | Always use `(package! ...)` in `packages.el` + `doom sync`                                  |
| Keybinding inside `after!` for launcher commands                  | Bind outside `after!` so the command is available immediately and can autoload               |
| `require` in config.el                                            | Use `after!` or `use-package! :init`                                                        |
| Lambda in hook where `setq-hook!` works                           | `(setq-hook! 'mode-hook var val)` is cleaner and debuggable                                 |
| Stale upstream comments recommending vanilla patterns             | Replace or annotate them — e.g. `with-eval-after-load` → `after!`                           |
| Format on save after `doom sync` breaks indentation               | Run `M-x doom/reload` after `doom sync` before saving                                       |
| `(featurep! ...)` guard in navigation section for disabled module | Already wrapped in this config — keep the guard. Code inside won't compile without the module |

---

## 10. Config Splitting Patterns

Research across popular Doom configs reveals two dominant approaches:

### Pattern A: Monolithic with Headers

Doom's creator (hlissner) and most popular configs keep everything in a single
`config.el` with `;;; HEADER` section comments. Works well up to ~300 lines.

**Example:** https://github.com/hlissner/.doom.d (205★, 296-line config.el)

### Pattern B: `load!` File Split

Section files loaded via `(load! ...)` from a lean config.el. Two naming
conventions exist:

| Convention | Example | Subdirectory? | Pros | Cons |
| ---------- | ------- | ------------- | ---- | ---- |
| `+prefix`  | `"+ui"` | No (flat)     | Shorter names, no mkdir | Visual noise from `+` |
| `sections/`| `"sections/ui"` | Yes (`sections/`) | Cleaner `ls`, explicit grouping | Extra mental indirection |

**Real-world example (flat +prefix):**
https://github.com/ztlevi/doom-config (223★)

```elisp
;; From ztlevi's config.el — 7 load! calls + global settings
(load! "+os")
(load! "+git")
(load! "+misc")
(load! "+text")
(load! "+prog")
(load! "+ui")
(load! "+keys")
;; Conditional section — only loads if the module is enabled
(cond
 ((modulep! :tools lsp +eglot) (load! "+eglot"))
 ((modulep! :tools lsp) (load! "+lsp")))
```

### Universal Settings Stay in the Loader

A pattern shared by EVERY config surveyed: the loader (`config.el`) keeps
settings that don't belong to any single section:

- `user-full-name`, `user-mail-address`
- `doom-scratch-buffer-major-mode`
- `confirm-kill-emacs`
- `display-line-numbers-type`
- Popup rules (`set-popup-rules!`)
- `custom-set-variables`
- Environment setup (PATH, exec-path)

In ztlevi's config, these sit below the `load!` block. In hlissner's
config, they sit at the top of the monolithic file. Either way, they
live in config.el as universal defaults.

**Rule of thumb for our config:**
- If a setting affects a specific package or mode → put it in that section file
- If a setting affects Emacs globally (display-time, exec-path, window
  defaults) → keep it in config.el (or sections/defaults.el)
- The loader should be thin, not empty — a few universal calls are expected

**Exceptional: incf/decf aliases.** These are a backward-compat workaround
for Jinx, so they belong in the spellcheck section, not the loader. This
was a deliberate decision documented in the plan (SECTIONS_PLAN.md).

### Why Not Literate Config?

Several popular configs (tecosaur 1087★, nmartin84 244★) use org-babel
literate config (`config.org` tangle). Unnecessary here:
- Our config is small enough to read without tangling
- Org-babel hides `git blame` information behind a tangle step
- Agents can't navigate org-babel source blocks as easily as `.el` files

---

## Cross-References

| For deeper coverage                         | See                                                     |
| ------------------------------------------- | ------------------------------------------------------- |
| Doom macro syntax with examples             | `DOOM-API.md`                                           |
| Package lifecycle (pinning, straight)       | `references/package-management.md`                      |
| Agent workflow and drift prevention         | `AGENTS.md`                                             |
| Config profile (enabled modules, packages)  | `PROFILE.md`                                            |
| General Doom guide plus troubleshooting     | `.agents/skills/doom-emacs/SKILL.md`                    |
| Task-specific procedures                    | `.agents/skills/doom-emacs/domains/PROCEDURES.md`       |
| Troubleshooting diagnostics                 | `.agents/skills/doom-emacs/domains/TROUBLESHOOTING.md`  |
| Emacs Lisp for Doom config                  | `.agents/skills/doom-emacs/domains/ELISP.md`            |
| Doom framework architecture                 | `.agents/skills/doom-emacs/domains/ARCHITECTURE.md`     |
| External resources and community configs    | `references/INDEX.md`                                   |
