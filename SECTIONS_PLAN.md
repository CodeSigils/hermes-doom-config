# Sections Split Plan

> **One-shot construction guide.** The section file contents below document what
> to write — they go stale once the split executes. After execution, `config.el`
> (with its header comment block) is the single authoritative section inventory.

Split `config.el` (235 lines) into a lean loader and section files.
Keep `packages.el` and `init.el` as-is.

## Motivation

The section headers already exist in `config.el` (`;;; ORG`, `;;; COMPANY`, etc.).
This formalises the existing structure.

**What this gains (ROI):**

| Benefit                                                            | Real for 235 lines?                                       |
| ------------------------------------------------------------------ | --------------------------------------------------------- |
| `git blame` per feature (isolated file, not shared config.el)      | Yes — meaningful even at 235 lines                        |
| Agent-friendly navigation (agents target files, not grep sections) | Yes — agents match `sections/spellcheck.el` by name       |
| Future-proofing for growth past 500 lines                          | Pre-emptive — plan is lighter now than during a migration |
| Easier to review Org-only changes                                  | Yes — diff shows only sections/org.el                     |

**What this costs:**

- 8 new files + directory structure at repo root
- `(load! ...)` indirection — reading a symbol sometimes requires opening two files
- One more mental model (load order) for what is mostly independent config
- Plan content (lines 51-311) will go stale immediately after execution

**Verdict:** Marginal today, better-than-neutral for the next feature addition.
The split is mechanical (copy-paste + `load!`), low risk with `check-parens` and
`doom sync` gates. If the config stays at 235 lines forever, the cost is a few
extra files. If it grows, the structure repays the overhead.

## File Contents

### config.el (post-split) — single source of truth for section inventory

```
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

**Note on incf/decf placement:** These aliases are the _only reason_ config.el
is not a pure loader. They must execute before any Jinx autoload fires. Putting
them in config.el (rather than a section file) makes the load guarantee
unambiguous: they run before the first `(load! ...)`, which is before any
`:hook` can trigger. If they were in `sections/spellcheck.el`, a future edit
that reorders or splits that file could break Jinx silently.

### sections/defaults.el

```
;;; $DOOMDIR/sections/defaults.el -*- lexical-binding: t; -*-

(setq! delete-by-moving-to-trash t
      window-combination-resize t
      confirm-kill-emacs nil
      confirm-kill-processes nil
      evil-want-fine-undo t
      truncate-string-ellipsis "...")

;; Time
(setq! display-time-24hr-format t)
(display-time-mode 1)
```

### sections/appearance.el

```
;;; $DOOMDIR/sections/appearance.el -*- lexical-binding: t; -*-

(setq! doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 22)
      doom-variable-pitch-font (font-spec :family "JetBrainsMono Nerd Font" :size 20))
