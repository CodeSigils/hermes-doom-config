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
| Spelling         | Jinx with Enchant/Hunspell (`en_US el_GR`)                |
| Git client       | magit                                                     |
| Terminal         | vterm                                                     |
| Tab/workspace    | workspaces module (`persp-mode`)                          |
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

| Function                     | Purpose                                        | Location                 |
| ---------------------------- | ---------------------------------------------- | ------------------------ |
| `user/git-config`            | Read a git config key from global gitconfig    | `config.el`              |
| `user/greek-input-method`    | Toggle the Greek input method                  | `sections/input.el`      |
| `user/split-window-sensibly` | Prefer side-by-side splits, fall back to below | `sections/navigation.el` |
| `user/initial-frame-size`    | Return saved or pixel-width-based frame size   | `sections/navigation.el` |
| `user/load-frame-geometry`   | Read saved frame geometry from disk            | `sections/navigation.el` |
| `user/save-frame-geometry`   | Save frame geometry to disk on Emacs exit      | `sections/navigation.el` |

## Config Policies Summary

For full policy text see [`AGENTS.md`](AGENTS.md):

- **Completion Policy** — Company preferred, Corfu disabled as commented module
- **Defensive Config Policy** — `fboundp` guards for optional packages; global defaults stay global
- **Skill Source Policy** — `.agents/skills/doom-emacs/` is canonical; local discovery can link to it

## Environment

- **OS:** PikaOS Linux (with conditional macos module via `:if` form)
- **Shell editing:** zsh support is enabled in `:lang sh +zsh +lsp`
- **Display:** Dual monitors
- **Default browser:** BrowserOS (Chromium agentic browser)
- **Node manager:** fnm (prettier installed via pnpm, survives Node switches)
- **Python CLI tooling:** `uv tool install`
- **Global formatters:** pnpm for prettier, pip/uv for ruff

## Config Details

### Spell Checking with Jinx

Jinx uses `en_US` and `el_GR`. Its configuration is in `packages.el`,
`sections/spellcheck.el`, and `sections/keys.el`. See [the Jinx reference](references/jinx.md)
for dependencies, verification, and the compatibility workaround.

### Dirvish File Manager

The `+dirvish` flag enables Dirvish. Its launcher is in `sections/keys.el` and
appearance in `sections/ui.el`. Bind launchers outside `after!` for immediate availability.

### Org-Tempo (`<s` Tab Expansion)

`sections/org.el` loads `org-tempo` for source-block expansion. Yasnippet is
separate; see [the snippet reference](references/yasnippets.md).

## Related Files

| File                                                                       | Purpose                                                    |
| -------------------------------------------------------------------------- | ---------------------------------------------------------- |
| [`DOOM-API.md`](DOOM-API.md)                                               | Idiomatic Doom patterns — which macros to use when and why |
| [`AGENTS.md`](AGENTS.md)                                                   | Agent behavior policies and workflow                       |
| [`references/INDEX.md`](references/INDEX.md)                               | External Doom Emacs reference catalogue                    |
| [`references/package-management.md`](references/package-management.md)     | Doom package lifecycle: declaration, sync, update, pinning |
| [`references/best-practices.md`](references/best-practices.md)             | Consolidated Doom config best practices                    |
| [`references/jinx.md`](references/jinx.md)                                 | Jinx spell-checking — config, dictionaries, verification   |
| [`references/drift-prevention.md`](references/drift-prevention.md)         | Source-to-dependent drift prevention map                   |
| [`references/snippet-validation.md`](references/snippet-validation.md)     | Yasnippet parser-level validation — directives, semantics  |
| [`references/yasnippets.md`](references/yasnippets.md)                     | Snippet inventory, template syntax, best practices         |
| [`.agents/skills/doom-emacs/SKILL.md`](.agents/skills/doom-emacs/SKILL.md) | Repo-specific guide with procedures and troubleshooting     |
| [`README.md`](README.md)                                                   | Human-facing quick start                                   |
