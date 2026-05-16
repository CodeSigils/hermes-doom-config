;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 22)
      doom-variable-pitch-font (font-spec :family "JetBrainsMono Nerd Font" :size 20))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-tokyo-night)
;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)
;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/notes/org/")

;;; EMACS DEFAULTS
(setq delete-by-moving-to-trash t
      window-combination-resize t
      confirm-kill-emacs nil
      confirm-kill-processes nil
      evil-want-fine-undo t
      truncate-string-ellipsis "..."
      password-cache-expiry nil)

(global-prettify-symbols-mode 1)
(global-subword-mode 1)

;; Enable spell checking broadly. Flyspell has no built-in global mode, so use
;; hooks: full checks in prose buffers, comment/string checks elsewhere.
(add-hook! '(org-mode-hook markdown-mode-hook text-mode-hook) #'flyspell-mode)
(add-hook! '(prog-mode-hook conf-mode-hook yaml-mode-hook) #'flyspell-prog-mode)

(after! smartparens
  (show-smartparens-global-mode 1))

;;; ORG
(defun sand/org-display-inline-images-only-in-org (fn &rest args)
  "Only run Org inline-image display in Org buffers."
  (when (derived-mode-p 'org-mode)
    (apply fn args)))

(after! org
  (add-hook 'org-mode-hook #'+org-pretty-mode)

  ;; Inline images
  (setq org-startup-with-inline-images t
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

;;; ORG ROAM
(setq org-roam-directory "~/notes/org/roam")

(after! org-roam
  (when (fboundp 'org-roam-db-autosync-mode)
    (org-roam-db-autosync-mode 1)))  ;; Enables automatic sync

;; Org roam UI - external package
(use-package! org-roam-ui
  :after org-roam
  :commands org-roam-ui-mode
  :config
  (setq org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-update-on-save t))

;;; DABBREV
;; (setq-default abbrev-mode t)
(setq abbrev-file-name (expand-file-name "abbrev.el" doom-user-dir))
(setq save-abbrevs nil)

;;; COMPANY
(after! company
  ;; Doom's Company module is enabled, but its default backend lists do not put
  ;; `company-files' in the common mode backends. Add it explicitly so paths are
  ;; suggested after prefixes like ./, ../, ~/, /, and Org file: links.
  (setq company-idle-delay 0.2
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

;;; BROWSER
(when-let ((browser (getenv "BROWSER")))
  (setq browse-url-browser-function 'browse-url-generic
        browse-url-generic-program browser))

;;; WINDOW
;; Use Doom/window display rules rather than advising low-level window
;; primitives like `window-split'.
(setq switch-to-buffer-obey-display-actions t)

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

(setq split-window-preferred-function #'sand/split-window-sensibly)

;; Keep common transient/help buffers out of the main editing layout without
;; capturing every star buffer.
(when (featurep! :ui popup)
  (set-popup-rule! "^\\*\\(?:Help\\|Apropos\\|Warnings\\|Backtrace\\|Messages\\|Completions\\)\\*"
    :size 0.35 :ttl 0 :quit t :select nil)
  (set-popup-rule! "^\\*\\(?:Compile-Log\\|compilation\\|Shell Command Output\\|Async Shell Command\\)\\*"
    :size 0.3 :ttl 0 :quit t :select nil)
  (set-popup-rule! "^\\*doom:[^*]+\\*"
    :size 0.35 :ttl 0 :quit t :select nil))

(defun sand/initial-frame-size ()
  "Return a monitor-aware initial frame size."
  (cond
   ((>= (display-pixel-width) 2560) '((width . 140) (height . 60)))
   ((>= (display-pixel-width) 1920) '((width . 124) (height . 55)))
   (t '((width . 100) (height . 45)))))

(setq initial-frame-alist
      (append '((top . 1) (left . 1))
              (sand/initial-frame-size)))

;;; DIRVISH
(after! dirvish
  (setq dirvish-attributes '(vc-state nerd-icons subtree-state collapse git-msg file-size))
  (setq dirvish-subtree-state-style 'nerd)
  (setq dirvish-path-separators
        (list (format " %s " (nerd-icons-codicon "nf-cod-home"))
              (format " %s " (nerd-icons-codicon "nf-cod-root_folder"))
              (format " %s " (nerd-icons-faicon "nf-fa-angle_right"))))
  ;; Dirvish keys
  (map! :leader :desc "Dirvish dwim" "d d" #'dirvish-dwim))

;;; TIME
(setq display-time-24hr-format t)
(display-time-mode 1)

;;; WHICH KEY
(after! which-key
  (setq which-key-min-display-lines 12
        which-key-idle-delay 0.3))

;;; RAINBOW DELIMITERS
(use-package! rainbow-delimiters
  :hook ((org-mode prog-mode) . rainbow-delimiters-mode))


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `with-eval-after-load' block, otherwise Doom's defaults may override your
;; settings. E.g.
;;
;;   (with-eval-after-load 'PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look them up).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
