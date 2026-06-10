# Doom Emacs Reference Index

Purpose: catalogue of Doom Emacs reference material organized for agent
consultation. An agent reading this file discovers what is possible, then
evaluates against the user's actual config and needs. This is an inspiration
catalogue, not a copy-paste library.

---

### Core Principle: Learn, Don't Copy

Every Emacs config is personal and idiomatic — the product of its author's
habits, modules, naming, and workflow. References in this file show what is
possible with Doom Emacs. They are not instructions to adopt.

An agent must never treat external configs as code to transplant. Instead:

1. **Learn** — understand what the feature does and why it exists
2. **Evaluate** — check against the user's PROFILE.md policies, existing config
   structure, completion backend, window rules, and naming conventions
3. **Suggest** — present the option to the user with what it enables and what
   it costs (conflicts, complexity, performance impact), using the user's own
   style conventions
4. **Only implement on request** — never apply external patterns unilaterally

The user's running config at `~/.config/doom/init.el` + `config.el` +
`packages.el` is the single source of truth. Everything else is inspiration.

### Evaluation Checklist

When an agent encounters a reference feature and is considering whether to
propose it, these checks determine if it's compatible:

1. **Module conflict** — does it require a module or flag not in `init.el`?
   If so, note what to add.
2. **Completion backend** — does it assume Corfu/Cape (alternative
   completions), LSP-specific completion, or any behavior that conflicts with
   the Company + vertico setup?
3. **Window management** — does it advise low-level window primitives, change
   `display-buffer-alist` broadly, or assume a single-monitor layout?
4. **Keybinding** — does it use `define-key` or `global-set-key` where a
   `map!` form would be more idiomatic? Does it shadow an Evil binding?
5. **External dependency** — does it require a binary, API key, or system
   package not listed in the environment profile?
6. **Doom version** — is it compatible with the monolithic Doom repo at
   `~/.config/emacs/`? (Does not assume the new core/modules split.)
7. **Config style** — does it assume `config.org` literate setup,
   `use-package` without Doom's `use-package!` wrapper, or other patterns
   that differ from this config's approach?
8. **Performance cost** — does it enable expensive features (Tree-sitter on
   every buffer, global mode on large hook, frequent timers)?

If any check produces a conflict, flag it to the user with the specific
incompatibility and let them decide. Do not silently adapt the reference code
to work around the conflict.

---

### Agent Strategy: How to Use This File

When asked a Doom Emacs question:

1. **Check this file first** — scan the relevant category for pointers.
2. **For Doom API/macro questions** — consult `DOOM-API.md` first (top-level,
   visible to any agent). For deeper reference, see the skill at
   `.agents/skills/doom-emacs/SKILL.md`.
3. **For module questions** — the local source at `~/.config/emacs/modules/` is
   the definitive reference. Each module directory has a `README.org` or
   `config.el` with its docs.
4. **For package questions** — check `~/.config/emacs/.local/straight/repos/`
   for installed package source code. This is more reliable than MELPA docs.
5. **For troubleshooting** — start with Section 7, then consult the Doom FAQ
   at `~/.config/emacs/docs/faq.org`.
6. **When suggesting config changes** — first check `PROFILE.md` for the
   current config setup, then cross-reference against AGENTS.md policies
   (completion system, window rules, naming conventions). These take priority
   over any external reference. Run the **Evaluation Checklist** above before
   proposing anything found in a reference link.
7. **When exploring possibilities** — Sections 11 and 12 catalogue inspiring
   community configs and features the user does not currently use. Browse
   these when the user asks "what could I do with X?" or "show me what's
   possible."

### Agent Prohibitions

- Do not add new modules, flags, or packages to `init.el` without user request
- Do not copy code from any external config into this config. Every config is
  personal — learn the pattern, write it fresh using this config's conventions
- Do not use external variable names, keybinding prefixes, or module flags that
  differ from this config's patterns without flagging the difference to the user
