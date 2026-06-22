# Sections Split Plan

> **One-shot construction guide.** After execution, `config.el` (with its header
> comment block) is the single authoritative section inventory. This plan goes
> stale once the split is done.

Split `config.el` into a thin loader with universal defaults and section files.
Keep `packages.el` and `init.el` as-is.

This is a **refactoring**: all behavior is preserved, only the file layout changes.

Research backing the approach: popular Doom configs use one of two patterns —
monolithic with headers (hlissner, 205★) or `load!` split with universal
settings in the loader (ztlevi, 223★). Our plan follows the latter, with two
explicit ztlevi-inspired refinements: global-only settings stay directly in
`config.el`, and all keybindings move to a centralized `sections/keys.el` file.

## Motivation

The section headers already exist in `config.el` (`;;; ORG`, `;;; COMPANY`, etc.).
This formalises the existing structure.

**What this gains (ROI):**

| Benefit                                                            | Real at current size?                                       |
| ------------------------------------------------------------------ | ----------------------------------------------------------- |
| `git blame` per feature (isolated file, not shared config.el)      | Yes — meaningful even at this size                          |
| Centralized keybinding inventory                                   | Yes — agents and humans inspect one file for key behavior   |
| Agent-friendly navigation (agents target files, not grep sections) | Yes — agents match `sections/spellcheck.el` by name         |
| Future-proofing for growth past 500 lines                          | Pre-emptive — lighter to do now than during a migration     |
| Easier to review Org-only changes                                  | Yes — diff shows config in sections/org.el, keys in keys.el |

**What this costs:**

- 8 new files + directory structure at repo root
- `(load! ...)` indirection — reading a symbol sometimes requires opening two files
- One more mental model (load order) for what is mostly independent config
- Keybindings are intentionally separated from package config; reviewing a feature
  may require checking both its section file and `sections/keys.el`
- Plan content (split description + notes) goes stale after execution

**Verdict:** Marginal today, better-than-neutral for the next feature addition.
The split is mechanical (copy-paste + `load!`), low risk with `check-parens` and
`doom sync` gates. If the config stays at this size forever, the cost is a few
extra files. If it grows, the structure repays the overhead.

## File Contents — What Goes Where

### config.el (post-split) — thin loader with universal defaults

This is the **only** file whose exact content must be as shown below (it is new
structure, not derived from the current config.el). All other section files are
copied from the existing `;;; HEADER` blocks in config.el.

```elisp
;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here. Section files under sections/
;; are loaded in order below.

;;; UNIVERSAL DEFAULTS — settings that affect Emacs globally, not a specific
;;; package or mode. Every config surveyed (hlissner, ztlevi, tecosaur) keeps
;;; these in the loader rather than moving them to a section file.

;; Ensure pnpm global binaries on exec-path for formatters (prettier, etc.)
;; pnpm stores globals at ~/.local/share/pnpm/bin/ -- independent of fnm.
(let ((pnpm-global (expand-file-name "~/.local/share/pnpm/bin")))
  (when (file-directory-p pnpm-global)
    (add-to-list 'exec-path pnpm-global)))

(setq! delete-by-moving-to-trash t
      window-combination-resize t
      confirm-kill-emacs nil
      confirm-kill-processes nil
      evil-want-fine-undo t
      truncate-string-ellipsis "...")

(global-prettify-symbols-mode 1)
(global-subword-mode 1)
(display-time-mode 1)

;;; SECTIONS — loaded in order (independent of each other).
;;
;;   sections/appearance.el    Font, theme, line-numbers, symbols
;;   sections/spellcheck.el    Jinx spell-checking
;;   sections/org.el           Org, Org-Roam, Org-Roam-UI
;;   sections/completion.el    Company backends, dabbrev
;;   sections/navigation.el    Browser, window management, popups, frame
;;   sections/ui.el            Dirvish, which-key, smartparens, rainbow-delimiters
;;   sections/formatting.el    Ruff (Python), Prettier (Markdown)
;;   sections/keys.el          All keybindings, loaded last
(load! "sections/appearance")
(load! "sections/spellcheck")
(load! "sections/org")
(load! "sections/completion")
(load! "sections/navigation")
(load! "sections/ui")
(load! "sections/formatting")
(load! "sections/keys")
```

