# DOOM-API — The Doom Way

Purpose: teach an agent how to think in Doom Emacs conventions. This is not a
syntax dump — it is a decision guide with rationales. Every config in this repo
should follow these patterns unless PROFILE.md or AGENTS.md overrides for a
specific case.

---

## 1. Doom's Design Philosophy (Why It Works)

Doom wraps Emacs with conventions that make config maintainable, composable, and
lazy. Understanding these axioms explains almost every macro decision below:

| Axiom                        | Meaning                                                                                  |
| ---------------------------- | ---------------------------------------------------------------------------------------- |
| Lazy by default              | Nothing loads until needed. `use-package! :defer t` is the default stance                |
| Declarative over imperative  | Say _what_ a package does, not _how_ to set it up                                        |
| Composability through macros | `after!`, `map!`, `add-hook!` compose across files without conflict                      |
| Stable pinned base           | Doom pins all packages. Unpin only when upstream moves faster than Doom                  |
| Doom API > Emacs API         | Always prefer Doom's macro (`use-package!`, `after!`, `setq!`) over the Emacs equivalent |

An agent that internalizes these five axioms will make correct Doom decisions
even without looking up every macro.

---

## 2. The Core Macros (Learn These First)

These are the macros you reach for in every config edit. The order below is
frequency of use.

### `use-package!` — Configure a Package

Doom's version of `use-package` (note the trailing `!`). A thin wrapper around `use-package` that adds disabled-package awareness
and two extra keywords (`:after-call`, `:defer-incrementally`). Use for _any_ package
that needs setup beyond defaults.

```elisp
(use-package! foo
  :defer t               ; don't load at startup
  :hook (mode . func)    ; attach function to major-mode hook
  :init                  ; code that runs before the package loads
  :config                ; code that runs after the package loads
  :commands my-cmd       ; autoload on first invocation
  :after other-pkg)      ; wait for another package before loading
```

**Do NOT** use the standard `use-package` from MELPA — Doom's `use-package!`
adds disabled-package awareness and extra keywords; the regular `use-package`
misses these.

### `after!` — Defer Config After Something Loads

The replacement for `with-eval-after-load`. It handles package ordering
correctly and supports multiple features.

```elisp
(after! org
  (setq org-adapt-indentation nil))

(after! (org company)   ; wait for BOTH to load
  (do-something))
```

**When to reach for it:** When you need to set a variable that belongs to a
package. If you're writing config for a package, wrap it in `(after! <package> ...)`.
The only exception is variables that must be set before load — those go in
`use-package! :init`.

### `map!` — Keybinding

Doom's keybinding system. Supports evil states, which-key descriptions, and
mode-specific maps.

```elisp
(map! :leader :desc "Find file" "f f" #'find-file)
(map! :n "C-c C-f" #'foo-command)             ; normal mode only
(map! :map org-mode-map :n "RET" #'org-open-at-point)
```

| Prefix         | Scope                                 |
| -------------- | ------------------------------------- |
| `:leader`      | `SPC` (evil) or `M-m`                 |
| `:localleader` | `SPC m` (major-mode prefix)           |
| `:n`           | Normal mode only                      |
| `:i`           | Insert mode only                      |
| `:v`           | Visual mode only                      |
| `:m`           | Motion mode only                      |
| `:map KEYMAP`  | Specific keymap (e.g. `org-mode-map`) |

**When to use:** Always prefer `map!` over `define-key` or `global-set-key`.
`map!` handles evil state awareness, which-key descriptions, and mode
unloading automatically.

### `add-hook!` — Multi-Mode Hook Attachment

```elisp
(add-hook! 'prog-mode-hook #'rainbow-delimiters-mode)
(add-hook! '(org-mode-hook markdown-mode-hook) #'flyspell-mode)
(add-hook! 'org-mode-hook (setq-local truncate-lines nil) nil nil)
```

Supports multiple hooks in one form, local variable setting, and `:append`
position flag. Simpler than writing separate `add-hook` calls.

### `setq!` — Safe Variable Setting

Doom's wrapper around `setq` that triggers custom setters on customizable
variables via `set-default-toplevel-value`. More efficient than `setopt`. <!-- stale-check: allow -->

```elisp
(setq! delete-by-moving-to-trash t
       scroll-margin 0)
```

Use `setq!` instead of `setq` or `setq-default` in `config.el`. Doom handles
the default-value semantics internally.

### `set-company-backend!` — Per-Mode Completion

```elisp
(set-company-backend! 'org-mode
  'company-files
  '(company-capf :with company-yasnippet)
  'company-dabbrev)
```

Backends are tried in order. `:with` means "enrich the primary backend."
`:separate` means "try each independently."

### `set-popup-rule!` — Transient Buffer Display