(setq! doom-theme 'doom-tokyo-night)
(setq! display-line-numbers-type t)

(global-prettify-symbols-mode 1)
(global-subword-mode 1)
```

### sections/spellcheck.el

```
;;; $DOOMDIR/sections/spellcheck.el -*- lexical-binding: t; -*-

;; Fast async spell checking via Enchant/Hunspell.
;; incf/decf compatibility aliases are in config.el (loaded before any
;; use-package! :hook can fire). Do not move them into this file — see
;; config.el for rationale.

(use-package! jinx
  :hook ((text-mode prog-mode conf-mode yaml-mode) . jinx-mode)
  :config
  (setq! jinx-languages "en_US")
  (map! "M-$" #'jinx-correct
        "C-M-$" #'jinx-languages
        :leader
        (:prefix ("s" . "spelling")
         :desc "Correct word" "c" #'jinx-correct
         :desc "Next misspelling" "n" #'jinx-next
         :desc "Previous misspelling" "p" #'jinx-previous)))
```

### sections/org.el

```
;;; $DOOMDIR/sections/org.el -*- lexical-binding: t; -*-

(setq! org-directory "~/notes/org/")

(defun sand/org-display-inline-images-only-in-org (fn &rest args)
  "Only run Org inline-image display in Org buffers."
  (when (derived-mode-p 'org-mode)
    (apply fn args)))

(after! org
  (require 'org-tempo)
  (add-hook! 'org-mode-hook #'+org-pretty-mode)

  ;; Inline images
  (setq! org-startup-with-inline-images t
        org-display-remote-inline-images 'cache
        org-image-actual-width 600)

  ;; Defensive guard: some image/advice integrations can call Org's inline
  ;; image display from non-Org buffers, which makes `org-element' try to
  ;; parse Markdown buffers like AGENTS.md.
  (advice-add #'org-display-inline-images
              :around #'sand/org-display-inline-images-only-in-org)
  (when (fboundp 'org-display-user-inline-images)
    (advice-remove #'org-display-inline-images
                   #'org-display-user-inline-images)))

;; Org Roam
(setq! org-roam-directory "~/notes/org/roam")

(after! org-roam
  (when (fboundp 'org-roam-db-autosync-mode)
    (org-roam-db-autosync-mode 1)))

(use-package! org-roam-ui
  :after org-roam
  :commands org-roam-ui-mode
  :config
  (setq! org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-update-on-save t))
```

### sections/completion.el

```
;;; $DOOMDIR/sections/completion.el -*- lexical-binding: t; -*-

;; Dabbrev
(setq! abbrev-file-name (expand-file-name "abbrev.el" doom-user-dir))
(setq! save-abbrevs nil)

;; Company
(after! company
  ;; Doom's Company module is enabled, but its default backend lists do not
  ;; put `company-files' in the common mode backends. Add it explicitly so
  ;; paths are suggested after prefixes like ./, ../, ~/, /, and Org file:
  ;; links.
  (setq! company-idle-delay 0.2
        company-minimum-prefix-length 1
        company-tooltip-limit 12
        company-tooltip-align-annotations t
        company-require-match 'never
        company-selection-wrap-around t
        company-show-numbers t
        ;; Search same-mode buffers for dabbrev without scanning every buffer.
        company-dabbrev-other-buffers t
        company-dabbrev-code-other-buffers t)

  (set-company-backend! 'prog-mode
    'company-files
    '(company-capf :with company-yasnippet)
    'company-dabbrev-code)

  (set-company-backend! 'conf-mode
    'company-files
    '(company-capf :with company-yasnippet)
    'company-dabbrev-code)

  (set-company-backend! 'text-mode
    'company-files
    '(:separate company-dabbrev company-yasnippet company-ispell))

  (set-company-backend! '(org-mode markdown-mode)
    'company-files
    '(company-capf :with company-yasnippet)
    '(:separate company-dabbrev company-ispell)))
```

### sections/navigation.el

```
;;; $DOOMDIR/sections/navigation.el -*- lexical-binding: t; -*-

;; Browser
(when-let ((browser (getenv "BROWSER")))
  (setq! browse-url-browser-function 'browse-url-generic
        browse-url-generic-program browser))

;; Window management
(setq! switch-to-buffer-obey-display-actions t)
(winner-mode 1)

(defun sand/split-window-sensibly (&optional window)
  "Prefer side-by-side splits, then fall back to below splits."
  (let ((window (or window (selected-window))))
    (or (and (window-splittable-p window t)
             (with-selected-window window
               (split-window-right)))
        (and (window-splittable-p window)
             (with-selected-window window
               (split-window-below))))))

(setq! split-window-preferred-function #'sand/split-window-sensibly)

;; Popups — keep common transient/help buffers out of the main editing layout
;; (boundary note: these use :ui popup features, placed here for window
;;  management grouping — could also live in ui.el)
(when (featurep! :ui popup)
  (set-popup-rule! "^\\*\\(?:Help\\|Apropos\\|Warnings\\|Backtrace\\|Messages\\|Completions\\)\\*"
    :size 0.35 :ttl 0 :quit t :select nil)
  (set-popup-rule! "^\\*\\(?:Compile-Log\\|compilation\\|Shell Command Output\\|Async Shell Command\\)\\*"
    :size 0.3 :ttl 0 :quit t :select nil)
  (set-popup-rule! "^\\*doom:[^*]+\\*"
    :size 0.35 :ttl 0 :quit t :select nil))

;; Initial frame size
(defun sand/initial-frame-size ()
  "Return a monitor-aware initial frame size."
  (cond
   ((>= (display-pixel-width) 2560) '((width . 140) (height . 60)))
   ((>= (display-pixel-width) 1920) '((width . 124) (height . 55)))
   (t '((width . 100) (height . 45)))))

(setq! initial-frame-alist
      (append '((top . 1) (left . 1))
              (sand/initial-frame-size)))
```

### sections/ui.el

```
;;; $DOOMDIR/sections/ui.el -*- lexical-binding: t; -*-

;; Smartparens
(after! smartparens
  (show-smartparens-global-mode 1))

;; Dirvish
(map! :leader :desc "Dirvish dwim" "d d" #'dirvish-dwim)

(after! dirvish
  (setq! dirvish-attributes '(vc-state nerd-icons subtree-state collapse git-msg file-size))
  (setq! dirvish-subtree-state-style 'nerd)
  (setq! dirvish-path-separators
        (list (format " %s " (nerd-icons-codicon "nf-cod-home"))
              (format " %s " (nerd-icons-codicon "nf-cod-root_folder"))
              (format " %s " (nerd-icons-faicon "nf-fa-angle_right")))))

;; Which-key
(after! which-key
  (setq! which-key-min-display-lines 12
        which-key-idle-delay 0.3))

;; Rainbow delimiters
(use-package! rainbow-delimiters
  :hook ((org-mode prog-mode) . rainbow-delimiters-mode))
```

### sections/formatting.el

```
;;; $DOOMDIR/sections/formatting.el -*- lexical-binding: t; -*-

;; Python formatting (ruff)
;; Ruff is on PATH at ~/.local/bin/ruff, installed via pnpm global.
;; Doom's (format +onsave) + apheleia autodetects it, but be explicit.
(after! python
  (set-formatter! 'ruff "ruff format --stdin-filename=%b -"
    :modes '(python-mode))
  (setq! +format-with-lsp nil))

;; Markdown formatting (prettier)
;; Prettier handles markdown structure: tables, list indentation, fences.
;; Installed globally via pnpm at ~/.local/share/pnpm/bin/prettier.
(use-package! apheleia
  :config
  (setf (alist-get 'prettier-markdown apheleia-formatters)
        '("prettier" "--parser" "markdown"))
  (setf (alist-get 'markdown-mode apheleia-mode-alist) 'prettier-markdown)
  (setf (alist-get 'gfm-mode apheleia-mode-alist) 'prettier-markdown))

;; Use marked for compilation so markdown-open renders HTML in BrowserOS
(after! markdown-mode
  (setq! markdown-open-command
        (lambda ()
          (interactive)
          (let ((browse-url-browser-function 'browse-url-xdg-open))
            (browse-url-of-buffer
             (markdown-standalone (generate-new-buffer-name "*marked*")))))))
```

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
  - Jinx spell-checking config → `sections/spellcheck.el`
  - Dirvish config → `sections/ui.el`
  - Org-Tempo config → `sections/org.el`
    (The code blocks themselves are documentation; they duplicate what's in the
    section files. Do NOT attempt to make PROFILE.md authoritative — it is a
    human summary, not a drift-free source of truth. Just update the file paths.)

## Validator

Extend `validate-docs.py` with two new passes:

**1. Section inventory (`section_inventory_findings()`).**
Read `(load! "sections/([^"]+)")` lines from config.el,
compare against `sections/*.el` on disk:

- `BROKEN` — load! target file does not exist
- `ORPHAN` — section file exists but is not loaded

Follow the `domain_inventory_findings()` pattern in the existing code
(inventory dict, findings list, sorted reporting). Wire into `main()` as a
new report call alongside the domain inventory pass.

**2. Header-load alignment (future — add as comment only for now).**
The header comment block (`;; sections/defaults.el ...`) should list every
section that has a `(load! ...)` line, in the same order. This is not yet
automated — add a `# TODO:` in validate-docs.py noting the gap. Implementing
it requires parsing `;; section/file.el` lines from the comment block, which
is more complex than the regex for `(load! ...)` lines.

Before editing `validate-docs.py`, load the `python-best-practices` skill
to apply the review checklist (ruff check, py_compile, ruff format --check).

## Execution Steps

1. **Create `sections/` directory**
2. **Write each section file** with the exact content shown above; verify each
   mode-line header matches the file's path (`;;; $DOOMDIR/sections/<name>.el`)
3. **Verify source completeness** — diff the old config.el line by line against
   the new section files. All 235 lines must be accounted for. <!--- stale-check: allow -->
4. **Replace `config.el`** with the lean loader shown above (incf/decf aliases,
   pnpm setup, load! block, no section body content)
5. **Load `python-best-practices` skill**, then extend `validate-docs.py` with
   the section inventory pass (see Validator section)
6. **Run `check-parens`** on all `.el` files (`config.el`, `sections/*.el`)
7. **Run `doom sync`** and verify exit code
8. **Run `doom doctor`** and verify output
   - If doom sync or doctor fails: fix the reported errors in the affected
     section file, re-run check-parens, re-run sync/doctor. Do not proceed
     past a failed step.
9. **Test config load** — `emacs --batch -l ~/.config/doom/config.el \
--eval='(message "config loaded OK")'`. This catches syntax errors and
   missing dependencies that doom sync's byte-compilation might miss.
10. **Update PROFILE.md** — source-of-truth line, Config Details file references,
    Custom Functions table location
11. **Update README.md** — Key Features, Notes, Agent Script Awareness sections
12. **Update AGENTS.md** — drift prevention row + agent workflow bullet
13. **Update SKILL.md** — File Roles row
14. **Run `git diff --check`** to catch whitespace errors
15. **Sync mirror** and run validator
16. **Commit** with a message documenting each file change

## Risks

| Risk                                           | Mitigation                                                                                                                                                                                |
| ---------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| incf/decf aliases separated from Jinx config   | Solved by design — aliases stay in config.el (immovable), spellcheck.el only has use-package! jinx. A cross-reference comment in spellcheck.el points back to config.el.                  |
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
- **validate-docs.py TODO** notes the header-comment alignment gap.
- **AGENTS.md drift table**: `config.el` -> `sections/*.el`.
- **README.md Key Features**: references sections/ directory structure.
- **PROFILE.md**: queries reference `sections/*.el`, not `config.el` directly.
- **SKILL.md File Roles**: one generic `sections/` row.
- **Agent workflow**: explicit instruction to add new config to a section file
  and register with a `(load! ...)` line in config.el.
- **Section file headers**: each mode-line comment names the file's own path;
  self-consistent, no cross-file drift.
- No per-file listings outside config.el — no duplication to drift.