**Why some settings stay in config.el and others don't:**

| Belongs in config.el (universal)                      | Belongs in section file (package/mode-specific)     |
| ----------------------------------------------------- | --------------------------------------------------- |
| pnpm path, exec-path setup                            | Jinx config, incf/decf aliases                      |
| `delete-by-moving-to-trash`, `confirm-kill-emacs`     | Org files, Org-Roam, Org-Roam-UI                    |
| `global-prettify-symbols-mode`, `global-subword-mode` | Company backends, dabbrev                           |
| `display-time-mode`                                   | Browser, window/popup management, frame size        |
|                                                       | Dirvish, which-key, smartparens, rainbow-delimiters |
|                                                       | Ruff, Prettier, markdown-open                       |
|                                                       | All keybindings (`sections/keys.el`)                |

The key question for settings: _"Does this setting affect a specific package or
mode?"_ If yes → section file. If it's an Emacs-wide default → config.el.

Keybindings are the deliberate exception to co-location. ztlevi's `+keys.el`
is a strong real-world example: a single key inventory makes global overrides,
leader prefixes, `(:map override ...)`, and `(:after <pkg> :map <map> ...)`
patterns easier to audit than scattered `map!` blocks.

### Section Files — One Per `;;; HEADER` (No defaults.el)

For each `;;; SECTION` header in the current `config.el`, create a section file.
Settings **before** the first `;;;` header (pnpm path, Emacs-wide defaults,
display-time) stay in `config.el` — they are universal, not package-specific.

| config.el header | New file                 | Notes                                                                                                                                  |
| ---------------- | ------------------------ | -------------------------------------------------------------------------------------------------------------------------------------- |
| `;;; APPEARANCE` | `sections/appearance.el` | Font, theme, line-numbers                                                                                                              |
| `;;; SPELLCHECK` | `sections/spellcheck.el` | Jinx use-package! plus incf/decf aliases for Jinx legacy compat; config.el has the universal defaults only                             |
| `;;; ORG`        | `sections/org.el`        | Org, Org-Roam, Org-Roam-UI                                                                                                             |
| `;;; DABBREV`    | `sections/completion.el` | Abbrev file setup (two short `setq!` calls). Merged into completion.el for proximity — sits between ORG and COMPANY in current config. |
| `;;; COMPANY`    | `sections/completion.el` | Company backends                                                                                                                       |
| `;;; NAVIGATION` | `sections/navigation.el` | Browser, window/popup management, frame size                                                                                           |
| `;;; UI`         | `sections/ui.el`         | Dirvish, which-key, smartparens, rainbow-delimiters                                                                                    |
| `;;; FORMATTING` | `sections/formatting.el` | Ruff, Prettier, markdown-open                                                                                                          |
| All `map!` forms | `sections/keys.el`       | Centralized keybinding inventory; loaded last                                                                                          |

Each section file must:

- Start with `;;; $DOOMDIR/sections/<name>.el -*- lexical-binding: t; -*-`
- **With a `;;; HEADER`** — copy from that header through the next header
  (or EOF), except for `map!` forms.
- **All keybindings** — move every `map!` form to `sections/keys.el`, grouped by
  package or prefix. Use `(:after <pkg> :map <map> ...)` inside `map!` for
  package maps and `(:map override ...)` for global overrides that must win
  over minor modes.
- **Without a header** (smartparens after SPELLCHECK, frame size after
  WINDOW) — route by content to the section listed in the table above.
  Verify with the Notes column.
- (spellcheck.el only) The incf/decf aliases for Jinx 2.7 compat go here
  too, alongside the Jinx config they support.

**Verification:** For each section file, diff against the corresponding header
block in the current config.el to confirm content is identical except for
`map!` forms, which are intentionally moved to `sections/keys.el`. The
universal defaults at the top (pnpm path, Emacs-wide settings, display-time)
are NOT copied to section files — they stay in config.el.

## Documentation Updates

All documentation references are **generic** — no per-file listings outside config.el.

