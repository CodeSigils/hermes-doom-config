;;; $DOOMDIR/sections/spellcheck.el -*- lexical-binding: t; -*-
;; Jinx spell-checking configuration.

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
;; For additional languages, install the Hunspell dictionary and Jinx will find it.
(use-package! jinx
  :hook ((text-mode prog-mode conf-mode yaml-mode) . jinx-mode)
  :config
  (setq! jinx-languages "en_US el_GR"))
