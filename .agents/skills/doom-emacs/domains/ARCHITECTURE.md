# Doom Framework Architecture

Depth guide for understanding Doom's module system, flags, variables, reload semantics, and diagnostics. Read this when
you need to understand how Doom is structured or before editing `init.el`.

**Parent skill:** `SKILL.md` — compact core with file roles, API essentials, safety checks, pitfalls, and the Quick
Index for all domain files. Load SKILL.md first for the minimal context every Doom edit needs.

## Config Modularity

Split `config.el` into topic-specific files when a topic block exceeds ~50 lines. Load them with `load!`:

```elisp
;; In config.el near the bottom:
(load! "modules/org")
(load! "modules/lsp")
```

Each topic file gets its own lexical-binding cookie. This keeps `config.el` readable and makes it easy to temporarily
disable an area by commenting its `load!` line.

## The `doom!` Module System

`init.el` declares modules inside `(doom! ...)`, grouped into 13 categories:

| Category      | Purpose                                    |
| :------------ | :----------------------------------------- |
| `:input`      | Input methods (bidi, CJK)                  |
| `:completion` | Company, corfu, vertico, helm, ivy, ido    |
| `:ui`         | Visual layer: modeline, popup, tabs, doom  |
| `:editor`     | Evil, snippets, format, fold, word-wrap    |
| `:emacs`      | Dired, ibuffer, tramp, undo, vc, electric  |
| `:term`       | vterm, eshell, shell, term                 |
| `:checkers`   | Syntax, spell, grammar                     |
| `:tools`      | LSP, magit, lookup, direnv, docker, eval   |
| `:os`         | OS-specific: macos, tty                    |
| `:lang`       | Language support: python, org, rust, latex |
| `:email`      | mu4e, notmuch, wanderlust                  |
| `:app`        | Calendar, emms, everywhere, rss, irc       |
| `:config`     | default (+bindings +smartparens), literate |

Lines within each category are sorted alphabetically. Comment disabled modules, never delete them — the commented-out
line is documentation.

## Module Flags

Flags (`+keyword`) parametrize a module — switching backends (`+eglot` vs `+lsp-mode`), enabling features (`+roam`),
changing UI (`+childframe`, `+icons`), or pulling in packages (`+dirvish`).

To resolve a flag's meaning: put cursor on the flag in `init.el` and press `K` (`C-c c k`) for inline docs, or `gd`
(`C-c c d`) to jump to its definition in `~/.config/emacs/modules/<cat>/<mod>/+<flag>.el`.

See `DOOM-API.md` for a table of common flags used in this repo and the canonical Doom API guide.

## Doom Variables

| Variable           | Value                           |
| :----------------- | :------------------------------ |
| `doom-user-dir`    | `~/.config/doom/`               |
| `doom-cache-dir`   | `~/.config/emacs/.local/cache/` |
| `doom-modules-dir` | `~/.config/emacs/modules/`      |

These are safe to reference in config.el, e.g. `(expand-file-name "foo.el" doom-user-dir)`.

## Reload Without Restarting

- **Inside Emacs:** `M-x doom/reload` — reloads config, no restart
- **From terminal:** `emacsclient -e '(doom/reload)'`
- **After `doom sync`:** run `doom/reload` last to avoid format-on-save indentation issues (see SKILL.md Pitfalls)

## `:tools lsp` — Two Backends

| Flag        | Backend  | When                          |
| :---------- | :------- | :---------------------------- |
| `+eglot`    | eglot    | Simpler, built-in integration |
| `+lsp-mode` | lsp-mode | More features, more config    |

Language modules like `(python +lsp)` inherit whichever backend is active — they don't select their own. Configure only
the backend you've enabled, not both.

## Diagnostic Commands

| Command              | Use                                |
| :------------------- | :--------------------------------- |
| `doom doctor`        | After every `doom sync`            |
| `doom info`          | Full diagnostics (for bug reports) |
| `doom env`           | Regenerate the environment file    |
| `emacs --debug-init` | Catch errors with stack trace      |
| `M-x doom/debug`     | Toggle debug logging               |

## Restoring Official Template Content

Doom ships canonical example files at `~/.config/emacs/static/`:

- `config.example.el`
- `init.example.el`
- `packages.example.el`

These contain the original template comments and example settings. If a file has been trimmed of template boilerplate,
restore the comment blocks from the example — preserving the user's actual values, overwriting only comments.
