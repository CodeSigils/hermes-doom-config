;;; $DOOMDIR/sections/org.el -*- lexical-binding: t; -*-
;; Org, Org-Roam, and Org-Roam-UI configuration.

(setq! org-directory "~/notes/org/");  ; Why: central location for all Org files.

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

(setq! org-roam-directory "~/notes/org/roam");  ; Why: separate directory for Org Roam notes to keep them organized.

(after! org-roam
  (when (fboundp 'org-roam-db-autosync-mode)
    (org-roam-db-autosync-mode 1)))  ;; Enables automatic sync

(use-package! org-roam-ui
  :after org-roam
  :commands org-roam-ui-mode
  :config
  (setq! org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-update-on-save t))
