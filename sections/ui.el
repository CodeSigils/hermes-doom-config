;;; $DOOMDIR/sections/ui.el -*- lexical-binding: t; -*-
;; Dirvish, which-key, smartparens, and rainbow-delimiters configuration.

(after! smartparens
  (show-smartparens-global-mode 1))

(after! dirvish
  (setq! dirvish-attributes '(vc-state nerd-icons subtree-state collapse git-msg file-size))
  (setq! dirvish-subtree-state-style 'nerd)
  (setq! dirvish-path-separators
        (list (format " %s " (nerd-icons-codicon "nf-cod-home"))
              (format " %s " (nerd-icons-codicon "nf-cod-root_folder"))
              (format " %s " (nerd-icons-faicon "nf-fa-angle_right")))))

(after! which-key
  (setq! which-key-min-display-lines 12
        which-key-idle-delay 0.3))

(use-package! rainbow-delimiters
  :hook ((org-mode prog-mode) . rainbow-delimiters-mode))
