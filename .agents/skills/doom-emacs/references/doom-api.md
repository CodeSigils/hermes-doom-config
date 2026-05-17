# Doom Emacs API Quick Reference

Doom wraps standard Emacs with its own macros and helpers. These are the ones
you need to know to write correct config. Using the standard equivalent instead
of Doom's version is the most common source of bugs.

## Module Declaration (`init.el`)

Only valid inside the `(doom! ...)` block at the top of `init.el`.

| Pattern                                 | Meaning                                     |
| :-------------------------------------- | :------------------------------------------ |
| `(org +roam +babel)`                    | Enable org module with roam and babel flags |
| `:completion (company +childframe)`     | Company with childframe UI                  |
| `:ui (popup +all +defaults)`            | Popup system with all rules + defaults      |
| `:editor (format +onsave)`              | Format on save                              |
| `:checkers (spell +flyspell)`           | Flyspell spell checking                     |
| `(:if (featurep :system 'macos) macos)` | Conditional module (platform check)         |

**Rules:**

- Comment disabled modules (`;;corfu`), never delete the line
- Module order matters — listed under `:completion`, `:ui`, `:editor`, `:emacs`,
  `:term`, `:checkers`, `:tools`, `:os`, `:lang`, `:email`, `:app`, `:config`
- Flags are `+keyword` suffixes. Not all modules have flags

## Package Declaration (`packages.el`)

| Form                                                     | Effect                          |
| :------------------------------------------------------- | :------------------------------ |
| `(package! foo)`                                         | Install from MELPA/ELPA         |
| `(package! foo :disable t)`                              | Disable a Doom-included package |
| `(package! foo :recipe (:host github :repo "user/foo"))` | Install from git                |
| `(package! foo :recipe (:branch "develop"))`             | Use a specific branch           |
| `(package! foo :pin "abc1234")`                          | Pin to a specific commit        |
| `(unpin! foo)`                                           | Unpin a package (use latest)    |

**Important:** Doom uses `straight.el` under the hood. `package!` wraps
straight's recipe format. Running `package-install` manually installs to the
wrong location. Always use `package!` in `packages.el` then `doom sync`.

## Config Macros (`config.el`)

### `after!` — Defer Config After Feature Loads

```elisp
(after! org
  (setq org-adapt-indentation nil))

(after! (org company)  ; wait for both
  (do-something))
```

Do NOT use `with-eval-after-load` — `after!` is Doom's version, handles
package ordering correctly, and supports multiple features.

### `use-package!` — Declare + Configure

```elisp
(use-package! some-package
  :defer t               ; don't load immediately
  :hook (mode . func)    ; attach to mode hook
  :init                  ; run before loading
  :config                ; run after loading
  :commands my-func      ; autoload on command
  :after other-package)  ; load after dependency
```

Do NOT use the standard `use-package` (from MELPA). Doom's `use-package!`
(written with a trailing bang) has different deferral semantics.

### `map!` — Keybinding

```elisp
(map! :leader :desc "Foo" "f f" #'foo-command)       ; SPC f f
(map! :n "C-c C-f" #'foo-command)                     ; Normal mode
(map! :i "C-c C-f" #'foo-command)                     ; Insert mode
(map! :v "C-c C-f" #'foo-command)                     ; Visual mode
(map! :map org-mode-map :n "RET" #'org-open-at-point) ; Mode-specific
(map! :after org :desc "Agenda" "a a" #'org-agenda)   ; After feature loads
```

| Prefix           | Meaning                    |
| :--------------- | :------------------------- |
| `:leader`        | `SPC` (evil) or `M-m`      |
| `:localleader`   | `SPC m` or `M-m m`         |
| `:n`             | Normal mode                |
| `:i`             | Insert mode                |
| `:v`             | Visual mode                |
| `:m`             | Motion mode                |
| `:map MODE-MAP`  | Keymap-specific            |
| `:desc "..."`    | Description for which-key  |
| `:after FEATURE` | Define after feature loads |

### `set-company-backend!` — Per-Mode Completion

```elisp
(set-company-backend! 'prog-mode
  'company-files
  '(company-capf :with company-yasnippet)
  'company-dabbrev-code)

(set-company-backend! 'org-mode
  'company-files
  '(company-capf :with company-yasnippet)
  '(:separate company-dabbrev company-ispell))
```

Backends are tried in order. `:with` means a backend enriches the primary one.
`:separate` means each backend is tried independently.

### `add-hook!` — Multi-Mode Hooks

