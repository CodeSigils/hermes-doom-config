# Doom Emacs config

## Agent instructions

- Load the `emacs-lisp-expert` and `doom-emacs-config` Hermes skills before
  modifying this Doom Emacs config or debugging Emacs Lisp behavior.
  Local reference copies are in `skills/` if the canonical skills aren't available.
- Use `;;;` for section headings (left-aligned) and `;;` for code-level
  documentation in config.el. Never remove or alter the lexical-binding cookie.
- Do not remove lines from `init.el`; comment disabled modules/settings instead so the original Doom module list stays visible and recoverable.
- Prefer Doom's `:completion company` module in this config: `(company +childframe +tng)`.
- Preserve the explicit `company-files` backend expansion in `config.el`; it is what provides file/path autosuggestions with Company.
- Keep `corfu` present but commented unless explicitly requested otherwise.
- Use documented window/display controls for layout behavior, such as `split-window-preferred-function`, Doom `set-popup-rule!`, and explicit keybindings. Do not advise low-level primitives like `window-split`.
- Keep initial frame sizing monitor-aware via `sand/initial-frame-size`; avoid returning to a single hardcoded frame size unless explicitly requested.
- Prefer targeted Doom popup rules for recurring transient buffers instead of broad catch-all star-buffer rules.
- Keep optional package startup defensive with `fboundp` guards when practical, e.g. `org-roam-db-autosync-mode`.
- Keep `delete-by-moving-to-trash` global; do not duplicate it inside package-specific blocks unless a package requires a different value.
- Do not add Ollama Buddy (`ollama-buddy`) back unless explicitly requested.
- Do not run chezmoi sync/update actions for Doom work until explicitly told to.
- Run `doom sync` after changing `init.el` modules or `packages.el`.
- Run `doom doctor` after `doom sync` to catch missing deps, wrong flags, or broken recipes.

## Doom Upgrade Safety

Before updating the Doom framework: `cp -a ~/.config/doom ~/.config/doom.backup.$(date +%Y%m%d)`
Then `doom upgrade`, `doom sync`, `doom doctor`. If something breaks, `doom rollback` or restore from backup.
