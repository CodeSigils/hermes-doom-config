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

If you're an AI agent working in this repo, read `AGENTS.md` first.

## Notable Modules

- `:completion company` — with childframe and `company-files` path completion
- `:ui doom, doom-dashboard, hl-todo, modeline, nav-flash, ophints, popup, treemacs, vi-tilde-fringe, window-select, workspaces`
- `:editor evil, fold, multiple-cursors, rotate-text`
- `:emacs dired, electric, undo, vc`
- `:tools direnv, editorconfig, eval, lookup, lsp, magit, tree-sitter`
- `:lang org, markdown, yaml, rest, sh, emacs-lisp, json, python, web`
- `:email mu4e` (withmu and mbsync)
- `:app everywhere, irc, rss, scriba`
- `:config default`

## Key Features

- **Company completion** with file path expansion — `company-files` added to
  `prog-mode`, `org-mode`, and `org-capture-mode`
- **Dirvish** — `SPC d d` launches `dirvish-dwim`
- **Jinx spell checking** — fast Enchant/Hunspell-backed spell checking for
  prose and code comments/strings
- **Org mode** — org-roam, org-journal, org-download with yank-media, habit
  tracking, and GTD workflows
- **Mu4e** — email with contexts, native address completion, org-capture
  integration
- **Window management** — `set-popup-rule!` for transient buffers,
  `split-window-preferred-function` for predictable splits, monitor-aware
  initial frame sizing via `sand/initial-frame-size`
- **Popup targets** — `*Help*`, `*Completions*`, `*vterm*`, `*vc-diff*`,
  `*vc-log*`, `*org-capture*`, `*elfeed-search*`, `*gnuplot*`,
  `*doom:scratch-buffer*`
- **Defensive setup** — `fboundp` guards on optional packages,
  `delete-by-moving-to-trash` globally

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
- Ollama Buddy is intentionally excluded from this config
- Unused modules are commented out in `init.el`, never deleted
