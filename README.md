# doom-emacs-config

My personal Doom Emacs configuration repo. Designed for org-mode, GTD
workflows, and general development with Company completion on a dual-monitor
setup.

## Quick Start

Requires [Doom Emacs](https://github.com/doomemacs/doomemacs) installed.

```sh
git clone <remote-url> ~/.config/doom
doom sync
doom doctor
```

If you're an AI agent working in this repo, read `AGENTS.md` first. The repo's
required Doom skill is self-contained at `.agents/skills/doom-emacs/SKILL.md`.
If your Hermes installation also has `emacs-lisp-expert`, load it as an optional
companion skill for general Emacs Lisp guidance. If it is missing, consider
installing it for deeper Emacs Lisp help, but do not require it for basic repo
maintenance.

Agent workflow: work sequentially, check `git status --short` before edits,
inspect files before patching, verify README module lists against `init.el`, run
`check-parens` for changed `.el` files, run `doom sync` after requested Doom
config edits unless told not to, and run `doom doctor` after `doom sync`.

## Notable Enabled Modules

`init.el` is the source of truth for this list.

- `:completion company +childframe +tng` and `vertico`
- `:ui doom, doom-dashboard, hl-todo, indent-guides, modeline, ophints, popup
  +all +defaults, smooth-scroll, vc-gutter +pretty, vi-tilde-fringe,
  window-select, workspaces, zen`
- `:editor evil +everywhere, file-templates, fold, format +onsave, snippets,
  whitespace +guess +trim, word-wrap`
- `:emacs dired +icons +dirvish, electric, eww, ibuffer +icons, tramp, undo,
  vc`
- `:term vterm`
- `:checkers syntax`
- `:tools ansible, direnv, docker, eval +overlay, lookup, lsp +eglot, magit,
  pdf, tree-sitter`
- `:lang data, emacs-lisp, json, latex, markdown, org +roam +babel +dragndrop,
  python +lsp, sh +zsh +lsp, yaml +lsp`
- `:app everywhere`
- `:config default +bindings +smartparens`

Not currently enabled: Doom's `mu4e`, `irc`, `rss`, `rest`, `web`, `treemacs`,
`nav-flash`, `multiple-cursors`, `rotate-text`, and `editorconfig` modules are
commented out in `init.el`.

## Key Features

- **Company completion** with file path expansion — `company-files` added to
  `prog-mode`, `org-mode`, and `org-capture-mode`
- **Dirvish** — `SPC d d` launches `dirvish-dwim`
- **Jinx spell checking** — fast Enchant/Hunspell-backed spell checking for
  prose and code comments/strings
- **Org mode** — org-roam, org-journal, org-download with yank-media, habit
  tracking, and GTD workflows
- **Window management** — `set-popup-rule!` for transient buffers,
  `split-window-preferred-function` for predictable splits, monitor-aware
  initial frame sizing via `sand/initial-frame-size`
- **Popup targets** — `*Help*`, `*Completions*`, `*vterm*`, `*vc-diff*`,
  `*vc-log*`, `*org-capture*`, `*elfeed-search*`, `*gnuplot*`,
  `*doom:scratch-buffer*`
- **Snippets** — Yasnippet snippets live under `snippets/<major-mode>/`; the
  TypeScript snippets inherit JavaScript snippets through `.yas-parents`
- **Defensive setup** — `fboundp` guards on optional packages,
  `delete-by-moving-to-trash` globally

## Optional System Dependencies

`doom doctor` reports missing optional tools for some enabled modules and
workflows. Install only what you use.

| Tool or package                        | Used by                        | Notes                                            |
| :------------------------------------- | :----------------------------- | :----------------------------------------------- |
| Symbola or equivalent Unicode font     | Doom font checks               | Optional fallback symbol font                    |
| `ansible`                              | `:tools ansible`               | Needed for Ansible editing helpers               |
| `dockfmt`                              | `:tools docker`                | Formats Dockerfiles                              |
| Markdown compiler                      | Markdown preview/export        | Use the compiler expected by your Doom setup     |
| `gnome-screenshot`, `maim`, or `scrot` | org-download clipboard images  | On GNOME, prefer `gnome-screenshot` if available |
| `pyflakes`                             | Python syntax checking         | Optional Python checker                          |
| `isort`                                | Python import sorting          | Optional formatter/import sorter                 |
| `pipenv`                               | Python environments            | Only needed for Pipenv projects                  |
| `nosetests`                            | Python test runner integration | Legacy; only needed for Nose-based projects      |

## Maintenance

```sh
# Before upgrading Doom, back up your config
cp -a ~/.config/doom ~/.config/doom.backup.$(date +%Y%m%d)

doom upgrade
doom sync
doom doctor
```

If something breaks, `doom rollback` reverts the framework. Restore
`~/.config/doom.backup.*` if config files were affected.

## Notes

- `~/.config/doom/` is a git repo, not chezmoi managed
- Runtime SQLite artifacts under `.open-mem/` are ignored; keep durable notes in
  human-readable files instead of committing WAL/SHM database state
- The repo skill is canonical; when working in the local Hermes runtime,
  sync `.agents/skills/doom-emacs/` to
  `~/.hermes/skills/emacs/doom-emacs-config/` with `cp` after skill edits
- Markdown files in this repo should not contain emoji, including generated
  status summaries or agent notes
- Unused modules are commented out in `init.el`, never deleted
