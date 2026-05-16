# 2026-05-16 Doom Config Evolution Notes

Session-derived workflow and configuration details for the user's `doom-emacs-config` repo.

## Durable workflow lessons

- For this user's Doom repo, run `doom sync` after requested config edits, even when only `config.el` changed, unless the user explicitly says not to. The user corrected this directly.
- Run a paren check before `doom sync` for changed `.el` files, then run `doom doctor` after sync.
- If `emacsclient -e '(doom/reload)'` fails because no Emacs server socket exists, do not treat it as a config failure; tell the user to restart Emacs or run `M-x doom/reload` inside Emacs.
- Keep operational knowledge in `.agents/skills/doom-emacs/` and AGENTS/README. Remove completed one-off plan/execution-summary files once their knowledge has been absorbed.

## Current config patterns established

### Jinx spelling

- Doom's `(spell +flyspell)` line is commented, not deleted.
- `(package! jinx)` is installed through Doom packages.
- `config.el` uses `use-package! jinx` with `jinx-languages` set to `"en_US"` only.
- Keybindings preserve `M-$` for `jinx-correct` and add leader spelling bindings under `SPC s`.

### Dirvish

- `dired +dirvish` is the Doom module path.
- `SPC d d` should launch `dirvish-dwim`.
- Bind launcher commands outside `(after! dirvish ...)` so the key is available immediately and can autoload the command.
- Keep visual/custom behavior inside `(after! dirvish ...)`.

### Repository identity

- Repo name: `doom-emacs-config`.
- README and AGENTS should use that name.
- The old one-off file `2026-05-16-emacs-aware-hermes.md` was removed after its content was absorbed into the skill and repo docs.
