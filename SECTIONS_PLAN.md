# Sections Split Plan

> **One-shot construction guide.** After execution, `config.el` (with its header
> comment block) is the single authoritative section inventory. This plan goes
> stale once the split is done.

Split `config.el` into a lean loader and section files.
Keep `packages.el` and `init.el` as-is.

## Motivation

The section headers already exist in `config.el` (`;;; ORG`, `;;; COMPANY`, etc.).
This formalises the existing structure.

**What this gains (ROI):**

| Benefit                                                            | Real at current size?                                   |
| ------------------------------------------------------------------ | ------------------------------------------------------- |
| `git blame` per feature (isolated file, not shared config.el)      | Yes — meaningful even at this size                      |
| Agent-friendly navigation (agents target files, not grep sections) | Yes — agents match `sections/spellcheck.el` by name     |
| Future-proofing for growth past 500 lines                          | Pre-emptive — lighter to do now than during a migration |
| Easier to review Org-only changes                                  | Yes — diff shows only sections/org.el                   |

**What this costs:**

- 8 new files + directory structure at repo root
- `(load! ...)` indirection — reading a symbol sometimes requires opening two files
- One more mental model (load order) for what is mostly independent config
- Plan content (split description + notes) goes stale after execution

**Verdict:** Marginal today, better-than-neutral for the next feature addition.
The split is mechanical (copy-paste + `load!`), low risk with `check-parens` and
`doom sync` gates. If the config stays at this size forever, the cost is a few
extra files. If it grows, the structure repays the overhead.

## File Contents — What Goes Where

### config.el (post-split) — single source of truth for section inventory

This is the **only** file whose exact content must be as shown below (it is new
structure, not derived from the current config.el). All other section files are
copied from the existing `;;; HEADER` blocks in config.el.

```elisp
;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here. Section files under sections/
;; are loaded in order below.

;; Ensure pnpm global binaries on exec-path for formatters (prettier, etc.)
;; pnpm stores globals at ~/.local/share/pnpm/bin/ -- independent of fnm.
(let ((pnpm-global (expand-file-name "~/.local/share/pnpm/bin")))
  (when (file-directory-p pnpm-global)
    (add-to-list 'exec-path pnpm-global)))

;; Jinx 2.7 calls legacy bare incf/decf at runtime. Emacs 30 only provides
;; the cl-lib names, so install compatibility aliases here (config.el) so
;; they are loaded before any use-package! :hook can fire. Keeping them
;; out of the section files guarantees load order — moving them into a
;; section file would create a silent void-function risk if the section
;; were reordered past a Jinx-triggering hook.
(require 'cl-lib)
(unless (fboundp 'incf)
  (defalias 'incf #'cl-incf))
(unless (fboundp 'decf)
  (defalias 'decf #'cl-decf))

;; Sections — loaded in order (independent of each other).
;;
;;   sections/defaults.el      Core Emacs behaviour, display-time
;;   sections/appearance.el    Font, theme, line-numbers, symbols
;;   sections/spellcheck.el    Jinx spell-checking
;;   sections/org.el           Org, Org-Roam, Org-Roam-UI
;;   sections/completion.el    Company backends, dabbrev
;;   sections/navigation.el    Browser, window management, popups, frame
;;   sections/ui.el            Dirvish, which-key, smartparens, rainbow-delimiters
;;   sections/formatting.el    Ruff (Python), Prettier (Markdown)
(load! "sections/defaults")
(load! "sections/appearance")
(load! "sections/spellcheck")
(load! "sections/org")
(load! "sections/completion")
(load! "sections/navigation")
(load! "sections/ui")
(load! "sections/formatting")
```

**incf/decf placement rationale:** These aliases are the _only reason_ config.el
is not a pure loader. They must execute before any Jinx autoload fires. Putting
them in config.el (rather than a section file) makes the load guarantee
unambiguous: they run before the first `(load! ...)`, which is before any
`:hook` can trigger. If they were in a section file, a future reorder or
rename could break Jinx silently.

### Section Files — Copied from Current `config.el` Headers

For each `;;; SECTION` header in the current `config.el`, create a section file:

