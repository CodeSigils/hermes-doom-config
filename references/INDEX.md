# Doom Emacs Reference Index

Catalogue of Doom Emacs reference material organized for agent consultation.
Browse categories below to discover what is possible. Every config is personal
— learn the pattern, write it fresh using your own conventions.

This is an inspiration catalogue, not a copy-paste library.

The authoritative reference for all Doom behavior is the installed source
at `~/.config/emacs/` — module `README.org` files define flags, module
`config.el` files show current patterns, and `lisp/` files document core
macros. This index points to those sources.

## 1. Official Resources

| Resource                 | URL / Path                                                               |
| ------------------------ | ------------------------------------------------------------------------ |
| Doom Emacs GitHub        | https://github.com/doomemacs/doomemacs                                   |
| Doom Emacs Issues        | https://github.com/doomemacs/doomemacs/issues                            |
| Doom Emacs Discussions   | https://github.com/doomemacs/doomemacs/discussions                       |
| Doom Emacs Documentation | https://docs.doomemacs.org/ (noted as outdated; in-Emacs help preferred) |
| In-Emacs Help            | `M-x doom/help`                                                          |
| Changelog                | `~/.config/emacs/docs/changelog.org`                                     |
| FAQ                      | `~/.config/emacs/docs/faq.org`                                           |
| Getting Started Guide    | `~/.config/emacs/docs/getting_started.org`                               |
| Contributing Guide       | `~/.config/emacs/docs/contributing.org`                                  |
| Doom CLI Help            | `doom help` (terminal) or `M-x doom/help` (in Emacs)                     |
| Doom Online Help         | https://github.com/doomemacs/doomemacs/wiki                              |

Note: the official docs site is version-lagging. The authoritative docs live
inside Emacs: `M-x doom/help` opens an interactive info browser with current
documentation matching the installed version.

The Doom Emacs repo recently entered a transition phase. The monolithic
`doomemacs/doomemacs` repo is being split into
`doomemacs/core` + per-module repos. This install uses the monolithic
repo, which remains fully functional.

## 2. Local Source Anatomy

This Doom install lives at `~/.config/emacs/`. Key directories:

| Path                                     | Contents                                        |
| ---------------------------------------- | ----------------------------------------------- |
| `~/.config/emacs/lisp/`                  | Core Doom libraries (lib/\*.el)                 |
| `~/.config/emacs/modules/`               | All module categories + module code             |
| `~/.config/emacs/modules/<cat>/<mod>/`   | Individual module (config.el, packages.el, etc) |
| `~/.config/emacs/core/`                  | Module system, CLI, bootstrap                   |
| `~/.config/emacs/static/`                | Template example files                          |
| `~/.config/emacs/profiles/`              | Profile system for multi-config switching       |
| `~/.config/emacs/docs/`                  | Official docs in org format                     |
| `~/.config/emacs/.local/straight/repos/` | Cloned package repos (read source here)         |
| `~/.config/emacs/.local/straight/build/` | Built/compiled package bytecode                 |
| `~/.config/emacs/.local/cache/`          | Cache files (eln-cache, etc)                    |
| `~/.config/emacs/.local/state/`          | Persistent state (savehist, recentf, etc)       |

## 3. Module Documentation

The module system is organized by category, each with its own init.el,
config.el, and packages.el. Module flags (e.g. `+lsp`, `+roam`) parametrize
behavior.

### How to Read Module Docs

For any enabled module in `init.el`:

1. `K` (press) on the module name in `init.el` — opens README.org
2. `gd` (press) on a flag keyword — jumps to its definition
3. Browse the source directly: `~/.config/emacs/modules/<category>/<module>/`

### Module Category Reference

The definitive list is in `~/.config/emacs/README.md` and `init.el`. The 13
categories:

