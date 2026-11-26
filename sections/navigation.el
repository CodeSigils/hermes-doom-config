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

(defvar user/frame-geometry-file
  (expand-file-name ".frame-geometry" "~/.local/share/doom/")
  "File storing last frame width/height for persistence across sessions.")

(defun user/initial-frame-size ()
  "Return saved frame geometry, or pixel-width-based defaults.
Saves last geometry on exit so Emacs remembers your manual resizes."
  (or (user/load-frame-geometry)
      (cond
       ((>= (display-pixel-width) 2560) '((width . 140) (height . 60)))
       ((>= (display-pixel-width) 1920) '((width . 124) (height . 55)))
       (t '((width . 100) (height . 45))))))

(defun user/load-frame-geometry ()
  "Read saved native pixel geometry as text-area pixel parameters."
  (when (file-exists-p user/frame-geometry-file)
    (condition-case nil
        (with-temp-buffer
          (insert-file-contents user/frame-geometry-file)
          (let* ((geometry (read (current-buffer)))
                 (width (alist-get 'width geometry))
                 (height (alist-get 'height geometry)))
            (when (and (integerp width) (> width 0)
                       (integerp height) (> height 0))
              `((width . (text-pixels . ,(max 1 (- width (- (frame-pixel-width) (frame-text-width))))))
                (height . (text-pixels . ,(max 1 (- height (- (frame-pixel-height) (frame-text-height))))))))))
      (error nil))))

(defun user/save-frame-geometry ()
  "Save current frame pixel width and height for next session."
  (when (display-graphic-p)
    (let ((params `((width . ,(frame-pixel-width))
                    (height . ,(frame-pixel-height)))))
      (with-temp-file user/frame-geometry-file
        (insert (prin1-to-string params))))))

;; Remember frame size across restarts
(add-hook 'kill-emacs-hook #'user/save-frame-geometry)

(setq! initial-frame-alist
      (append '((top . 1) (left . 1))
              (user/initial-frame-size)))
