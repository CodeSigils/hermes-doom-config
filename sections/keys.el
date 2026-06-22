;;; $DOOMDIR/sections/keys.el -*- lexical-binding: t; -*-
;; All keybindings, loaded last.

(map! "M-$" #'jinx-correct
      "C-M-$" #'jinx-languages
      :leader
      (:prefix ("s" . "spelling")
       :desc "Correct word" "c" #'jinx-correct
       :desc "Next misspelling" "n" #'jinx-next
       :desc "Previous misspelling" "p" #'jinx-previous))

;; Keep the launcher binding available immediately; the command is autoloaded.
(map! :leader :desc "Dirvish dwim" "d d" #'dirvish-dwim)
