;;; $DOOMDIR/sections/navigation.el -*- lexical-binding: t; -*-
;; Browser, window management, popups, and frame configuration.

(when-let ((browser (getenv "BROWSER")))
  (setq! browse-url-browser-function 'browse-url-generic
        browse-url-generic-program browser))

;; Use Doom/window display rules rather than advising low-level window
;; primitives like `window-split'.
(setq! switch-to-buffer-obey-display-actions t)

(winner-mode 1)

(defun user/split-window-sensibly (&optional window)
  "Prefer side-by-side splits, then fall back to below splits."
  (let ((window (or window (selected-window))))
    (or (and (window-splittable-p window t)
             (with-selected-window window
               (split-window-right)))
        (and (window-splittable-p window)
             (with-selected-window window
               (split-window-below))))))

(setq! split-window-preferred-function #'user/split-window-sensibly)

;; Keep common transient/help buffers out of the main editing layout without
;; capturing every star buffer.
(when (modulep! :ui popup)
  (set-popup-rule! "^\\*\\(?:Help\\|Apropos\\|Warnings\\|Backtrace\\|Messages\\|Completions\\)\\*"
    :size 0.35 :ttl 0 :quit t :select nil)
  (set-popup-rule! "^\\*\\(?:Compile-Log\\|compilation\\|Shell Command Output\\|Async Shell Command\\)\\*"
    :size 0.3 :ttl 0 :quit t :select nil)
  (set-popup-rule! "^\\*doom:[^*]+\\*"
    :size 0.35 :ttl 0 :quit t :select nil))

(defun user/initial-frame-size ()
  "Return a monitor-aware initial frame size."
  (cond
   ((>= (display-pixel-width) 2560) '((width . 140) (height . 60)))
   ((>= (display-pixel-width) 1920) '((width . 124) (height . 55)))
   (t '((width . 100) (height . 45)))))

(setq! initial-frame-alist
      (append '((top . 1) (left . 1))
              (user/initial-frame-size)))