```elisp
(set-popup-rule! "^\\*Help\\*" :size 0.35 :ttl 0 :quit t :select nil)
```

Parameters: `:size` (fraction or rows), `:ttl` (0 = forever), `:quit` (q to
quit), `:select` (auto-select), `:side` (bottom/left/right/top), `:slot`.

**Important:** Match buffer names with a regex. `"^\\*"` captures every star
buffer — too broad. Prefer specific names like `"^\\*Help\\*"`.

### `modulep!` — Compile-Time Module Check (replaces deprecated `featurep!`)

```elisp
(when (modulep! :ui popup)
  (set-popup-rule! ...))
```

This is evaluated at compile time, not runtime. Code inside a `modulep!` block
for a disabled module is never compiled. Use when you need conditional config
that depends on whether a module is enabled.

### `setq-hook!` — Hook-Local Variable

```elisp
(setq-hook! 'org-mode-hook truncate-lines nil)
```

Cleaner than writing `(add-hook! 'org-mode-hook (lambda () (setq-local ...)))`.

---

## 3. The Module System

### How `doom!` Works

`init.el` contains a single `(doom! ...)` form with modules grouped by category
in alphabetical order. Each module can have flags (`+keyword`).

```elisp
(doom!
  :completion
  (company +childframe +tng)
  ;;corfu

  :ui
  doom
  doom-dashboard)
```

**Rules:**

- One module per line under its category header
- Categories appear in a fixed order (completion, ui, editor, emacs, term,
  checkers, tools, os, lang, email, app, config)
- Comment disabled modules — never delete them (the comment IS documentation)
- Flags are `+keyword` suffixes; not all modules support flags

### How Flags Work

Flags parametrize a module. They are defined as files inside the module
directory: `~/.config/emacs/modules/<category>/<module>/+<flag>.el`.

In `init.el`, put cursor on a flag and press `K` for docs or `gd` to jump
to its definition.

Common flags used in this config:

| Module               | Flag          | Effect                                   |
| -------------------- | ------------- | ---------------------------------------- |
| `company`            | `+childframe` | Display completions in a childframe      |
| `company`            | `+tng`        | Tab-and-go: Tab completes, Enter selects |
| `org`                | `+roam`       | Enable org-roam (knowledge base)         |
| `org`                | `+dragndrop`  | Drag-and-drop images into org buffers    |
| `lsp`                | `+eglot`      | Use eglot backend (not lsp-mode)         |
| `format`             | `+onsave`     | Auto-format on save                      |
| `dired`              | `+icons`      | Icons in dired                           |
| `dired`              | `+dirvish`    | Dirvish sidebar replacement              |
| `popup`              | `+all`        | Enable all built-in popup rules          |
| `popup`              | `+defaults`   | Enable default popup rules               |
| `vc-gutter`          | `+pretty`     | Prettier fringe indicators               |
| `(evil +everywhere)` | `+everywhere` | Evil in non-programming buffers          |

### Module Categories (the 13 groups)

| Category      | What Goes There                                         |
| ------------- | ------------------------------------------------------- |
| `:input`      | Input methods (bidi, CJK)                               |
| `:completion` | Company, corfu, vertico, helm, ivy                      |
| `:ui`         | Visual layer — modeline, tabs, popups, doom look        |
| `:editor`     | Evil, snippets, format, fold, word-wrap                 |
| `:emacs`      | Built-in Emacs app improvements — dired, ibuffer, tramp |
| `:term`       | Terminal emulators — vterm, eshell, shell               |
| `:checkers`   | Syntax, spell, grammar checkers                         |
| `:tools`      | LSP, magit, lookup, direnv, docker, debugger            |
| `:os`         | OS-specific (macos, tty)                                |
| `:lang`       | Language support — one module per language              |
| `:email`      | Email clients — mu4e, notmuch                           |
| `:app`        | Extra apps — calendar, emms, irc, rss                   |
| `:config`     | default (+bindings +smartparens), literate              |

---

## 4. Package Management

Doom uses `straight.el` under the hood. The `package!` macro in `packages.el`
wraps straight's recipe format.