### AGENTS.md

Drift prevention table — one row:

```
| config.el | sections/*.el, PROFILE.md, ... | Add/remove (load! ...) lines, update header comment |
```

Agent Workflow — add bullet:

```
- When adding new settings/hooks/advice, place them in the appropriate
  sections/*.el file and register new sections with a (load! ...) line in
  config.el. Place all keybindings in sections/keys.el.
```

### SKILL.md

File Roles table — one row:

```
| sections/        | Split config loaded via (load! ...) from config.el | No       |
| sections/keys.el | Centralized keybinding inventory loaded last       | No       |
```

No Quick Index entry (sections are user config, not agent reference docs).

### README.md

- **Key Features** — add note that per-feature config lives in `sections/*.el`,
  with `config.el` as the loader and `sections/keys.el` as the centralized
  keybinding inventory.
- **Notes** — mention `sections/` as the home for split settings.
- **Agent Script Awareness** — update the config.el reference if the diagram
  mentions config.el file structure.

### PROFILE.md

- **Quick Reference** line 6 — change `"init.el", "config.el", and "packages.el"`
  to `"init.el", "config.el" (loader with universal defaults), "sections/*.el" (per-feature config), "sections/keys.el" (keybindings), and "packages.el"`.
- **Custom Functions** table — `sand/org-display-inline-images-only-in-org` moves
  from `config.el` to `sections/org.el`. Update the Location column.
- **Config Details code blocks** — update each section's file-path header to point
  to the new section file instead of config.el:
  - Jinx spell-checking config -> `sections/spellcheck.el`
  - Dirvish config -> `sections/ui.el`
  - Org-Tempo config -> `sections/org.el`
  - Jinx and Dirvish keybindings -> `sections/keys.el`
    (The code blocks themselves are documentation; they duplicate the section files.
    Do NOT attempt to make PROFILE.md authoritative — it is a human summary. Just
    update the file paths.)

## Validator

Extend `validate-docs.py` with a section inventory pass:

**`section_inventory_findings()`.** Read `(load! "sections/([^"]+)")` lines
from config.el, compare against `sections/*.el` on disk:

- `BROKEN` — load! target file does not exist
- `ORPHAN` — section file exists but is not loaded

Follow the `domain_inventory_findings()` pattern (inventory dict, findings list,
sorted reporting). Wire into `main()` as a new report call alongside the domain
inventory pass.

**Deferred: header-load alignment check.** The comment block (`;; sections/appearance.el ...`)
should list every loaded section in order. A future validator pass could parse
`;; section/file.el` lines from that block and diff against `(load! ...)` lines.
For now, add a `# TODO: check header comment alignment against (load! ...) lines`
in validate-docs.py and revisit if load! reordering becomes routine.

Before editing `validate-docs.py`, load the `python-best-practices` skill
to apply the review checklist (ruff check, py_compile, ruff format --check).

## Execution Steps

0. **Verify clean working tree** — `git status --short` must be empty.
   Commit or stash any pending changes before proceeding.
1. **Create `sections/` directory**
2. **Write each section file** by copying from the corresponding `;;; HEADER`
   block in current config.el (see Section Files table above); verify the
   mode-line header matches `;;; $DOOMDIR/sections/<name>.el`. Do NOT create
   `defaults.el` — the universal settings at the top of config.el (pnpm path,
   Emacs-wide defaults, display-time) stay in config.el. DO create
   `sections/keys.el` and move every `map!` form there.
3. **Verify source completeness** — diff every line of old config.el against
   the new files. Every line must appear in either:
   - config.el (universal defaults + `load!` block)
   - a section file (incf/decf aliases are part of spellcheck.el)
   - sections/keys.el (all `map!` forms)
     There are 8 section files + config.el. Run `wc -l config.el` on old
     config.el to get the expected total.
4. **Replace `config.el`** with the thin loader with universal defaults shown above
5. **Load `python-best-practices` skill**, then extend `validate-docs.py` with
   the section inventory pass (see Validator section). After editing, run
   `ruff format --check scripts/validate-docs.py` (the skill's review checklist
   covers this, but the explicit gate prevents accidental commits).