| Category      | Purpose                        | Example Modules         |
| ------------- | ------------------------------ | ----------------------- |
| `:input`      | Input methods                  | bidi, chinese, layout   |
| `:completion` | Completion frameworks          | company, corfu, vertico |
| `:ui`         | Visual interface               | doom, modeline, popup   |
| `:editor`     | Editing behavior               | evil, snippets, format  |
| `:emacs`      | Built-in Emacs enhancements    | dired, tramp, vc, undo  |
| `:term`       | Terminal emulation             | vterm, eshell, shell    |
| `:checkers`   | Syntax and style checking      | syntax, spell           |
| `:tools`      | Developer tools                | lsp, magit, lookup      |
| `:os`         | OS-specific integrations       | macos, tty              |
| `:lang`       | Language support               | python, org, rust       |
| `:email`      | Email clients                  | mu4e, notmuch           |
| `:app`        | Applications                   | calendar, rss, irc      |
| `:config`     | Default keybindings and layout | default, literate       |

For flag documentation, press `K` in `init.el` while cursor is on a module
name, which opens the README for that module. The flag names are self-documenting
when viewed in context of the module's init.el.

### Module Discovery

Doom's `M-x doom/help` includes a module browser. From the terminal, `doom
doctor` reports module-related issues (missing dependencies, conflicting
flags, unregistered packages).

## 4. Community and Support

| Resource                | URL / Access                                          |
| ----------------------- | ----------------------------------------------------- |
| Doom Discord            | https://discord.gg/doom-emacs                         |
| Doom Discourse (forum)  | https://discourse.doomemacs.org/                      |
| Doom GitHub Discussions | https://github.com/doomemacs/doomemacs/discussions    |
| r/doomemacs (Reddit)    | https://reddit.com/r/doomemacs                        |
| Emacs StackExchange     | https://emacs.stackexchange.com/questions/tagged/doom |

Search order preference when stuck:

1. `M-x doom/help` (in-Emacs, version-matching)
2. `~/.config/emacs/docs/faq.org` (local copy)
3. Doom GitHub Issues (search first, then open)
4. Doom Discord (#help channel)
5. Doom Discourse

## 5. Tutorials and Guides

### Official Doom Docs (on GitHub)

| Guide           | Path                                         |
| --------------- | -------------------------------------------- |
| Getting Started | `~/.config/emacs/docs/getting_started.org`   |
| FAQ             | `~/.config/emacs/docs/faq.org`               |
| Appendix        | `~/.config/emacs/docs/appendix.org`          |
| Examples        | `~/.config/emacs/docs/examples.org`          |
| Migrating       | `~/.config/emacs/docs/index.org` (section 4) |

### Community Tutorials

Note: these external links may reference older Doom versions. Cross-check
against the local `~/.config/emacs/` source when examples don't work.

- Doom's own blog: https://blog.doomemacs.org/
- System Crafters Doom Emacs series (YouTube)
- DistroTube Doom Emacs overviews (YouTube)
- "Emacs From Scratch" series by System Crafters (YouTube)

## 6. Tips, Tricks, and Patterns

### Doom Macros (Use These, Not Vanilla)

| Doom Macro             | Replaces                       | Purpose                                                     |
| ---------------------- | ------------------------------ | ----------------------------------------------------------- |
| `after!`               | `with-eval-after-load`         | Deferred config after load                                  |
| `use-package!`         | `use-package`                  | Package declaration + config                                |
| `map!`                 | `define-key`, `global-set-key` | Keybinding (evil-aware)                                     |
| `add-hook!`            | `add-hook` (multi-mode)        | Multi-mode hook registration                                |
| `setq-hook!`           | `add-hook` + lambda            | Buffer-local var in a hook                                  |
| `set-company-backend!` | `setq company-backends`        | Per-mode company backends                                   |
| `set-popup-rule!`      | `display-buffer-alist`         | Popup buffer display rules                                  |
| `defadvice!`           | `defun` + `advice-add`         | Named advice with docstring                                 |
| `load!`                | `load-file`                    | Load relative to doom-user-dir                              |
| `modulep!`             | `modulep`                      | Compile-time module check (replaces deprecated `featurep!`) |

For full syntax and examples, see `DOOM-API.md` at the repo root.

### Common Module Flags

Flags toggle features within a module. Examples:

| Flag          | Module           | Effect                           |
| ------------- | ---------------- | -------------------------------- |
| `+lsp`        | `:lang <lang>`   | Enable LSP for that language     |
| `+eglot`      | `:tools lsp`     | Use eglot backend (not lsp-mode) |
| `+roam`       | `:lang org`      | Enable org-roam                  |
| `+dragndrop`  | `:lang org`      | Drag-and-drop images in org      |
| `+pretty`     | `:lang org`      | Org-pretty-mode                  |
| `+icons`      | `:emacs`         | Icon font in dired, ibuffer      |
| `+onsave`     | `:editor format` | Auto-format on save              |
| `+dirvish`    | `:emacs dired`   | Dirvish file manager             |
| `+childframe` | `:completion`    | Childframe for completion UI     |

Press `gd` on any flag in `init.el` to see its definition.

### Stale Config Detection

Symptoms of config lagging behind Doom updates:

- `doom doctor` warns about deprecated variables or functions
- `byte-compile` warnings for obsolete API usage
- `after!` blocks that no longer fire (module was renamed or split)

When in doubt, check the upstream module source at
`~/.config/emacs/modules/<cat>/<mod>/config.el` for current patterns.

## 7. Troubleshooting

### Quick Diagnostic Commands

| Command                          | When to Use                                    |
| -------------------------------- | ---------------------------------------------- |
| `doom doctor`                    | After every `doom sync` — catches basic issues |
| `doom info`                      | Full diagnostics dump for bug reports          |
| `doom env`                       | Regenerate environment file                    |
| `emacs --debug-init`             | Catch init errors with full stack trace        |
| `M-x doom/debug`                 | Toggle debug logging at runtime                |
| `M-x doom/reload`                | Reload config without restarting               |
| `emacsclient -e '(doom/reload)'` | Reload from terminal                           |
| `check-parens`                   | Verify balanced parens in `.el` files          |

### Common Issues

| Symptom                        | Likely Cause                                 | Fix                                       |
| ------------------------------ | -------------------------------------------- | ----------------------------------------- |
| Emacs won't start              | Unbalanced parens in config                  | Run `check-parens` on changed files       |
| Module flag not working        | Flag not in init.el or wrong module          | Verify in `init.el`, run `doom sync`      |
| Package not found              | Missing from packages.el or need `doom sync` | Add `package!` in packages.el, sync       |
| LSP not working for a language | Missing LSP server binary                    | Install server, verify with `doom doctor` |
| Keybinding not working         | Wrong keymap or missing `:after` keyword     | Use `:after` inside `map!`, not wrapped   |
| Format on save broken          | Missing formatter on `exec-path`             | Install tool, verify `exec-path`          |

### Debugging Walkthrough

Step-by-step for "something is broken":

1. Run `doom doctor` in terminal
2. Check `*Messages*` buffer (`C-h e`) for error traces
3. Try `doom sync` to recompile stale bytecode
4. Check `~/.config/emacs/docs/faq.org` for known issues
5. Search Doom GitHub Issues for the error message
6. If LSP-related: check `M-x lsp-workspace-show-log`

## 8. Doom API Reference (Compact)

This section is a compact reference for common Doom API macros and
commands. For full syntax and examples, see `DOOM-API.md`.

### Key Variables

| Variable           | Value / Purpose                           |
| ------------------ | ----------------------------------------- |
| `doom-user-dir`    | `~/.config/doom/` — user config directory |
| `doom-cache-dir`   | `~/.config/emacs/.local/cache/`           |
| `doom-modules-dir` | `~/.config/emacs/modules/`                |
| `doom-version`     | Current Doom version string               |
| `+workspace-name`  | Current workspace name (tabspaces)        |

### Key Commands

| Command                    | Binding     | Purpose                                             |
| -------------------------- | ----------- | --------------------------------------------------- |
| `doom/reload`              | `SPC h r r` | Reload config without restart (also M-x)            |
| `doom/open-private-config` | `SPC f P`   | Open `~/.config/doom/` (also `C-h d c` in help-map) |
| `doom/help`                | `SPC h d h` | Doom help dashboard                                 |
| `doom/help-modules`        | `SPC h d m` | Browse modules                                      |
| `doom/debug`               | (M-x)       | Toggle debug mode                                   |
| `+eval/buffer-or-region`   | `SPC c e`   | Eval current buffer or selected region              |

### Module Lookup

When you encounter an unknown variable or function:

1. `M-x find-library` to load any Emacs library source
2. `C-h f function-name` to read documentation
3. `C-h v variable-name` for variable documentation
4. `C-c c k` on a module flag for its README
5. Browse `~/.config/emacs/modules/` for module source
6. Browse `~/.config/emacs/lisp/lib/` for utility libraries

## 9. Package Ecosystem

Doom's package workflow — declaration (`package!`), configuration
(`use-package!`), installation (`doom sync`), updating, pinning, and
troubleshooting — is documented at:

- `references/package-management.md` — full lifecycle reference

## 10. Maintenance and Upgrades

### Doom Update Commands

| Command             | Purpose                                    |
| ------------------- | ------------------------------------------ |
| `doom upgrade`      | Update Doom framework + all packages       |
| `doom sync`         | Recompile, sync profiles, update autoloads |
| `doom update`       | Update all packages (without framework)    |
| `doom update <pkg>` | Update a specific package                  |
| `doom gc`           | Remove orphaned packages and stale builds  |
| `doom doctor`       | Validate config after changes              |

### Upgrade Safety

Before any upgrade:

```sh
# Backup the config repo (this is YOUR config, not Doom's):
cp -a ~/.config/doom ~/.config/doom.backup.$(date +%Y%m%d)
```

After `doom upgrade`:

1. Run `doom sync && doom doctor`
2. Check doctor output for deprecation warnings
3. If config still breaks, restore `~/.config/doom.backup.*` from the backup

### Avoiding Common Upgrade Pitfalls

- `doom upgrade` modifies `~/.config/emacs/` — your config at `~/.config/doom/`
  is separate but API changes can break it
- After major Doom versions, check `~/.config/emacs/docs/appendix.org` for
  breaking changes
- Package unpinning may be needed: if Doom pins a package version that conflicts
  with an installed package, use `(unpin! <pkg>)` in packages.el

## 11. Inspiring Community Configurations

A catalogue of what is possible with Doom Emacs, organized by what each config
teaches. These are exploration material — browse to learn patterns and features,
never to extract code. Every config is personal.

### Tecosaur's Emacs Config

https://tecosaur.github.io/emacs-config/config.html

One of the most polished Doom-based configs in the wild. Rich org-mode literate
config with deep coverage of:

- **Org-mode publishing** — export pipelines, LaTeX, HTML
- **Mixed-pitch** proportional fonts in org-mode
- **Centered cursor and typographic frame**
- **Org-modern** styling
- **LaTeX preview** with math snippets
- **Custom org-babel functionality**
- **Notification system** integration

The HTML rendering of his config at the link above is itself an artifact of his
org-publish pipeline — the config is self-hosting.

### Doom's Canonical Example Config

`~/.config/emacs/static/config.example.el` — the official example shipped with
Doom. Shows every module category with representative flags.

### Community Config Links

https://github.com/doomemacs/doomemacs/wiki — Doom wiki page listing community
config repos.

### Video (Community)

- System Crafters: "Doom Emacs for Beginners" series
- DistroTube: Doom Emacs overview and updates
- Protesilaos Stavrou: Emacs design and configuration philosophy (not
  Doom-specific but relevant)

### Blog Posts and Articles

- https://blog.doomemacs.org/ — Official Doom blog
- Emacs Reddit: /r/emacs and /r/doomemacs — frequent config discussion
- Various GitHub gists: search "doom emacs config" for community examples

## 12. In-Repo Reference Documents

Reference files shipped with this config, beyond the skill system:

| File                                        | Purpose                                        |
| ------------------------------------------- | ---------------------------------------------- |
| `references/package-management.md`          | Package lifecycle, pinning, straight recovery  |
| `references/best-practices.md`              | Consolidated Doom config best practices        |
| `references/yasnippets.md`                  | Yasnippet inventory and template syntax        |
| `references/jinx.md`                        | Jinx spell-checking — config and dictionaries  |
| `references/snippet-validation.md`          | Yasnippet parser-level validation guide        |
