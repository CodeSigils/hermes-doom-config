;;; $DOOMDIR/sections/appearance.el -*- lexical-binding: t; -*-
;; Font, theme, and line-number configuration.

(setq! doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 26);  ; Why: larger font for readability on high-resolution display
       doom-variable-pitch-font (font-spec :family "JetBrainsMono Nerd Font" :size 24))

(setq! doom-theme 'doom-tokyo-night);  ; Why: dark theme with blue accents, easy on the eyes.
(setq! display-line-numbers-type t);  ; Why: helps with code navigation and understanding structure.
(when (fboundp 'set-fontset-font) (add-hook! 'after-setting-font-hook (set-fontset-font t 'greek "DejaVu Sans Mono" nil 'append)))