| config.el header                    | New file                 | Notes                                                  |
| ----------------------------------- | ------------------------ | ------------------------------------------------------ |
| _(top of file — before any header)_ | `sections/defaults.el`   | Core Emacs behaviour, display-time                     |
| `;;; APPEARANCE`                    | `sections/appearance.el` | Font, theme, line-numbers                              |
| `;;; SPELLCHECK`                    | `sections/spellcheck.el` | Jinx config only — incf/decf aliases stay in config.el |
| `;;; ORG`                           | `sections/org.el`        | Org, Org-Roam, Org-Roam-UI                             |
| `;;; COMPANY`                       | `sections/completion.el` | Company backends, dabbrev                              |
| `;;; NAVIGATION`                    | `sections/navigation.el` | Browser, window/popup management, frame size           |
| `;;; UI`                            | `sections/ui.el`         | Dirvish, which-key, smartparens, rainbow-delimiters    |
| `;;; FORMATTING`                    | `sections/formatting.el` | Ruff, Prettier, markdown-open                          |

Each section file must:

- Start with `;;; $DOOMDIR/sections/<name>.el -*- lexical-binding: t; -*-`
- Contain exactly the code from under that header in the _current_ config.el
- (spellcheck.el only) Exclude the incf/decf aliases — they stay in config.el.
  Add a comment at the top referencing config.el for those aliases.

**Verification:** For each section file, diff against the corresponding header
block in the current config.el to confirm content is identical.

## Documentation Updates

All documentation references are **generic** — no per-file listings outside config.el.

### AGENTS.md

Drift prevention table — one row:

```
| config.el | sections/*.el, PROFILE.md, ... | Add/remove (load! ...) lines, update header comment |
```

Agent Workflow — add bullet:

```
- When adding new config, place it in the appropriate sections/*.el file
  and register it with a (load! ...) line in config.el.
```

### SKILL.md

File Roles table — one row:

```
| sections/        | Split config loaded via (load! ...) from config.el | No       |
```

No Quick Index entry (sections are user config, not agent reference docs).

### README.md

- **Key Features** — add note that per-feature config lives in `sections/*.el`,
  with `config.el` as the loader.
- **Notes** — mention `sections/` as the home for split settings.
- **Agent Script Awareness** — update the config.el reference if the diagram
  mentions config.el file structure.

### PROFILE.md

- **Quick Reference** line 6 — change `"init.el", "config.el", and "packages.el"`
  to `"init.el", "config.el" (loader), "sections/*.el" (per-feature config), and "packages.el"`.
- **Custom Functions** table — `sand/org-display-inline-images-only-in-org` moves
  from `config.el` to `sections/org.el`. Update the Location column.
- **Config Details code blocks** — update each section's file-path header to point
  to the new section file instead of config.el:
  - Jinx spell-checking config -> `sections/spellcheck.el`
  - Dirvish config -> `sections/ui.el`
  - Org-Tempo config -> `sections/org.el`
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

**Deferred: header-load alignment check.** The comment block (`;; sections/defaults.el ...`)
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
   block in current config.el (see File Contents table above); verify the
   mode-line header matches `;;; $DOOMDIR/sections/<name>.el`
3. **Verify source completeness** — diff every line of old config.el against
   the new files. Every line must appear in either config.el (pnpm, incf/decf,
   load! block) or a section file. Run `wc -l config.el` on old config.el to
   get the expected total.
4. **Replace `config.el`** with the lean loader shown above
5. **Load `python-best-practices` skill**, then extend `validate-docs.py` with
   the section inventory pass (see Validator section)
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
15. **Sync mirror** and run validator (validate-docs.py section inventory pass
    must report zero findings)
16. **Commit** with a message documenting each file change

## Risks

