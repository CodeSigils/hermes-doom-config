;;; input.el --- Greek input method toggle -*- lexical-binding: t; -*-
;; Private input-method configuration.

(defun user/greek-input-method ()
  "Toggle Emacs' built-in Greek input method on or off."
  (interactive)
  (if (and current-input-method (string= current-input-method "greek"))
      (deactivate-input-method)
    (set-input-method "greek")))

(provide 'user-input)
