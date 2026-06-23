# PROFILE.md — Doom Emacs Config Profile

Purpose: compact reference for what this Doom Emacs configuration is. An agent reads this to understand the user's setup
before making suggestions or modifications.

This is a summary. The source of truth is `init.el`, `config.el` (loader with universal defaults), `sections/*.el`
(per-feature config), `sections/keys.el` (keybindings), and `packages.el`; policy and reference guides live in
`AGENTS.md` and `references/`.

---

## Quick Reference

| Property         | Value                                                     |
| ---------------- | --------------------------------------------------------- |
| Config dir       | `~/.config/doom/`                                         |
| Doom install     | `~/.config/emacs/` (old monolithic repo)                  |
| Init file        | `init.el` (not `config.org` — not literate)               |
| Completion       | `:completion company +childframe +tng` + `vertico`        |
| LSP backend      | `eglot` (not lsp-mode)                                    |
| File manager     | Dirvish via `:emacs dired +dirvish`                       |
| Spelling         | Jinx with Enchant/Hunspell (`en_US`)                      |
| Git client       | magit                                                     |
| Terminal         | vterm                                                     |
| Tab/workspace    | workspaces module (tabspaces)                             |
| Formatting       | `format +onsave` — Ruff for Python, Prettier for Markdown |
| Custom prefix    | `user/`                                                   |
| Module style     | Comment out unused modules, never delete lines            |
| Keybinding style | `map!` with `:leader`; `:localleader` for major-mode maps |
| Package installs | via `(package! ...)` in `packages.el` + `doom sync`       |

## Modules Enabled (by Category)

From `init.el`:

| Category      | Enabled Modules (with flags)                                        |
| ------------- | ------------------------------------------------------------------- |
| `:completion` | `(company +childframe +tng)`, `vertico`                             |
| `:ui`         | `doom`, `doom-dashboard`, `hl-todo`, `indent-guides`, `modeline`,   |
|               | `ophints`, `(popup +all +defaults)`, `smooth-scroll`,               |
|               | `(vc-gutter +pretty)`, `vi-tilde-fringe`, `window-select`,          |
|               | `workspaces`, `zen`                                                 |
| `:editor`     | `(evil +everywhere)`, `file-templates`, `fold`, `(format +onsave)`, |
|               | `snippets`, `(whitespace +guess +trim)`, `word-wrap`                |
| `:emacs`      | `(dired +icons +dirvish)`, `electric`, `eww`, `(ibuffer +icons)`,   |
|               | `tramp`, `undo`, `vc`                                               |
| `:term`       | `vterm`                                                             |
| `:checkers`   | `syntax`                                                            |
| `:tools`      | `ansible`, `direnv`, `docker`, `(eval +overlay)`, `lookup`,         |
|               | `(lsp +eglot)`, `magit`, `pdf`, `tree-sitter`                       |
| `:os`         | `(:if (featurep :system 'macos) macos)` — conditional               |
| `:lang`       | `data`, `emacs-lisp`, `json`, `latex`, `markdown`,                  |
|               | `(org +roam +dragndrop)`, `(python +lsp)`, `(sh +zsh +lsp)`,        |
|               | `(yaml +lsp)`                                                       |
| `:app`        | `everywhere`                                                        |
| `:config`     | `(default +bindings +smartparens)`                                  |

## Packages Installed (from packages.el)

Beyond Doom built-ins:

| Package              | Purpose                 | Notes                                      |
| -------------------- | ----------------------- | ------------------------------------------ |
| `jinx`               | Async spell checking    | Installed from minad/jinx (not Doom's pin) |
| `compat`             | Compatibility layer     | Unpinned for Jinx compatibility            |
| `websocket`          | WebSocket client        | For org-roam-ui                            |
| `org-roam-ui`        | Org-roam graph browser  |                                            |
| `rainbow-delimiters` | Color-coded parentheses |                                            |

## Custom Functions (user/ prefix)

| Function                                     | Purpose                                        | Location                 |
| -------------------------------------------- | ---------------------------------------------- | ------------------------ |
| `user/split-window-sensibly`                 | Prefer side-by-side splits, fall back to below | `sections/navigation.el` |
| `user/initial-frame-size`                    | Return a monitor-aware initial frame size      | `sections/navigation.el` |

## Config Policies Summary

For full policy text see [`AGENTS.md`](AGENTS.md):

- **Completion Policy** — Company preferred, Corfu disabled as commented module
- **Defensive Config Policy** — `fboundp` guards for optional packages; global defaults stay global
- **Skill Source Policy** — `.agents/skills/doom-emacs/` is canonical; the Hermes mirror is generated and not hand-edited
- **Script Safety Policy** — mirror updates validate identity, stage replacement, and restore the prior mirror on failure

## Environment

- **OS:** PikaOS Linux (with conditional macos module via `:if` form)
- **Shell:** zsh (enabled in `:lang sh +zsh +lsp`)
- **Display:** Dual monitors
- **Default browser:** BrowserOS (Chromium agentic browser)
- **Node manager:** fnm (prettier installed via pnpm, survives Node switches)
- **Python CLI tooling:** `uv tool install`
- **Global formatters:** pnpm for prettier, pip/uv for ruff

## Config Details

### Spell Checking with Jinx

This config uses Jinx for spelling instead of Doom's built-in Flyspell module. Jinx is async (avoids one subprocess per
check), supports multiple languages simultaneously, and uses Enchant as a backend.

Keep Doom's `(spell +flyspell)` line commented in `init.el`:

```elisp
;; (spell +flyspell)  ; left commented for future reference
```

**packages.el:**

```elisp
(unpin! compat)    ; Jinx needs compat 31+
(package! jinx
  :recipe (:host github :repo "minad/jinx"))
```

**sections/spellcheck.el and sections/keys.el:**

```elisp
;; Jinx 2.7 calls legacy bare incf/decf at runtime. Emacs 30 only has the
;; cl-lib names, so install aliases before autoloaded commands run.
;; Prefer aliases over a straight :pre-build source patch: the source patch
;; dirties the checkout and makes `doom sync -u` stop for an interactive
;; dirty-tree prompt.
(require 'cl-lib)
(unless (fboundp 'incf)
  (defalias 'incf #'cl-incf))
(unless (fboundp 'decf)
  (defalias 'decf #'cl-decf))

(use-package! jinx
  :hook ((text-mode prog-mode conf-mode yaml-mode) . jinx-mode)
  :config
  (setq! jinx-languages "en_US"))

;; sections/keys.el
(map! "M-$" #'jinx-correct
      "C-M-$" #'jinx-languages
      :leader
      (:prefix ("s" . "spelling")
       :desc "Correct word" "c" #'jinx-correct
       :desc "Next misspelling" "n" #'jinx-next
       :desc "Previous misspelling" "p" #'jinx-previous))
```

**System dependencies** (Debian/PikaOS):

- Runtime: `enchant-2`, `hunspell` or `nuspell`, `hunspell-en-us`
- Build: `libenchant-2-dev` + `pkg-config` (provides `enchant-2.pc`)

Probe commands:

```sh
command -v enchant-2 || command -v enchant
command -v pkg-config
command -v hunspell || command -v nuspell
pkg-config --exists enchant-2
```

**Verification after `doom sync`:**

```sh
emacs --batch -L ~/.config/emacs/.local/straight/build-30.2/compat \
  -L ~/.config/emacs/.local/straight/build-30.2/jinx \
  --eval "(progn (require 'cl-lib) (unless (fboundp 'incf) (defalias 'incf #'cl-incf)) (unless (fboundp 'decf) (defalias 'decf #'cl-decf)) (require 'compat) (require 'jinx) (message \"jinx loads OK: %s, completion metadata: %s\" (featurep 'jinx) (fboundp 'completion-table-with-metadata)))"
git -C ~/.config/emacs/.local/straight/repos/jinx status --short
```