6. **Run `check-parens`** on all `.el` files (`config.el`, `sections/*.el`)
7. **Run `doom sync`** and verify exit code
8. **Run `doom doctor`** and verify output
   - If sync or doctor fails: fix errors in the affected section file, re-run
     check-parens, re-run sync/doctor. Do not proceed past failure.
9. **Test config load** — `emacs --batch -l ~/.config/doom/config.el --eval='(message "config loaded OK")'`.
   Catches syntax errors and missing dependencies that doom sync's
   byte-compilation might miss.
10. **Update PROFILE.md** — source-of-truth line, Config Details file references,
    Custom Functions table location
11. **Update README.md** — Key Features, Notes, Agent Script Awareness sections
12. **Update AGENTS.md** — drift prevention row + agent workflow bullet
13. **Update SKILL.md** — File Roles row
14. **Run `git diff --check`** to catch whitespace errors
15. **Verify CI triggers are still accurate** — the current `**/*.el` glob
    already covers the new `sections/*.el` files. No change needed. Only add
    or narrow path filters if a future refactoring creates files that shouldn't
    trigger CI (e.g., static data files).
16. **Sync mirror** — `scripts/sync-doom-skill-mirror.sh`;
    verify with `scripts/check-doom-skill-mirror.sh`
17. **Full stale-patterns and Python audit:**
    - `scripts/check-stale-patterns.sh` — cross-reference integrity, script
      inventory, domain file coverage (must report zero findings)
    - `ruff format --check scripts/validate-docs.py` — verifies step 5's
      Python edits are formatted
    - `validate-docs.py` itself — run it to confirm the new section inventory
      pass reports no findings
18. **Commit with decision-aware messages** — `git log` is the historical
    record for agents. Each commit message should capture _why_ a decision
    was made, not just _what_ changed:

    ```
    <action>: <brief summary>

    <context — what problem or principle drove this change>

    <decisions — trade-offs considered, alternatives rejected, rationale>
    ```

    Example:

    ```
    split config into sections with centralized keys

    config.el is now a thin loader — universal Emacs-wide defaults sit
    at the top, then a block of (load! ...) calls for section files.
    incf/decf Jinx legacy aliases go in sections/spellcheck.el alongside
    the Jinx config they support. Keybindings move to sections/keys.el
    as a single searchable inventory, loaded last.

    Aliases are defined at load time via (load! ...), well before any
    :hook can fire at runtime — no silent void-function risk. Centralized
    keys intentionally trade strict co-location for easier audit of global
    overrides, leader prefixes, and package-map bindings.
    ```

    Avoid one-liners like "fix typo" or "update plan" — they tell an agent
    nothing on their own.

### Why shellcheck isn't needed here

The sections split only touches `.el`, `.py`, and `.md` files. No shell
scripts are created or modified. If the split ever requires a new script,
add it and run `shellcheck -x scripts/*.sh` before committing — the CI's
`shellcheck` job enforces this on push for `scripts/*.sh` changes.

## Risks

| Risk                                                              | Mitigation                                                                                                                                                                                        |
| ----------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Spellcheck section includes incf/decf aliases for Jinx 2.7 compat | Solved — aliases live in spellcheck.el alongside the Jinx config they support. Universal defaults in config.el load first, then section files, so incf/decf are defined before any `:hook` fires. |
| Centralized keys drift from package config                        | `sections/keys.el` is loaded last and grouped by package/prefix. Feature review should check both the section file and keys file.                                                                 |
| Load order regression                                             | Sections are independent — no functional coupling. Reorder if needed; any order works.                                                                                                            |
| `(featurep! ...)` guard in navigation.el                          | Already wrapped — stays in the section file.                                                                                                                                                      |
| Emacs won't start                                                 | Step 9 catches this. Rollback: `git checkout config.el && rm -rf sections/`.                                                                                                                      |
| Header comment drifts from load! lines                            | Validator tracks load! vs filesystem but NOT load! vs header comment. The TODO in validate-docs.py flags this gap.                                                                                |
| Section file mode-line path wrong after rename                    | The header `;;; $DOOMDIR/sections/<name>.el` hardcodes the path. Renaming a file without updating the header creates a stale comment. Naming is stable — the risk is low.                         |
| Stale PROFILE.md function locations                               | Step 10 catches this.                                                                                                                                                                             |

