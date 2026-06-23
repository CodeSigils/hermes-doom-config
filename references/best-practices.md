# Doom Emacs Best Practices

Consolidated guidance for writing correct, maintainable Doom Emacs config.
Pulls together patterns from DOOM-API.md (performance, style), SKILL.md
(conventions, pitfalls), and AGENTS.md (repo-specific policies) into one
scannable reference.

---

## 1. Macro Decisions — Doom API Over Emacs API

| Doom macro             | Replaces                            | Why prefer it                                                                                    |
| ---------------------- | ----------------------------------- | ------------------------------------------------------------------------------------------------ |
| `use-package!`         | `use-package`                       | Wraps use-package with disabled-package awareness; adds `:after-call` and `:defer-incrementally` |
| `after!`               | `with-eval-after-load` / `require`  | Handles Doom's deferred ordering; never `require` in config                                      |
| `setq!`                | `setq` / `setq-default`             | Triggers custom setters on customizable variables via `set-default-toplevel-value`               |
| `map!`                 | `define-key` / `global-set-key`     | Evil-state aware, which-key descriptions, mode unloading                                         |
| `add-hook!`            | `add-hook` (repeated)               | Multi-mode, local variables, `:append` in one form                                               |
| `setq-hook!`           | `add-hook` + lambda                 | Buffer-local var in a hook, cleaner than a lambda                                                |
| `set-company-backend!` | `setq company-backends`             | Per-mode company backends                                                                        |
| `set-popup-rule!`      | `display-buffer-alist`              | Transient buffer display rules                                                                   |
| `modulep!`             | `(when (require ... nil 'noerror))` | Compile-time check; disabled modules never compiled. Replaces deprecated `featurep!`             |
| `load!`                | `load-file`                         | Relative to the currently executing file (`load-file-name`) — portable, no hardcoded paths       |
| `defadvice!`           | `defun` + `advice-add`              | Named advice with docstring, manageable                                                          |

The ordering principle: **lazy by default**. Every macro choice should defer
loading unless there is a specific reason not to.

---

## 2. Config Hygiene

**Namespace everything.** All custom functions, variables, and private state
use the `user/` prefix (defined in PROFILE.md). Never use bare `my-`, no
prefix at all, or package-internal-looking names.