- Do not replace the user's existing patterns (Company for completion, sand/
  prefix, config.el over config.org) with references from external configs

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
`doomemacs/doomemacs` repo (this user's install) is being split into
`doomemacs/core` + per-module repos. Modules that have moved are tracked in
`~/.config/emacs/sources/`. The monolithic repo still works; the split affects
upstream development, not this config.

## 2. Local Source Anatomy

This Doom install lives at `~/.config/emacs/`. Key directories:

| Path                                     | Contents                                        |
| ---------------------------------------- | ----------------------------------------------- |
| `~/.config/emacs/lisp/`                  | Core Doom libraries (lib/\*.el)                 |
| `~/.config/emacs/modules/`               | All module categories + module code             |
| `~/.config/emacs/modules/<cat>/<mod>/`   | Individual module (config.el, packages.el, etc) |
| `~/.config/emacs/core/`                  | Module system, CLI, bootstrap                   |
| `~/.config/emacs/static/`                | Template example files                          |
| `~/.config/emacs/sources/`               | Module-to-repo mapping (during transition)      |
| `~/.config/emacs/docs/`                  | Official docs in org format                     |
| `~/.config/emacs/.local/straight/repos/` | Cloned package repos (read source here)         |
| `~/.config/emacs/.local/straight/build/` | Built/compiled package bytecode                 |
| `~/.config/emacs/.local/cache/`          | Cache files (eln-cache, etc)                    |

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

### This Config

This config's documentation (see `PROFILE.md` for the full overview):

- `../AGENTS.md` — agent behavior policies and workflow
- `../DOOM-API.md` — idiomatic Doom patterns reference
- `.agents/skills/doom-emacs/SKILL.md` — full Doom procedures and pitfalls
- `../init.el` — source of truth for enabled modules

## 6. Tips, Tricks, and Patterns

### Doom Macros (Use These, Not Vanilla)

| Doom Macro             | Replaces                       | Purpose                        |
| ---------------------- | ------------------------------ | ------------------------------ |
| `after!`               | `with-eval-after-load`         | Deferred config after load     |
| `use-package!`         | `use-package`                  | Package declaration + config   |
| `map!`                 | `define-key`, `global-set-key` | Keybinding (evil-aware)        |
| `add-hook!`            | `add-hook` (multi-mode)        | Multi-mode hook registration   |
| `setq-hook!`           | `add-hook` + lambda            | Buffer-local var in a hook     |
| `set-company-backend!` | `setq company-backends`        | Per-mode company backends      |
| `set-popup-rule!`      | `display-buffer-alist`         | Popup buffer display rules     |
| `defadvice!`           | `defun` + `advice-add`         | Named advice with docstring    |
| `load!`                | `load-file`                    | Load relative to doom-user-dir |
| `featurep!`            | `featurep`                     | Compile-time module check      |

For full syntax and examples, see `.agents/skills/doom-emacs/SKILL.md` section
"Doom API Essentials (Compact)".

### Common Module Flags

Flags toggle features within a module. Examples from this config:

| Flag          | Module           | Effect                           |
| ------------- | ---------------- | -------------------------------- |
| `+icons`      | `:ui`            | Icon font support                |
| `+lsp`        | `:lang <lang>`   | Enable LSP for that language     |
| `+eglot`      | `:tools lsp`     | Use eglot backend (not lsp-mode) |
| `+roam`       | `:lang org`      | Enable org-roam                  |
| `+babel`      | `:lang org`      | Enable org-babel                 |
| `+dragndrop`  | `:lang org`      | Drag-and-drop images in org      |
| `+pretty`     | `:lang org`      | Org-pretty-mode                  |
| `+onsave`     | `:editor format` | Auto-format on save              |
| `+dirvish`    | `:emacs dired`   | Dirvish file manager             |
| `+childframe` | `:completion`    | Childframe for completion UI     |

Press `gd` on any flag in `init.el` to see its definition.

### Stale Config Detection

Symptoms of config lagging behind Doom updates:

- `doom doctor` warns about deprecated variables or functions
- `byte-compile` warnings for obsolete API usage
- Errors mentioning `setq!` instead of `setopt` (Doom 3 migration)
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
| `void-function incf` error     | Jinx timer calling legacy `incf`/`decf`      | Add `cl-incf` alias (see config.el)       |

### Debugging Walkthrough

Step-by-step for "something is broken":

1. Run `doom doctor` in terminal
2. Check `*Messages*` buffer (`C-h e`) for error traces
3. Try `doom sync` to recompile stale bytecode
4. Check `~/.config/emacs/docs/faq.org` for known issues
5. Search Doom GitHub Issues for the error message
6. If LSP-related: check `M-x lsp-workspace-show-log`

## 8. Doom API Reference (Compact)

The canonical Doom API guide is `DOOM-API.md` at the repo root — read that
first for idiomatic patterns and macro decisions. This section is a compact
reference for quick lookup. For the full reference with examples, see
`.agents/skills/doom-emacs/SKILL.md`.

### Key Variables

| Variable           | Value / Purpose                           |
| ------------------ | ----------------------------------------- |
| `doom-user-dir`    | `~/.config/doom/` — user config directory |
| `doom-cache-dir`   | `~/.config/emacs/.local/cache/`           |
| `doom-modules-dir` | `~/.config/emacs/modules/`                |
| `doom-version`     | Current Doom version string               |
| `+workspace-name`  | Current workspace name (tabspaces)        |

### Key Commands

| Command                    | Binding     | Purpose                       |
| -------------------------- | ----------- | ----------------------------- |
| `doom/reload`              | (M-x)       | Reload config without restart |
| `doom/open-private-config` | `SPC h p`   | Open `~/.config/doom/`        |
| `doom/help`                | `SPC h d h` | Doom help dashboard           |
| `doom/help-modules`        | `SPC h d m` | Browse modules                |
| `doom/debug`               | (M-x)       | Toggle debug mode             |
| `+eval/buffer`             | `SPC b e`   | Eval current buffer           |
| `+eval/region`             | `SPC c e`   | Eval selected region          |

### Module Lookup from config.el

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

For the authoritative list of extra packages used in this config, see
`PROFILE.md` (Packages Installed section).

The actual declarations live in `packages.el` at the repo root.

## 10. Maintenance and Upgrades

### Doom Update Commands

| Command             | Purpose                                    |
| ------------------- | ------------------------------------------ |
| `doom upgrade`      | Update Doom framework + all packages       |
| `doom sync`         | Recompile, sync profiles, update autoloads |
| `doom update`       | Update all packages (without framework)    |
| `doom update <pkg>` | Update a specific package                  |
| `doom rollback`     | Revert last framework update               |
| `doom clean`        | Remove stale bytecode and repos            |
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
3. If config breaks: `doom rollback` restores the framework; restore
   `~/.config/doom.backup.*` if config files were affected

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
never to extract code. Every config is personal (see Core Principle).

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

**Reference note:** Tecosaur runs a very different set of modules and a
literate config.org setup. His org-mode depth is exceptional. The value for
this config is seeing what org-mode can do and evaluating whether those
features suit your workflow.

### Doom's Canonical Example Config

`~/.config/emacs/static/config.example.el` — the official example shipped with
Doom. Shows every module category with representative flags. Useful as a
starting point for understanding Doom's module system, but the configuration is
minimal by design.

### Community Config Links

https://github.com/doomemacs/doomemacs/wiki — Doom wiki page listing community
config repos. Browse to discover different organizational styles, package
choices, and module combinations.

User's own README.md and AGENTS.md — authoritative for this setup.

### Video (Community)

- System Crafters: "Doom Emacs for Beginners" series
- DistroTube: Doom Emacs overview and updates
- Protesilaos Stavrou: Emacs design and configuration philosophy (not
  Doom-specific but relevant)

### Blog Posts and Articles

- https://blog.doomemacs.org/ — Official Doom blog
- Emacs Reddit: /r/emacs and /r/doomemacs — frequent config discussion
- Various GitHub gists: search "doom emacs config" for community examples

## How to Contribute to This File

- Add links in the appropriate section with URL + brief description
- Verify links are current before adding
- Keep the agent strategy section at the top — it's the first thing a reader
  (human or machine) sees
- Prefer local paths (`~/.config/emacs/...`) over remote URLs when the
  information lives locally
- Prefer stable links (GitHub permalinks) over blog posts that may go stale
