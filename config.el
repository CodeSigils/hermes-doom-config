;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here. Section files under sections/
;; are loaded in order below.

;;; UNIVERSAL DEFAULTS — settings that affect Emacs globally, not a specific
;;; package or mode. Every config surveyed (hlissner, ztlevi, tecosaur) keeps
;;; these in the loader rather than moving them to a section file.

;; Identity used by GPG, email, file templates, and snippets.
;; Read from ~/.gitconfig so there's one source of truth — change it in git
;; config and Emacs picks it up after a restart, no config file edit needed.
;; Falls back to the OS-level default if gitconfig values are missing.
(defun user/git-config (key)
  "Return value of git config KEY from the global gitconfig, or nil."
  (with-temp-buffer
    (when (zerop (call-process "git" nil t nil "config" "--global" key))
      (string-trim (buffer-string)))))
(let ((name (user/git-config "user.name"))
      (email (user/git-config "user.email")))
  (when name  (setq user-full-name name))
  (when email (setq user-mail-address email)))

;; Ensure pnpm global binaries are on exec-path for formatters (prettier, etc.)
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
(setq! display-time-24hr-format t)
(display-time-mode 1)

;;; SECTIONS — loaded in reviewed order; keys loaded last.
(load! "sections/appearance") ;; Font, theme, line-numbers
(load! "sections/spellcheck") ;; Jinx spell-checking
(load! "sections/org")        ;; Org, Org-Roam, Org-Roam-UI
(load! "sections/completion") ;; Company backends, dabbrev
(load! "sections/navigation") ;; Browser, window management, popups, frame
(load! "sections/ui")         ;; Dirvish, which-key, smartparens, rainbow-delimiters
(load! "sections/formatting") ;; Ruff (Python), Prettier (Markdown)
(load! "sections/keys")       ;; All keybindings, loaded last
