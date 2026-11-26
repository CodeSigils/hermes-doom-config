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
| Doom Core API Demos      | https://github.com/doomemacs/core/blob/master/modules/doom/demos.org     |

The official docs site may lag the installed version. In the installed Doom,
`M-x doom/help` opens the local user manual; `M-x doom/help-search` searches
the installed documentation, and `M-x doom/help-modules` browses modules.

Check the installed source when following upstream guidance: local and upstream versions may differ.

## 2. Local Source Anatomy

This Doom install lives at `~/.config/emacs/`. Key directories:

| Path                                     | Contents                                        |
| ---------------------------------------- | ----------------------------------------------- |
| `~/.config/emacs/lisp/`                  | Core Doom libraries (lib/\*.el)                 |
| `~/.config/emacs/modules/`               | All module categories + module code             |
| `~/.config/emacs/modules/<cat>/<mod>/`   | Individual module (config.el, packages.el, etc) |
| `~/.config/emacs/static/`                | Template example files                          |
| `~/.config/emacs/profiles/`              | Profile system for multi-config switching       |
| `~/.config/emacs/docs/`                  | Official docs in org format                     |
| `~/.config/emacs/.local/straight/repos/` | Cloned package repos (read source here)         |
| `~/.config/emacs/.local/straight/build-<version>/` | Version-specific package builds; inspect the installed directory |
| `~/.config/emacs/.local/cache/`          | Cache files (eln-cache, etc)                    |
| `~/.config/emacs/.local/state/`          | Persistent state (savehist, recentf, etc)       |

## 2.1 Repository Security Policy

This repository's security reporting scope and handling expectations live in
[`SECURITY.md`](../SECURITY.md). It covers config/script/CI/agent-guidance
risks in this repo; upstream Doom/Emacs/package vulnerabilities should be
reported upstream when appropriate.

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

Doom's `M-x doom/help-modules` browses module documentation. From the terminal,
`doom doctor` reports module-related issues (missing dependencies, conflicting
flags, unregistered packages).

For a community-maintained module index with available flags and per-module
links, see
[fanrenmortals/doom-emacs modules/](https://github.com/fanrenmortals/doom-emacs/tree/develop/modules).

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

## 6. In-Repo Guidance

- [Doom API](../DOOM-API.md): macro decisions and examples.
- [Best practices](best-practices.md): organization and performance.
- [Package management](package-management.md): lifecycle, pinning and recovery.
- [Troubleshooting](../.agents/skills/doom-emacs/domains/TROUBLESHOOTING.md): diagnostics, including Eglot and lsp-mode.
- [Procedures](../.agents/skills/doom-emacs/domains/PROCEDURES.md): common tasks.

Consult installed module source for version-specific flags and behavior.

## 7. Inspiring Community Configurations

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

## 8. In-Repo Reference Documents

Reference files shipped with this config, beyond the skill system:

| File                               | Purpose                                       |
| ---------------------------------- | --------------------------------------------- |
| `references/package-management.md` | Package lifecycle, pinning, straight recovery |
| `references/best-practices.md`     | Consolidated Doom config best practices       |
| `references/yasnippets.md`         | Yasnippet inventory and template syntax       |
| `references/jinx.md`               | Jinx spell-checking — config and dictionaries |
| `references/snippet-validation.md` | Yasnippet parser-level validation guide       |