| Pattern                                                  | When to Use                                                       |
| -------------------------------------------------------- | ----------------------------------------------------------------- |
| `(package! foo)`                                         | Install from MELPA or ELPA                                        |
| `(package! foo :disable t)`                              | Disable a package that Doom ships enabled                         |
| `(package! foo :recipe (:host github :repo "user/foo"))` | Install from an external git repo                                 |
| `(unpin! foo)`                                           | Unpin a package to get latest (needed when Doom's pin is too old) |

**Important:** Never use `package-install` interactively in this config.
Always add a `(package! ...)` form to `packages.el`, then run `doom sync`.

See `packages.el` for this config's unpinned packages and their reasons.

---

## 5. File Organization

| File               | What Goes Here                                        | `doom sync`?            |
| ------------------ | ----------------------------------------------------- | ----------------------- |
| `init.el`          | Module declarations only                              | Yes                     |
| `config.el`        | Thin loader with universal defaults and `load!` calls | This config prefers yes |
| `sections/*.el`    | Per-feature settings, hooks, advice, custom functions | This config prefers yes |
| `sections/keys.el` | Centralized `map!` keybinding inventory, loaded last  | This config prefers yes |
| `packages.el`      | Package declarations                                  | Yes                     |

This config uses topic files under `sections/`, loaded from the thin
`config.el` loader. Add new per-feature settings/hooks/advice to the matching
section file and register new sections with `(load! ...)`:

```elisp
(load! "sections/org")
(load! "sections/completion")
(load! "sections/keys")
```

---

## 6. Reload Without Restarting

Doom runs an Emacs server by default.

| Action            | Command                                                       |
| ----------------- | ------------------------------------------------------------- |
| Inside Emacs      | `M-x doom/reload`                                             |
| From terminal     | `emacsclient -e '(doom/reload)'`                              |
| After `doom sync` | `doom/reload` last to avoid format-on-save indentation issues |

---

## 7. Performance and Best Practices

> **Consolidated reference:** `references/best-practices.md` collects the
> guidance in this section plus conventions from SKILL.md and AGENTS.md into
> one scannable file. Read that for the summary; this section has the detail
> with examples.

### 7.1 Lexical Binding — Why Every .el File Needs It

Every `.el` file in this config must start with a lexical-binding cookie:

```elisp
;;; config.el -*- lexical-binding: t; -*-
```

This tells Emacs to use lexical scoping instead of the default dynamic scoping.
Without it:

- **Closures don't work** — `(let ((x 1) (lambda () x))` captures `x` by
  reference, not by value. Dynamic binding means every lambda re-evaluates at
  call time, not definition time.
- **Byte-compilation is slower** — the byte-compiler can't optimize variable
  references, producing larger, slower code.
- **Variable shadowing is fragile** — a `let` binding can be overridden by
  any `setq` anywhere in the call stack.

**The cookie is mandatory.** If a file doesn't have it, add it. The `;;;`
triple-semicolon is the file's major mode header; the `-*- ... -*-` sets
file-local variables. The cookie only affects the file it's in — different
files can have different binding strategies.

### 7.2 Startup Performance — Every Millisecond Counts

Doom's design philosophy is "lazy by default." Stay consistent:

| Principle                                                       | Practice                                                                                                                                                                              |
| --------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Defer everything                                                | Every `use-package!` gets `:defer t` unless the package is needed at startup                                                                                                          |
| Prefer `after!` over `(require '...)`                           | `(require 'foo)` force-loads `foo` at config time. `(after! foo ...)` runs when the feature actually loads. Never `(require)` in config unless you have a specific startup dependency |
| Use `:commands` for autoloads                                   | Instead of loading a package, declare entry-point commands that autoload it on first use                                                                                              |
| Use `:hook` in `use-package!`                                   | `(use-package! foo :hook (mode . func))` is cleaner and more efficient than a separate `(add-hook! ...)` outside the declaration                                                      |
| Keep `:init` blocks lean                                        | `:init` runs at startup even with `:defer t`. Put expensive setup in `:config` (runs after actual load)                                                                               |
| Prefer `modulep!` over `(when (require 'foo nil 'noerror) ...)` | `modulep!` is a compile-time check — disabled modules are never compiled, producing zero startup cost                                                                                 |
| Avoid lambdas in hooks                                          | `:hook (mode . (lambda () ...))` creates a new closure each time the hook runs. Prefer a named function                                                                               |

**Hot take: if you can't justify why a piece of code needs to run at startup,
it shouldn't run at startup.**

### 7.3 Config Style and Runtime Performance

| Wrong / Anti-pattern                                  | Right / Doom Way                                       | Why                                                                                                                                  |
| ----------------------------------------------------- | ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------ |
| `(use-package foo ...)`                               | `(use-package! foo ...)`                               | Adds disabled-package awareness and extra keywords; the regular `use-package` misses these                                           |
| `(with-eval-after-load 'foo ...)` or `(require 'foo)` | `(after! foo ...)`                                     | Doom's macro handles ordering through its deferred system. Never `require` in config                                                 |
| `(setq-default ...)` or bare `setq`                   | `setq!`                                                | Triggers custom setters on customizable variables; more efficient than `setopt`. <!-- stale-check: allow -->                         |
| `(define-key map k f)` or `(global-set-key ...)`      | `(map! ...)` with `:leader`, `:map`, or `:localleader` | Integrates with which-key for discoverability and evil-state awareness                                                               |
| `(add-hook 'foo-hook ...)` with a lambda              | `(add-hook! ...)` or `use-package!` `:hook`            | Supports multiple hooks, local variables natively (`setq-local` inside the form), and mode-specific behavior without lambda wrappers |
| `(loop for ... collect ...)`                          | `(cl-loop for ... collect ...)`                        | `cl-lib` is the modern, namespaced version. Bare `loop` pollutes the namespace                                                       |
| `(defun* ...)` or `(destructuring-bind ...)`          | `(cl-defun ...)` or `(cl-destructuring-bind ...)`      | All `cl` functions have `cl-` prefixed equivalents                                                                                   |
| Nested `cond` chains                                  | `pcase`                                                | Byte-compiler optimises `pcase` better; more readable pattern matching                                                               |
| Deleting unused `init.el` lines                       | Commenting them out                                    | The comment IS documentation — it tells the next agent a module was considered and turned off                                        |
| `package-install` (interactive)                       | `(package! ...)` in `packages.el` + `doom sync`        | Straight vs package.el conflict; explicit declarations keep the config reproducible                                                  |

### 7.4 Config Hygiene — Code That Stays Maintainable

- **Namespace everything.** Use the `user/` prefix for all custom functions,
  variables, and private state. Never use a bare `my-` prefix or no prefix at
  all — collisions with package-internal functions are silent and hard to
  debug.
- **Guard optional integrations.** When enabling a minor mode or calling a
  function from an optional package, guard it with `fboundp`:

  ```elisp
  (when (fboundp 'org-roam-db-autosync-mode)
    (org-roam-db-autosync-mode))
  ```

  This lets the file byte-compile cleanly even when the package isn't loaded.

- **Comment, never delete.** In `init.el`, disabled modules stay as comments.
  The comment IS documentation — it tells the next agent "this is available,
  it was considered and turned off."
- **One concern per edit.** Don't fix two unrelated things in the same commit.
  If you're adding a package and fixing a keybinding, split them.
- **Use the existing `sections/` split.** Add per-feature settings, hooks, and
  advice to `sections/<topic>.el`; register new sections from `config.el` with
  `load!`:

  ```elisp
  (load! "sections/org")
  ```

- **Prefer named functions over lambdas.** Lambdas in hooks make the hook
  invisible to `describe-function`, stack traces harder to read, and the
  lambda can't be removed without the original reference.

### 7.5 Code Quality Toolchain

| Tool                    | When                                      | What It Catches                                                     |
| ----------------------- | ----------------------------------------- | ------------------------------------------------------------------- |
| `check-parens`          | After every `.el` edit                    | Mismatched parentheses                                              |
| `M-x byte-compile-file` | Before committing `.el` changes           | Free variable references, unused lexical variables, type mismatches |
| `doom doctor`           | After every `doom sync`                   | Config errors, module conflicts, missing binaries                   |
| `M-x checkdoc`          | Before submitting package-quality code    | Docstring formatting, missing arguments                             |
| `M-x doom/reload`       | After config changes in a running session | Verifies the config loads without errors                            |

**For this repo:** `check-parens` is required after every `.el` edit
(mandated by AGENTS.md). `doom doctor` runs automatically after `doom sync`.
Byte-compile before committing if you're touching non-trivial logic (more than
a few `setq` calls).

