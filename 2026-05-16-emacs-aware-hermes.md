# Emacs-Aware Hermes — Execution Summary

**Goal:** Make Hermes reliably competent at configuring Doom Emacs — understanding Doom's module system, API, package management, and user-specific conventions — so it can modify `config.el`, `init.el`, and `packages.el` with the same fluency it has for Python projects.

**Status: COMPLETE** — All 8 tasks executed on 2026-05-16.

**Architecture:** Three layers: (1) a dedicated Hermes skill for Doom config procedures, (2) a reference document covering Doom's API surface and safe patterns, and (3) enhancements to the existing AGENTS.md for user-specific guardrails. The skill files are mirrored into `skills/` within the repo for portability — anyone cloning `~/.config/doom/` has the full reference.

**Why this matters:** Currently Hermes has to learn Doom conventions from scratch every time. A lot of Doom's API (`use-package!`, `after!`, `set-company-backend!`, `featurep!`, `map!`) is not standard Emacs Lisp — without that knowledge in context, Hermes generates naive config that would need human editing. This plan closes that gap.

---

## Task 1: Create `doom-emacs-config` Hermes Skill

**Status: DONE**

**Location:** `~/.hermes/skills/emacs/doom-emacs-config/SKILL.md`

**Content sections:**

1. File roles and responsibilities:
   - `init.el` = module declarations only (which modules, what flags)
   - `packages.el` = external package installation
   - `config.el` = everything else (settings, keybinds, hooks, advice)
2. Doom API quick-reference (see Task 2 for the full version; skill covers just what's needed for procedures)
3. Procedures for common tasks:
   - Adding a new module to `init.el` (comment disabled ones, uncomment to enable)
   - Installing a MELPA package / git package in `packages.el`
   - Adding a mode hook
   - Configuring a built-in Doom module (e.g., company, org, lsp)
   - Adding a keybinding with `map!`
4. Safety procedures:
   - After `init.el` or `packages.el` changes: run `doom sync`
   - Before committing: run `check-parens` on the changed file
   - After `config.el` changes: restart Emacs or `eval-buffer`
5. Integration with user's AGENTS.md (load and read it before modifying anything)

**Trigger conditions:** Skill loads when user mentions Doom Emacs, config.el, init.el, packages.el, or asks to configure Emacs.

---

## Task 2: Create Doom API Quick-Reference File

**Status: DONE**

**Location:** `~/.hermes/skills/emacs/doom-emacs-config/references/doom-api.md`

**Content (covers the non-standard patterns Hermes most often gets wrong):**

| Macro/API              | Purpose                                          | Example                                                 |
| :--------------------- | :----------------------------------------------- | :------------------------------------------------------ |
| `after!`               | Defer config until a feature loads               | `(after! org (setq org-adapt-indentation nil))`         |
| `use-package!`         | Declare and configure a package (Doom's wrapper) | `(use-package! foo :defer t :config ...)`               |
| `map!`                 | Set keybindings                                  | `(map! :leader :desc "Foo" "f f" #'foo)`                |
| `set-company-backend!` | Set per-mode company backends                    | `(set-company-backend! 'prog-mode 'company-files ...)`  |
| `set-popup-rule!`      | Control how temporary buffers display            | See config.el lines 139-144                             |
| `featurep!`            | Check if a module is enabled at compile-time     | `(when (featurep! :ui popup) ...)`                      |
| `modulep!`             | Same as featurep!                                | Prefer `featurep!` in modern Doom                       |
| `add-hook!`            | Doom's multi-mode hook helper                    | `(add-hook! '(org-mode markdown-mode) #'flyspell-mode)` |
| `setq-hook!`           | Set a variable only in certain hooks             | `(setq-hook! 'org-mode-hook truncate-lines nil)`        |
| `+` flags              | Module variants                                  | `:completion (company +childframe +tng)`                |

**Also include pitfalls:**

- Doom uses `straight.el` under the hood, not `package.el` — `package!` macro wraps it
- `use-package!` is NOT the same as `use-package` — Doom's version handles deferred loading differently
- `(setq-default ...)` should be `(setq ...)` in most Doom contexts
- Don't use `with-eval-after-load` — use `after!`

---

## Task 3: Enhance AGENTS.md with Doom API Section

**Status: DONE**

- Added "## Doom API Quick Reference" — 8 macros with substitution table
- Added "## Verification Checklist" — doom sync, eval-buffer, check-parens, CLI fallback
- Added "## Elisp Comment Convention" — semicolon hierarchy (;;; vs ;; vs ;)
- Added "## Lexical Binding" — performance and closure correctness
- Updated skill-load line to mention both `emacs-lisp-expert` and `doom-emacs-config`

---

## Task 4: Configure Hermes to Auto-Load the Skill

**Status: DONE**

- AGENTS.md skill-load line updated to require both skills
- Skill frontmatter includes `trigger_keywords` for auto-detection
- Memory updated for cross-session recall

## Task 5: Enable Spell Checking Globally in config.el

**Status: NO CHANGE NEEDED**

Existing flyspell hooks (full checking in prose modes, comment/string checking in prog/conf/yaml modes) already cover all buffer types correctly. Flyspell has no global mode — hooks are the canonical approach.

**Bonus — Restored original Doom template comments to config.el:**

- User identity block and font docs (lines 7-30)
- Theme, line-numbers, and org-directory annotations (lines 35-44)
- Concluding help block with with-eval-after-load, load!, add-load-path!, map! (lines 215-244)
- Source: `~/.config/emacs/static/config.example.el`

## Task 6: Memory Update — Store Doom Config Detail

**Status: DONE**

Doom config structure persisted to Hermes memory. Entry reads:

> Doom: ~/.config/doom/ git,not chezmoi. init/packages/config.el. Company>Corfu. after!/use-package!/map!/add-hook!. Comment,no delete. Flyspell. No Ollama. Skill: doom-emacs-config.

---

## Task 7: Copy Skill Files into Doom Repo for Portability

**Status: DONE**

**Location:** `~/.config/doom/skills/`

Copies of the skill and API reference now live inside the repo so the knowledge
travels with it — no dependency on ~/.hermes/skills/ for anyone cloning the repo.

- `skills/doom-emacs-config.md` — full skill with procedures, safety checks, pitfalls
- `skills/references/doom-api.md` — macro reference, module flags, pitfalls table

AGENTS.md and README.md both updated to point agents at `skills/` as a
fallback: "Local reference copies are in `skills/` if the canonical skills
aren't available."

The canonical source remains `~/.hermes/skills/emacs/doom-emacs-config/`
(Hermes auto-loads from there). The `skills/` copies are a snapshot — sync
them when the canonical skill is updated.

---

**All 8 tasks complete. Plan file updated to execution summary on 2026-05-16.**
