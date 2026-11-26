;;; $DOOMDIR/sections/completion.el -*- lexical-binding: t; -*-
;; Company backends and dabbrev configuration.

(setq! abbrev-file-name (expand-file-name "abbrev.el" doom-user-dir))
(setq! save-abbrevs nil)

;; Recognize paths after Markdown's inline-code and link-destination delimiters.
(add-hook! 'markdown-mode-hook
  (require 'company-files)
  (setq-local company-files--regexps (copy-sequence company-files--regexps))
  (add-to-list 'company-files--regexps
               "\\(?:`\\|](\\)\\(\\(?:\\.\\{1,2\\}/\\|~/\\|/\\)[^`) \t\n]*\\)"))

(defun user/company-markdown-files (command &optional arg &rest rest)
  "Use Company file completion without consuming Markdown delimiters."
  (let ((result (apply #'company-files command arg rest)))
    (if (and (eq command 'prefix) (consp result) (stringp (cadr result)))
        (list (car result) (string-trim-right (cadr result) "[`)]"))
      result)))

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

  (set-company-backend! 'org-mode
    'company-files
    '(company-capf :with company-yasnippet)
    '(:separate company-dabbrev company-ispell))

  (set-company-backend! '(markdown-mode gfm-mode)
    'user/company-markdown-files
    'company-files
    '(company-capf :with company-yasnippet)
    '(:separate company-dabbrev company-ispell)))