Expected result: Jinx loads, `completion-table-with-metadata` is defined, and the Jinx straight checkout is clean.

**`void-function incf` / `void-function decf`:** If `M-$`, `SPC s c`, or unrelated Org commands report
`Error running timer 'nil': (void-function incf)`, the idle Jinx timer is loading bytecode that still calls legacy
`incf`/`decf`. Confirm the aliases are present before `(use-package! jinx ...)`, run `doom sync`, restart Emacs, and
retest.

**Multilingual setup:** Extend `jinx-languages`, e.g. `"en_US de_DE"`. Start with the primary dictionary unless the user
asks for more.

**Flyspell legacy pattern** (for reference only — do not reintroduce):

```elisp
;; init.el
(spell +flyspell)

;; sections/spellcheck.el
(add-hook! '(org-mode-hook markdown-mode-hook text-mode-hook) #'flyspell-mode)
(add-hook! '(prog-mode-hook conf-mode-hook yaml-mode-hook) #'flyspell-prog-mode)
```

### Dirvish File Manager

Dirvish replaces Dired as the primary file manager via the `+dirvish` flag. The launcher keybinding stays outside the
`after!` block so it's available immediately and can autoload the command:

```elisp
;; sections/keys.el
;; Launcher binding — keep outside after! for immediate availability
(map! :leader :desc "Dirvish dwim" "d d" #'dirvish-dwim)

;; sections/ui.el
(after! dirvish
  (setq! dirvish-attributes '(vc-state nerd-icons subtree-state collapse git-msg file-size))
  (setq! dirvish-subtree-state-style 'nerd)
  (setq! dirvish-path-separators
        (list (format " %s " (nerd-icons-codicon "nf-cod-home"))
              (format " %s " (nerd-icons-codicon "nf-cod-root_folder"))
              (format " %s " (nerd-icons-faicon "nf-fa-angle_right")))))
```

Pitfall: putting `SPC d d` inside `(after! dirvish ...)` delays the binding until dirvish loads. For launcher commands,
bind first; customize after load.

### Org-Tempo (`<s` Tab Expansion)

Org-tempo provides `<s` + Tab → `#+begin_src` template expansion in Org buffers. The templates are built-in but Doom
loads them lazily, so an explicit `require` is needed:

```elisp
;; sections/org.el
(after! org
  (require 'org-tempo)   ; without this, `<s` won't expand
  ;; ... rest of org config
)
```

The current `init.el` declaration is `(org +roam +dragndrop)`. If `<s` still doesn't expand after adding the require,
consider adding the `+pretty` flag: `(org +roam +dragndrop +pretty)`.

The yasnippet path is separate: `SPC h i` to insert a snippet, type `src`, and Tab. Org-tempo and yasnippet are
independent completion systems and coexist.

## Related Files

| File                                                                       | Purpose                                                    |
| -------------------------------------------------------------------------- | ---------------------------------------------------------- |
| [`DOOM-API.md`](DOOM-API.md)                                               | Idiomatic Doom patterns — which macros to use when and why |
| [`AGENTS.md`](AGENTS.md)                                                   | Agent behavior policies and workflow                       |
| [`references/INDEX.md`](references/INDEX.md)                               | External Doom Emacs reference catalogue                    |
| [`references/package-management.md`](references/package-management.md)     | Doom package lifecycle: declaration, sync, update, pinning |
| [`references/best-practices.md`](references/best-practices.md)             | Consolidated Doom config best practices                    |
| [`references/yasnippets.md`](references/yasnippets.md)                     | Snippet inventory, template syntax, best practices         |
| [`.agents/skills/doom-emacs/SKILL.md`](.agents/skills/doom-emacs/SKILL.md) | General Doom guide with procedures and troubleshooting     |
| [`README.md`](README.md)                                                   | Human-facing quick start                                   |
