;;; $DOOMDIR/sections/appearance.el -*- lexical-binding: t; -*-
;; Font, theme, and line-number configuration.

(setq! doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 22);  ; Why: larger font for readability on high-resolution display
      doom-variable-pitch-font (font-spec :family "JetBrainsMono Nerd Font" :size 20))

(setq! doom-theme 'doom-tokyo-night);  ; Why: dark theme with blue accents, easy on the eyes.
(setq! display-line-numbers-type t);  ; Why: helps with code navigation and understanding structure.