```elisp
;; Single hook
(add-hook! 'prog-mode-hook #'rainbow-delimiters-mode)

;; Multiple hooks
(add-hook! '(org-mode-hook markdown-mode-hook) #'flyspell-mode)

;; With local variables
(add-hook! 'org-mode-hook
  (setq-local truncate-lines nil))

;; Append (run after other hooks)
(add-hook! 'org-mode-hook :append #'my-function)
```

### `set-popup-rule!` — Buffer Display Rules

```elisp
(set-popup-rule! "^\\*Help\\*"
  :size 0.35 :ttl 0 :quit t :select nil)
```

| Param     | Meaning                               |
| :-------- | :------------------------------------ |
| `:size`   | Height (fraction of frame, or N rows) |
| `:ttl`    | Time to live (0 = forever)            |
| `:quit`   | `t` = quit with `q`                   |
| `:select` | `nil` = don't auto-select             |
| `:side`   | `'bottom`, `'left`, `'right`, `'top`  |
| `:slot`   | Which slot in the side                |

The regex matches buffer names. Be specific — `"^\\*"` captures every
star buffer and is almost always too broad.

### `featurep!` — Module Check

```elisp
(when (featurep! :ui popup)
  (set-popup-rule! ...))
```

This is a compile-time check. If the module isn't enabled, the code inside
is never compiled. Useful for conditional config that depends on module flags.

### `setq-hook!` — Hook-Local Variables

```elisp
(setq-hook! 'org-mode-hook truncate-lines nil)
```

Sets a variable locally in specified hooks. Cleaner than an `add-hook!` with
a lambda.

## Module Flag Reference (Common)

| Module               | Common Flags                                                     |
| :------------------- | :--------------------------------------------------------------- |
| `company`            | `+childframe`, `+tng` (tab-and-go)                               |
| `corfu`              | `+orderless`, `+dabbrev`                                         |
| `org`                | `+roam`, `+babel`, `+dragndrop`, `+noter`, `+pandoc`, `+present` |
| `org` (tempo)        | `+pretty` enables full `<s` Tab expansion; also requires         |
|                      | `(require 'org-tempo)` inside `(after! org ...)`                 |
| `lsp`                | `+eglot`, `+lsp-mode`                                            |
| `format`             | `+onsave`                                                        |
| `spell`              | `+flyspell`, `+aspell`, `+hunspell`                              |
| `dired`              | `+icons`, `+dirvish`                                             |
| `ibuffer`            | `+icons`                                                         |
| `popup`              | `+all`, `+defaults`                                              |
| `vc-gutter`          | `+pretty`                                                        |
| `workspaces`         | `+auto`                                                          |
| `(evil +everywhere)` | `+everywhere` (evil in non-programming buffers)                  |

## Org Snippet Style

Org yasnippet blocks use empty lines between open/close markers and body.
Cursor lands in the blank body line (via `$0`), not on the opening line.

**Standard block snippet shape:**

```text
#+begin_src python

$0
#+end_src
```

Not:

```text
#+begin_src python$0
...
#+end_src
```

Snippets live at `~/.config/doom/snippets/org-mode/`. Keys map to file names:
`<e` (example), `<h` (export html), `<q` (quote), `<v` (verse), `src`
(source). Only `src` has a default language argument (`${1:python}` with no
further tab stop after it — cursor goes straight to the body).

## Pitfalls Summary

| Wrong Pattern                     | Correct Pattern                 | Why                             |
| :-------------------------------- | :------------------------------ | :------------------------------ |
| `(use-package foo ...)`           | `(use-package! foo ...)`        | Doom's bang suffix matters      |
| `(setq-default ...)`              | `(setq ...)`                    | Doom handles default semantics  |
| `(with-eval-after-load 'foo ...)` | `(after! foo ...)`              | Doom's macro handles ordering   |
| `package-install`                 | `(package! ...)` in packages.el | Straight vs package.el conflict |
| Deleting init.el lines            | Commenting them out             | Module list must stay visible   |
| Rewriting config.el wholesale     | Targeted additions              | Preserve existing structure     |

## Official Doom Templates

Canonical example files live at `~/.config/emacs/static/`:

| Template              | Content                                              |
| :-------------------- | :--------------------------------------------------- |
| `config.example.el`   | Full config.el with template comments and examples   |
| `init.example.el`     | Module list with all available modules commented out |
| `packages.example.el` | Package declaration examples                         |

These are the files `doom install` copies when creating a new config. Fetch
them when a user asks to restore trimmed template commentary. Preserve the
user's actual settings — only re-add comment blocks.
