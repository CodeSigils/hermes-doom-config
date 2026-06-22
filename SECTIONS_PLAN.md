# Sections Split Plan

Split `config.el` (235 lines) into a lean loader and section files. Keep `packages.el` and `init.el` as-is.

## Motivation

The section headers are already in the file (`;;; ORG`, `;;; COMPANY`, etc.). This formalises the existing
structure and makes `sections/org.el` navigable by filename instead of by scrolling.

## File Contents

### config.el (post-split) — single source of truth for section inventory

```elisp
;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here. Section files under sections/
;; are loaded in dependency order below.

;; Ensure pnpm global binaries on exec-path for formatters (prettier, etc.)
;; pnpm stores globals at ~/.local/share/pnpm/bin/ -- independent of fnm.
(let ((pnpm-global (expand-file-name "~/.local/share/pnpm/bin")))
  (when (file-directory-p pnpm-global)
    (add-to-list 'exec-path pnpm-global)))

;; Sections — loaded in dependency order (least to most dependent).
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

### sections/defaults.el

```elisp
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

```elisp
;;; $DOOMDIR/sections/appearance.el -*- lexical-binding: t; -*-

(setq! doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 22)
      doom-variable-pitch-font (font-spec :family "JetBrainsMono Nerd Font" :size 20))
(setq! doom-theme 'doom-tokyo-night)
(setq! display-line-numbers-type t)

(global-prettify-symbols-mode 1)
(global-subword-mode 1)
```

### sections/spellcheck.el

```elisp
;;; $DOOMDIR/sections/spellcheck.el -*- lexical-binding: t; -*-

;; Fast async spell checking via Enchant/Hunspell.
;; Jinx 2.7 still calls legacy bare `incf`/`decf` at runtime. Emacs 30 only
;; provides the cl-lib names, so install tiny compatibility aliases before Jinx
;; autoloaded commands can run. Keep this out of straight's repo checkout so
;; `doom sync -u` can update Jinx without a dirty worktree prompt.
(require 'cl-lib)
(unless (fboundp 'incf)
  (defalias 'incf #'cl-incf))
(unless (fboundp 'decf)
  (defalias 'decf #'cl-decf))

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

```elisp
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

  ;; Defensive guard: some image/advice integrations can call Org's inline image
  ;; display from non-Org buffers, which makes `org-element' try to parse
  ;; Markdown buffers like AGENTS.md.
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

```elisp
;;; $DOOMDIR/sections/completion.el -*- lexical-binding: t; -*-

;; Dabbrev
(setq! abbrev-file-name (expand-file-name "abbrev.el" doom-user-dir))
(setq! save-abbrevs nil)

;; Company
(after! company
  ;; Doom's Company module is enabled, but its default backend lists do not put
  ;; `company-files' in the common mode backends. Add it explicitly so paths are
  ;; suggested after prefixes like ./, ../, ~/, /, and Org file: links.
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

```elisp
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

```elisp
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

```elisp
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

- **Key Features** section — add note that per-feature config lives in `sections/*.el`,
  with `config.el` as the loader that registers them in dependency order.
- **Notes** section — mention `sections/` directory as the home for split settings.
- **Agent Script Awareness** — update the config.el → sections/\*.el relationship if
  that diagram references config.el file structure.

### PROFILE.md

- **Quick Reference** line 6 — update `"init.el", "config.el", and "packages.el"` to
  `"init.el", "config.el" (loader), "sections/*.el" (per-feature config), and "packages.el"`.
- **Config Details** code blocks — the Jinx spell-checking config (currently cited as
  `config.el` lines 29-53 in line 114) moves to `sections/spellcheck.el`; the Dirvish
  config (line 187) moves to `sections/ui.el`; the Org-Tempo config moves to
  `sections/org.el`. Update the file references in the section headers.
- **Custom Functions** table — `sand/org-display-inline-images-only-in-org` moves from
  `config.el` to `sections/org.el`. Update the Location column in the table (step 9 in
  execution).

## Validator

Extend `validate-docs.py` with a `section_inventory_findings()` function matching the
`domain_inventory_findings()` pattern: read `(load! "sections/([^"]+)"")` lines from config.el,
compare against `sections/*.el` on disk, flag BROKEN (load! target missing) and
ORPHAN (file not loaded). Wire into `main()` as a new report pass.

Before editing `validate-docs.py`, load the `python-best-practices` skill to apply the
review checklist and verification commands (ruff check, py_compile, ruff format --check).

## Execution Steps

1. **Create `sections/` directory**
2. **Write each section file** with the exact content shown above
3. **Replace `config.el`** with the lean loader
4. **Load `python-best-practices` skill**, then extend `validate-docs.py` with section inventory pass
5. **Run `check-parens`** on all `.el` files (`config.el`, `sections/*.el`)
6. **Run `doom sync`** and verify exit code
7. **Run `doom doctor`** and verify output
8. **Start Emacs** and verify it loads cleanly (`emacs --batch --eval='(message "OK")'`)
9. **Update PROFILE.md** — update source-of-truth line, Config Details file references, Custom Functions table location
10. **Update README.md** — Key Features, Notes, Agent Script Awareness sections
11. **Update AGENTS.md** — drift prevention row + agent workflow bullet
12. **Update SKILL.md** — File Roles row
13. **Sync mirror** and run validator
14. **Commit**

## Risks

| Risk                                      | Mitigation                                                                                                         |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| Load order dependency                     | `(load! ...)` lines in config.el are in dependency order above. Reorder if a section needs something from another. |
| `(featurep! ...)` guard in navigation.el  | Already wrapped — stays in the section file.                                                                       |
| Emacs won't start with new load structure | Step 8 catches this. Rollback is `git checkout config.el && rm -rf sections/`.                                     |
| Stale PROFILE.md function locations       | Step 9 — update Location column for `sand/` functions.                                                             |

## Anti-Drift

- **config.el header block** is the single authoritative listing of all sections.
- **validate-docs.py** checks every `(load! "sections/...")` resolves to a file, and flags orphaned section files.
- **AGENTS.md drift table**: `config.el` -> `sections/*.el`.
- **README.md Key Features**: references sections/ directory structure.
- **PROFILE.md**: queries reference `sections/*.el`, not `config.el` directly.
- **SKILL.md File Roles**: one generic `sections/` row.
- **Agent workflow**: explicit instruction to add new config to a section file and register in config.el.
- No per-file listings outside config.el — no duplication to drift.