```elisp
(defun user/my-function () ...)
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

| File               | Purpose                                               | `doom sync` needed? |
| :----------------- | :---------------------------------------------------- | :------------------ |
| `init.el`          | Module declarations only — single `(doom! ...)` form  | Yes                 |
| `packages.el`      | Package declarations via `(package! ...)`             | Yes                 |
| `config.el`        | Thin loader with universal defaults and `load!` calls | Depends on config   |
| `sections/`        | Split config — loaded via `load!` from config.el      | No                  |
| `sections/keys.el` | Centralized keybinding inventory, loaded last         | No                  |

**Splitting rule:** This config already uses a `sections/` split. Put new
settings/hooks/advice in the matching section file under `sections/<topic>.el`
and load any new section from `config.el`. Move every `map!` form to
`sections/keys.el`:

```elisp
(load! "sections/org")
(load! "sections/keys")
```

Each `.el` file must start with a lexical-binding cookie:

```elisp
;;; $DOOMDIR/sections/org.el -*- lexical-binding: t; -*-
```

---

## 4. Startup Performance

> **Note:** The principles below are a compact summary. See
> `DOOM-API.md` section 7.2 for detailed explanations and examples.

- **Defer everything** — Every `use-package!` gets `:defer t` unless the package is needed at startup.
- **Understand implicit deferral** — `:commands`, `:hook`, `:mode`, and `:after` all imply `:defer t`. No need to specify both.
- **Prefer `after!` over `(require '...)`** — `after!` runs when the feature loads; `(require)` force-loads at config time.
- **Use `:commands` for autoloads** — Declare entry-point commands that autoload the package on first use.
- **Use `:hook` in `use-package!`** — Cleaner and more efficient than a separate `(add-hook! ...)` outside the declaration.
- **Keep `:init` blocks lean** — `:init` runs at startup even with `:defer t`. Put expensive setup in `:config` (post-load).
- **Prefer `modulep!` over runtime check** — Compile-time; disabled modules are never compiled, producing zero startup cost.
- **Avoid lambdas in hooks** — `(lambda () ...)` creates a new closure each time the hook runs. Prefer a named function.
- **Bind launcher keys outside `after!`** — `(map! ...)` inside `(after! <pkg> ...)` delays the binding until the package loads.
- **Use `setq-hook!` for buffer-local** — Cleaner than `(add-hook! ... (lambda () (setq-local ...)))`.
- **Guard external tools** — Use `(executable-find ...)` fallback chains before setting browser, formatter, or shell commands.

**Implicit deferral explained:** These `use-package` keywords automatically set
`:defer t` — you don't need to specify both:

```elisp
;; :hook implies :defer t — package loads when the hook triggers
(use-package! rainbow-delimiters
  :hook ((org-mode prog-mode) . rainbow-delimiters-mode))

;; :commands implies :defer t — package loads when the command is first called
(use-package! org-roam-ui
  :commands org-roam-ui-mode)

;; No deferral keyword → package loads at startup
(use-package! some-package
  :config ...)  ; BAD: loads eagerly at startup
```

**External tool fallback pattern:**

```elisp
(setq! browse-url-browser-function 'browse-url-generic
       browse-url-generic-program
       (cond
        ((executable-find "launch-browser") "launch-browser")
        ((executable-find "google-chrome-stable") "google-chrome-stable")
        ((executable-find "/opt/google/chrome/chrome") "/opt/google/chrome/chrome")
        ((executable-find "google-chrome") "google-chrome")))
```

Use this when config references an external binary that may differ across
machines. It avoids hard failures on a fresh install and documents the intended
preference order.

**Hot take:** If you can't justify why a piece of code needs to run at startup,
it shouldn't run at startup.

---

## 5. Code Quality Toolchain

| Tool              | When to Use                                 | What It Catches                                          |
| ----------------- | ------------------------------------------- | -------------------------------------------------------- |
| `check-parens`    | After every `.el` edit                      | Mismatched parentheses                                   |
| `byte-compile`    | Before committing non-trivial `.el` changes | Free variable refs, unused lexical vars, type mismatches |
| `doom doctor`     | After every `doom sync`                     | Config errors, module conflicts, missing binaries        |
| `doom sync`       | After init.el / packages.el changes         | Recompiles, updates autoloads, resolves straight recipes |
| `M-x doom/reload` | After config changes in a running Emacs     | Verifies config loads without restart                    |
| `M-x checkdoc`    | Before submitting package-quality code      | Docstring formatting, missing arguments                  |

**Workflow for any change:**

1. Edit the `.el` file
2. Run `check-parens`
3. If `init.el` or `packages.el`: run `doom sync`
4. Run `doom doctor`
5. Restart or `M-x doom/reload`
6. Commit

---

## 6. Keybinding Conventions

This repo uses the ztlevi-style centralized keybinding pattern: all `map!`
forms live in `sections/keys.el`, loaded last. Package settings stay in their
feature sections; key behavior has one searchable inventory.

**Why centralized keys:**

| Benefit                                                                         | Trade-off                                              |
| ------------------------------------------------------------------------------- | ------------------------------------------------------ |
| One file answers "what key invokes this?"                                       | Feature review checks both section file and keys file  |
| Easier to audit global overrides and leader prefixes                            | Strict config/key co-location is intentionally relaxed |
| `(:map override ...)` and `(:after ... :map ...)` patterns are visible together | `git blame` for a feature may span two files           |

**Rules:**

- Always use `map!` — never `define-key` or `global-set-key`.
- Global bindings use `:leader` (SPC prefix).
- Major-mode bindings use `:localleader` (SPC m prefix).
- Always provide a `:desc` string for leader bindings so which-key remains
  discoverable.
- Build on top of Doom's defaults; only shadow a binding with a deliberate
  reason, and document why in a comment.
- Bind launcher commands outside `after!` so the command can autoload
  immediately.
- Put package keymaps inside the same `map!` form using
  `(:after <pkg> :map <map> ...)`.
- Use `(:map override ...)` for global chords that must win over minor-mode
  maps.
- Do not add broad module/platform binding layers just because another config
  has them. Use conditional bindings only when this repo has a concrete module
  or platform split to support.

**Launcher + package-map example:**

```elisp
;;; $DOOMDIR/sections/keys.el -*- lexical-binding: t; -*-

(map!
 :leader
 :desc "Dirvish dwim" "d d" #'dirvish-dwim

 (:after dirvish
  (:map dirvish-mode-map
   :n "f" #'find-file
   :n "F" #'dirvish-file-info-menu)))
```

**Global override example:**

```elisp
(map!
 (:map override
  "M-q" (if (daemonp) #'delete-frame #'save-buffers-kill-terminal)
  "M-p" #'projectile-find-file))
```

---

## 7. Package Management Principles

| Pattern                                                  | When to Use                                                       |
| -------------------------------------------------------- | ----------------------------------------------------------------- |
| `(package! foo)`                                         | Install from MELPA or ELPA                                        |
| `(package! foo :disable t)`                              | Disable a package that Doom ships enabled                         |
| `(package! foo :recipe (:host github :repo "user/foo"))` | Install from an external git repo                                 |
| `(unpin! foo)`                                           | Unpin a package to get latest (needed when Doom's pin is too old) |

**Never** use `package-install` interactively. Always add `(package! ...)` to
`packages.el`, then run `doom sync`.

See `references/package-management.md` for the full lifecycle reference
(pinning, straight recipes, lockfile troubleshooting).

---

## 8. Repo-Specific Conventions

These are enforced in this config repo and may differ from general Doom
practice:

| Area     | Convention                                                             |
| -------- | ---------------------------------------------------------------------- |
| Markdown | No emoji. Prettier for formatting (`--parser markdown`).               |
| Python   | Ruff for linting and formatting. Mypy for type checking (CI/terminal). |
| Git      | One concern per commit. `git diff --check` before committing.          |
| Scripts  | `grep -E` (ERE), not `-P` (Perl). `grep -F` for fixed strings.         |

---

## 9. Common Pitfalls

- **Using `with-eval-after-load` instead of `after!`** — Use `after!`. It handles Doom's deferred ordering correctly.
- **Using standard `use-package` instead of `use-package!`** — `use-package!` adds disabled-package awareness and extra keywords; the regular `use-package` misses these.
- **Editing `early-init.el` or `~/.emacs.d/init.el`** — Doom manages those. All user config goes in `~/.config/doom/`.
- **Missing lexical-binding cookie on `.el` file** — Add `;;; file.el -*- lexical-binding: t; -*-` as first line.
- **`(setq-default ...)` when `setq!` suffices** — `setq!` triggers custom setters on customizable variables; more efficient than `setopt`. <!-- stale-check: allow -->
- **Deleting `init.el` lines instead of commenting** — Comment them out. The comment documents a considered-and-rejected option.
- **`package-install` interactively** — Always use `(package! ...)` in `packages.el` + `doom sync`.
- **Keybinding inside `after!` for launcher commands** — Bind outside `after!` in `sections/keys.el` so the command is available immediately and can autoload.
- **`require` in config.el** — Use `after!` or `use-package! :init`.
- **Lambda in hook where `setq-hook!` works** — `(setq-hook! 'mode-hook var val)` is cleaner and debuggable.
- **Stale upstream comments recommending vanilla patterns** — Replace or annotate them (e.g. `with-eval-after-load` → `after!`).
- **Format on save after `doom sync` breaks indentation** — Run `M-x doom/reload` after `doom sync` before saving.
- **`(modulep! ...)` guard in a section for a disabled module** — Already wrapped in this config — keep the guard. Code inside won't compile without the module.
- **Package keybindings scattered across feature files** — Keep every `map!` form in `sections/keys.el`; group by package or leader prefix.
- **Hardcoded external binary path** — Use `(executable-find ...)` fallback chains and tolerate missing binaries.
- **Forgetting `:defer t` on `use-package!` without trigger keywords** — Add `:defer t` explicitly if the package has no `:commands`, `:hook`, `:mode`, or `:after` keywords.

---

## 10. Config Splitting Patterns

Research across popular Doom configs reveals two dominant approaches:

Adopt external patterns by fit, not by imitation. From ztlevi, this config uses
only the pieces that reduce local complexity: centralized keys,
`(:map override ...)`, `(:after <pkg> :map <map> ...)`, and `(executable-find
...)` fallback chains. Defer larger-config machinery (`autoload/` directories,
broad module-conditional architecture, platform binding layers, literate config)
until the repo has concrete pressure for it.

### Pattern A: Monolithic with Headers

Doom's creator (hlissner) and most popular configs keep everything in a single
`config.el` with `;;; HEADER` section comments. Works well up to ~300 lines.

**Example:** https://github.com/hlissner/.doom.d (205★, 296-line config.el)

### Pattern B: `load!` File Split

Section files loaded via `(load! ...)` from a thin config.el loader. Two naming
conventions exist:

| Convention  | Example         | Subdirectory?     | Pros                            | Cons                     |
| ----------- | --------------- | ----------------- | ------------------------------- | ------------------------ |
| `+prefix`   | `"+ui"`         | No (flat)         | Shorter names, no mkdir         | Visual noise from `+`    |
| `sections/` | `"sections/ui"` | Yes (`sections/`) | Cleaner `ls`, explicit grouping | Extra mental indirection |

**Real-world example (flat +prefix):**
https://github.com/ztlevi/doom-config (223★)

```elisp
;; From ztlevi's config.el — section files, centralized keys, and global settings
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

The conditional LSP loading above is context, not a recommendation for this
repo today. Use module conditionals when maintaining alternate module stacks;
do not add them proactively.

### Centralized Keys Stay in One File

ztlevi's `+keys.el` is large (431 lines) but valuable: it answers keybinding
questions in one place. This repo adopts the same concept with
`sections/keys.el`:

- All `map!` forms live in `sections/keys.el`
- Load `sections/keys.el` last
- Group by global overrides, leader prefixes, and package maps
- Use `(:after <pkg> :map <map> ...)` inside `map!` for package maps
- Use `(:map override ...)` for high-priority global overrides

This intentionally relaxes strict co-location. The trade-off is worth it when
the question is "what does this key do?" or "which keys shadow Doom defaults?"

### Universal Settings Stay in the Loader

A pattern shared by EVERY config surveyed: the loader (`config.el`) keeps
settings that don't belong to any single section:

- `user-full-name`, `user-mail-address`
- `doom-scratch-buffer-major-mode`
- `confirm-kill-emacs`
- Popup rules (`set-popup-rules!`)
- `custom-set-variables`
- Environment setup (PATH, exec-path)

In ztlevi's config, these sit below the `load!` block. In hlissner's
config, they sit at the top of the monolithic file. Either way, they
live in config.el as universal defaults.

**Rule of thumb for our config:**

- If a setting affects a specific package or mode → put it in that section file
- If a visual setting belongs with font/theme/line-number appearance choices →
  put it in `sections/appearance.el`
- If a setting affects Emacs globally (display-time, exec-path, window
  defaults) → keep it in config.el
- The loader should be thin, not empty — a few universal calls are expected

**Exceptional: incf/decf aliases.** These are a backward-compat workaround
for Jinx, so they belong in the spellcheck section, not the loader. This
was a deliberate decision documented when the sections were created.

### Why Not Literate Config?

Several popular configs (tecosaur 1087★, nmartin84 244★) use org-babel
literate config (`config.org` tangle). Unnecessary here:

- Our config is small enough to read without tangling
- Org-babel hides `git blame` information behind a tangle step
- Agents can't navigate org-babel source blocks as easily as `.el` files