---

## Living Document — Keeping This File Current

This file is a living reference, not a static document. Doom Emacs evolves
rapidly — new macros, deprecations, and patterns appear every release. An agent
should treat this file as something to improve, not just consume.

When exploring official Doom resources and noticing something this file gets
wrong or omits:

1. **Check the official source first.** The canonical references are:
   - `~/.config/emacs/modules/` — each module's README.org and config.el
   - `~/.config/emacs/core/` — Doom's own macro definitions and documentation
   - `K` key on a module or flag in `init.el` — inline docs
   - `gd` on a module or flag in `init.el` — jump to definition
   - Doom's wiki at https://github.com/doomemacs/doomemacs/wiki
   - Doom's issue tracker and pull requests for recent changes

2. **Propose corrections.** If this file says something that contradicts the
   official source, it's wrong — the official source wins. Surface the
   discrepancy so the file gets updated.

3. **Add missing patterns.** If a Doom pattern is used in the user's config or
   appears commonly in Doom documentation but isn't covered here, propose
   adding it. This file should be a complete enough reference that an agent
   can write correct Doom config without reading the full skill.

4. **Flag deprecated patterns.** If a macro or convention in this file is
   deprecated by Doom upstream, note the deprecation and the replacement.
   Keep the old content briefly for context, then point to the new way.

5. **Reference, don't duplicate.** When official docs already have a thorough
   explanation, link to it rather than copy-pasting. This file is a curated
   guide — the skill at `.agents/skills/doom-emacs/SKILL.md` is the exhaustive
   reference.