| Risk                                           | Mitigation                                                                                                                                                                                |
| ---------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| incf/decf aliases separated from Jinx config   | Solved by design — aliases stay in config.el (immovable), spellcheck.el only has Jinx use-package!. A cross-reference comment in spellcheck.el points back to config.el.                  |
| Load order regression                          | Sections are independent — no functional coupling. Reorder if needed; any order works.                                                                                                    |
| `(featurep! ...)` guard in navigation.el       | Already wrapped — stays in the section file.                                                                                                                                              |
| Emacs won't start                              | Step 9 catches this. Rollback: `git checkout config.el && rm -rf sections/`.                                                                                                              |
| Header comment drifts from load! lines         | Validator tracks load! vs filesystem but NOT load! vs header comment. The TODO in validate-docs.py flags this gap.                                                                        |
| Section file mode-line path wrong after rename | The header `;;; $DOOMDIR/sections/<name>.el` hardcodes the path. Renaming a file without updating the header creates a stale comment. Naming is stable — the risk is low.                 |
| Root file name collision with section file     | If someone creates `~/.config/doom/defaults.el` and config.el has `(load! "sections/defaults")`, the load is unambiguous. Safer never to have root files named the same as section stems. |
| Stale PROFILE.md function locations            | Step 10 catches this.                                                                                                                                                                     |

## Anti-Drift

- **config.el header block** is the single authoritative listing of all sections.
- **validate-docs.py section inventory pass** checks every `(load! ...)` resolves
  to a file, and flags orphaned section files.
- **validate-docs.py TODO** notes the header-comment alignment gap (deferred).
- **AGENTS.md drift table**: `config.el` -> `sections/*.el`.
- **README.md Key Features**: references sections/ directory structure.
- **PROFILE.md**: queries reference `sections/*.el`, not `config.el` directly.
- **SKILL.md File Roles**: one generic `sections/` row.
- **Agent workflow**: explicit instruction to add new config to a section file
  and register with a `(load! ...)` line in config.el.
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
`AGENTS.md`, `references/INDEX.md`, `SKILL.md`). The other 6 files
(`references/package-management.md`, `references/best-practices.md`, and
4 files under `.agents/skills/doom-emacs/domains/`) were invisible from the
entry path — an agent had to read through all 5 entry files before
discovering they existed.

### Changes Made

| Change                          | File affected                             | Why                                               |
| ------------------------------- | ----------------------------------------- | ------------------------------------------------- |
| Create best-practices.md        | `references/best-practices.md` (new)      | Consolidate scattered guidance into one file      |
| Add Reference Map table         | `AGENTS.md` (Reference Map section)       | Show all 11 files with paths at step 3            |
| Update entry order              | `AGENTS.md` (Read First)                  | Note depth layers exist beyond the 5-step path    |
| Broaden Cross-References        | `AGENTS.md` (table)                       | Include package-management.md and best-practices.md|
| Drift table update              | `AGENTS.md` (Drift Prevention)            | Add best-practices.md as tracked source of truth  |
| Update Quick Index              | `SKILL.md`                                | Add best-practices.md row                         |
| Update Reference Sources        | `SKILL.md`                                | Add best-practices.md to local refs list          |
| Update Related Files            | `PROFILE.md`                              | Add best-practices.md                             |
| Swap entry steps 4 and 5       | `AGENTS.md` (Read First)                  | SKILL.md (local) before INDEX.md (external)      |
| Link SS7 to best-practices.md  | `DOOM-API.md` (SS7)                       | Agents reading DOOM-API.md find the consolidated ref |
| Add sibling cross-links        | all 4 `domains/` files                    | Any domain file links to the other three          |
| Broaden source-of-truth        | `PROFILE.md` line 6                       | Mention AGENTS.md and references/ alongside config files |

### What the Reference Map Gives an Agent

When an agent opens this repo cold and reads `AGENTS.md` at step 3, it now
sees a tiered table listing every `.md` file in the repo, its purpose, and
how to discover it. The 6 hidden files are visible immediately — no need to
find them through cross-references.

### Future Reference Work

- If the `domains/` directory grows beyond 6 files, consider a top-level
  index or splitting the Reference Map into sub-tables per tier.
- If upstream Doom module structure changes significantly, audit
  `references/INDEX.md` for stale flag/feature entries.
- After the sections split, audit `references/best-practices.md` §3 (File
  Organization) for accuracy against the new `sections/` structure.
