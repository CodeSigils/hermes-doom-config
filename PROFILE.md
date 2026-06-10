# PROFILE.md — Doom Emacs Config Profile

Purpose: compact reference for what this Doom Emacs configuration is. An agent
reads this to understand the user's setup before making suggestions or
modifications.

This is a summary. The source of truth is `init.el`, `config.el`, and
`packages.el`.

---

## Quick Reference

| Property         | Value                                                             |
| ---------------- | ----------------------------------------------------------------- |
| Config dir       | `~/.config/doom/`                                                 |
| Doom install     | `~/.config/emacs/` (old monolithic repo)                          |
| Init file        | `init.el` (not `config.org` — not literate)                       |
| Completion       | `:completion company +childframe +tng` + `vertico`                |
| LSP backend      | `eglot` (not lsp-mode)                                            |
| File manager     | Dirvish via `:emacs dired +dirvish`                               |
| Spelling         | Jinx with Enchant/Hunspell (`en_US`)                              |
| Git client       | magit                                                             |
| Terminal         | vterm                                                             |
| Tab/workspace    | workspaces module (tabspaces)                                     |
| Formatting       | `format +onsave` — Ruff for Python, Prettier for Markdown         |
| Custom prefix    | `sand/`                                                           |
| Window mgmt      | Custom frame sizing for dual monitors (`sand/initial-frame-size`) |
| Version control  | `~/.config/doom/` is git, NOT managed by chezmoi                  |
| Module style     | Comment out unused modules, never delete lines                    |
| Keybinding style | `map!` with `:leader`; `:localleader` for major-mode maps         |
| Package installs | via `(package! ...)` in `packages.el` + `doom sync`               |

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
|               | `(org +roam +babel +dragndrop)`, `(python +lsp)`, `(sh +zsh +lsp)`, |
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

## Custom Functions (sand/ prefix)

| Function                                     | Purpose                                    |
| -------------------------------------------- | ------------------------------------------ |
| `sand/initial-frame-size`                    | Dual-monitor-aware initial frame sizing    |
| `sand/split-window-sensibly`                 | Split direction based on frame proportions |
| `sand/org-display-inline-images-only-in-org` | Only display inline images in org-mode     |

## Config Policies Summary

For full policy text see `AGENTS.md`:

- **Completion Policy** — Company preferred, Corfu disabled as commented module
- **Window Management Policy** — No low-level `window-split` advice; prefer `display-buffer-alist` and `set-popup-rule!`
- **Defensive Config Policy** — `fboundp` guards for optional packages; global defaults stay global

## Environment

- **OS:** PikaOS Linux (with conditional macos module via `:if` form)
- **Shell:** zsh (enabled in `:lang sh +zsh +lsp`)
- **Display:** Dual monitors
- **Default browser:** BrowserOS (Chromium agentic browser)
- **Node manager:** fnm (prettier installed via pnpm, survives Node switches)
- **Python CLI tooling:** `uv tool install`
- **Global formatters:** pnpm for prettier, pip/uv for ruff

## Related Files

| File                                 | Purpose                                                    |
| ------------------------------------ | ---------------------------------------------------------- |
| `DOOM-API.md`                        | Idiomatic Doom patterns — which macros to use when and why |
| `AGENTS.md`                          | Agent behavior policies and workflow                       |
| `references/INDEX.md`                | External Doom Emacs reference catalogue                    |
| `references/package-management.md`   | Doom package lifecycle: declaration, sync, update, pinning |
| `.agents/skills/doom-emacs/SKILL.md` | Doom API reference and procedures                          |
| `README.md`                          | Human-facing quick start                                   |
