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
| Defer where useful           | Load packages when needed, with a real trigger for deferred configuration               |
| Declarative over imperative  | Say _what_ a package does, not _how_ to set it up                                        |
| Composability through macros | `after!`, `map!`, `add-hook!` compose across files without conflict                      |
| Stable pinned base           | Doom pins all packages. Unpin only when upstream moves faster than Doom                  |
| Doom API > Emacs API         | Always prefer Doom's macro (`use-package!`, `after!`, `setq!`) over the Emacs equivalent |

Check the installed source when choosing a macro or relying on version-specific behavior.

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
  :after-call after-find-file  ; load before this hook or command runs
  :defer-incrementally t       ; load this package incrementally during idle time
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

;; Compound conditions with :or/:and/:any/:all
(after! (:or magit diff-hl)  ; wait for ANY of these
  (do-something))
(after! (:and package-a (:or package-b package-c))  ; nested compound
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

;; Conditional — only bind when a module is enabled
(map! (:when (modulep! :completion company)
        :i "C-@" #'+company/complete))

;; Prefix group within map!
(map! (:prefix "C-x"
        :i "C-l" #'+company/whole-lines))

;; Unbind a key set elsewhere
(map! :map lua-mode-map "SPC m b" nil)

;; Global state binding
(map! :g "C-x y" #'do-something)
```

| Prefix         | Scope                                 |
| -------------- | ------------------------------------- |
| `:leader`      | `SPC` (evil) or `M-m`                 |
| `:localleader` | `SPC m` (major-mode prefix)           |
| `:n`           | Normal mode only                      |
| `:i`           | Insert mode only                      |
| `:v`           | Visual mode only                      |
| `:m`           | Motion mode only                      |
| `:g`           | Global (same as no prefix)            |
| `:map KEYMAP`  | Specific keymap (e.g. `org-mode-map`) |

Supports `:when` for conditional bindings, `(:prefix ...)` for nested key groups, and passing `nil` as the command to unbind.

**When to use:** Always prefer `map!` over `define-key` or `global-set-key`.
`map!` handles evil state awareness, which-key descriptions, and mode
unloading automatically.

### `add-hook!` — Multi-Mode Hook Attachment

```elisp
;; Single hook
(add-hook! 'prog-mode-hook #'rainbow-delimiters-mode)
;; Multiple hooks at once
(add-hook! '(org-mode-hook markdown-mode-hook) #'flyspell-mode)
;; Set local variable inside the hook
(add-hook! 'org-mode-hook (setq-local truncate-lines nil))

;; Append to the end of the hook chain
(add-hook! 'some-mode-hook :append #'enable-something)
;; Make it buffer-local
(add-hook! 'some-mode-hook :local #'enable-something)
;; Append and local together
(add-hook! 'some-mode-hook :append :local (setq v 5))

;; Inline named hook functions — no separate defun needed
(add-hook! '(one-mode-hook second-mode-hook)
  (defun do-something ()
    (message "Hello")))
```

Supports multiple hooks in one form, local variable setting, and `:append`
position flag. Simpler than writing separate `add-hook` calls.

### `setq!` — Safe Variable Setting

Doom's setter calls a variable's custom setter when present; otherwise it uses
`set-default-toplevel-value`. The installed source describes it as avoiding
unnecessary dependencies.

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

Parameters: `:size` (fraction or rows), `:ttl` (0 kills the buffer on close;
nil leaves it alive), `:quit` (quit behavior), `:select` (auto-select),
`:side` (bottom/left/right/top), `:slot`.

**Important:** Match buffer names with a regex. `"^\\*"` captures every star
buffer — too broad. Prefer specific names like `"^\\*Help\\*"`.

### `modulep!` — Module Check (replaces deprecated `featurep!`)

```elisp
(when (modulep! :ui popup)
  (set-popup-rule! ...))
```

Use this to test whether a module and its flags are enabled. Do not assume that
the body is removed at compile time; behavior depends on the expansion context.

### `setq-hook!` — Hook-Local Variable

```elisp
;; Single variable on a single hook
(setq-hook! 'org-mode-hook truncate-lines nil)

;; Multiple variables at once
(setq-hook! 'markdown-mode-hook
  line-spacing 2
  fill-column 80)

;; Apply to multiple hooks
(setq-hook! '(eshell-mode-hook term-mode-hook)
  hscroll-margin 0)
```

Cleaner than writing `(add-hook! 'mode-hook (lambda () (setq-local ...)))`. Works with one hook, multiple hooks, and one or more variables — the form is the same.

---

## 3. The Module System

### How `doom!` Works

`init.el` contains a single `(doom! ...)` form with modules grouped by category.
Some modules support flags (`+keyword`).

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
- Follow the existing category order in `init.el`.
- Comment disabled modules — never delete them (the comment IS documentation)
- Flags are `+keyword` suffixes; not all modules support flags

### How Flags Work

Flags parameterize module behavior. Inspect the installed module's `README.org`
and source for their definitions and effects; a flag need not have its own file.

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

Terminal reload requires a running Emacs server. If none is available, reload
inside Emacs or restart it.

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

Runtime config files should start with a lexical-binding cookie:

```elisp
;;; config.el -*- lexical-binding: t; -*-
```

This tells Emacs to use lexical scoping instead of the default dynamic scoping.
Without it:

- **Closures cannot capture lexical bindings** without lexical binding; free
  variables instead use dynamic lookup.
- **Optimization is more limited** because variable lookup uses dynamic scope.
- **Bindings have dynamic extent**, so a called function can see an active
  dynamic binding of the same variable.

The `-*- ... -*-` cookie sets file-local variables. `init.el` and `packages.el`
are Doom declaration files with their own header conventions; do not change
their headers merely to apply this runtime-config convention.

### 7.2 Startup Performance — Every Millisecond Counts

Doom's design philosophy is "lazy by default." Stay consistent:

| Principle                                                       | Practice                                                                                                                                                                              |
| --------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Defer where appropriate                                         | Use a hook, command, or other real load trigger; verify the intended behavior                                                                                                          |
| Prefer `after!` over `(require '...)`                           | `(require 'foo)` force-loads `foo` at config time. `(after! foo ...)` runs when the feature actually loads. Never `(require)` in config unless you have a specific startup dependency |
| Use `:commands` for autoloads                                   | Instead of loading a package, declare entry-point commands that autoload it on first use                                                                                              |
| Use `:hook` in `use-package!`                                   | `(use-package! foo :hook (mode . func))` keeps package-specific hook setup together                                                                                                    |
| Keep `:init` blocks lean                                        | `:init` runs at startup even with `:defer t`. Put expensive setup in `:config` (runs after actual load)                                                                               |
| Use `modulep!` for module conditions                            | Check enabled modules without loading a package just to test for it                                                                                                                    |
| Prefer named hook functions                                     | Named functions are easier to inspect and remove; use a lambda when appropriate                                                                                                      |

**Hot take: if you can't justify why a piece of code needs to run at startup,
it shouldn't run at startup.**

### 7.3 Config Style and Runtime Performance

| Wrong / Anti-pattern                                  | Right / Doom Way                                       | Why                                                                                                                                  |
| ----------------------------------------------------- | ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------ |
| `(use-package foo ...)`                               | `(use-package! foo ...)`                               | Adds disabled-package awareness and extra keywords; the regular `use-package` misses these                                           |
| Deferred package configuration                        | `(after! foo ...)`                                     | Runs after the feature loads; use `require` where a dependency must load immediately                                                 |
| Global customizable setting                           | `setq!`                                                | Triggers custom setters on customizable variables                                                                                    |
| `(define-key map k f)` or `(global-set-key ...)`      | `(map! ...)` with `:leader`, `:map`, or `:localleader` | Integrates with which-key for discoverability and evil-state awareness                                                               |
| `(add-hook 'foo-hook ...)` with a lambda              | `(add-hook! ...)` or `use-package!` `:hook`            | Supports multiple hooks, local variables natively (`setq-local` inside the form), and mode-specific behavior without lambda wrappers |
| `(loop for ... collect ...)`                          | `(cl-loop for ... collect ...)`                        | `cl-lib` is the modern, namespaced version. Bare `loop` pollutes the namespace                                                       |
| `(defun* ...)` or `(destructuring-bind ...)`          | `(cl-defun ...)` or `(cl-destructuring-bind ...)`      | All `cl` functions have `cl-` prefixed equivalents                                                                                   |
| Complex matching                                      | `pcase` where appropriate                              | Pattern matching can make the cases clearer                                                                                          |
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
(mandated by AGENTS.md). Run `doom doctor` after `doom sync`.
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
   - `~/.config/emacs/lisp/` — Doom's own macro definitions and documentation
   - `K` key on a module or flag in `init.el` — inline docs
   - `gd` on a module or flag in `init.el` — jump to definition
   - Doom Core API Demos at https://github.com/doomemacs/core/blob/master/modules/doom/demos.org — real usage examples for every Doom macro
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