## Anti-Drift

- **config.el header block** is the single authoritative listing of all sections.
- **sections/keys.el** is the single authoritative listing of all keybindings.
- **validate-docs.py section inventory pass** checks every `(load! ...)` resolves
  to a file, and flags orphaned section files.
- **validate-docs.py TODO** notes the header-comment alignment gap (deferred).
- **AGENTS.md drift table**: `config.el` -> `sections/*.el`.
- **README.md Key Features**: references sections/ directory structure.
- **PROFILE.md**: queries reference `sections/*.el`, not `config.el` directly.
- **SKILL.md File Roles**: one generic `sections/` row.
- **Agent workflow**: explicit instruction to add new settings/hooks/advice to a
  section file, add new keybindings to `sections/keys.el`, and register new
  section files with a `(load! ...)` line in config.el.
- **Section file headers**: each mode-line comment names the file's own path;
  self-consistent, no cross-file drift.
- No per-file listings outside config.el — no duplication to drift.

---

## Companion: Reference Improvements

Alongside the sections split, the reference documentation was improved to
flatten the discoverability gradient for agents. This was done before the
section split (it affects reference files, not config files) but is
documented here as a companion initiative so the reasoning is not lost.

### Problem

The repo had 11 reference `.md` files across 4 depth tiers. The agent entry
order in `AGENTS.md` listed only 5 of them (`PROFILE.md`, `DOOM-API.md`,
`AGENTS.md`, `references/INDEX.md`, `SKILL.md`). The other 5 files
(`references/package-management.md` and 4 files under
`.agents/skills/doom-emacs/domains/`) were invisible from the entry path — an
agent had to read through all 5 entry files before discovering they existed.
`references/best-practices.md` was created during this initiative to
consolidate scattered guidance.

### Changes Made

| Change                        | File affected                        | Why                                                      |
| ----------------------------- | ------------------------------------ | -------------------------------------------------------- |
| Create best-practices.md      | `references/best-practices.md` (new) | Consolidate scattered guidance into one file             |
| Add Reference Map table       | `AGENTS.md` (Reference Map section)  | Show all 11 files with paths at step 3                   |
| Update entry order            | `AGENTS.md` (Read First)             | Note depth layers exist beyond the 5-step path           |
| Broaden Cross-References      | `AGENTS.md` (table)                  | Include package-management.md and best-practices.md      |
| Drift table update            | `AGENTS.md` (Drift Prevention)       | Add best-practices.md as tracked source of truth         |
| Update Quick Index            | `SKILL.md`                           | Add best-practices.md row                                |
| Update Reference Sources      | `SKILL.md`                           | Add best-practices.md to local refs list                 |
| Update Related Files          | `PROFILE.md`                         | Add best-practices.md                                    |
| Swap entry steps 4 and 5      | `AGENTS.md` (Read First)             | SKILL.md (local) before INDEX.md (external)              |
| Link SS7 to best-practices.md | `DOOM-API.md` (SS7)                  | Agents reading DOOM-API.md find the consolidated ref     |
| Add sibling cross-links       | all 4 `domains/` files               | Any domain file links to the other three                 |
| Broaden source-of-truth       | `PROFILE.md` line 6                  | Mention AGENTS.md and references/ alongside config files |

### What the Reference Map Gives an Agent

When an agent opens this repo cold and reads `AGENTS.md` at step 3, it now
sees a tiered table listing every `.md` file in the repo, its purpose, and
how to discover it. The 5 hidden files are visible immediately — no need to
find them through cross-references.

### Future Reference Work

- If the `domains/` directory grows beyond 6 files, consider a top-level
  index or splitting the Reference Map into sub-tables per tier.
- If upstream Doom module structure changes significantly, audit
  `references/INDEX.md` for stale flag/feature entries.
- After the sections split, audit `references/best-practices.md` §3 (File
  Organization) for accuracy against the new `sections/` structure.
