;;; $DOOMDIR/sections/org.el -*- lexical-binding: t; -*-
;; Org, Org-Roam, and Org-Roam-UI configuration.

(setq! org-directory "~/notes/org/");  ; Why: central location for all Org files.

(after! org
  (require 'org-tempo)
  (add-hook! 'org-mode-hook #'+org-pretty-mode)

  ;; Inline images
  (setq! org-startup-with-inline-images t
        org-display-remote-inline-images 'cache
        org-image-actual-width 600))

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
