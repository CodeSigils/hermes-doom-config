;;; $DOOMDIR/sections/formatting.el -*- lexical-binding: t; -*-
;; Ruff (Python) and Prettier (Markdown) formatting configuration.

;; Ruff is on PATH at ~/.local/bin/ruff, installed via pnpm global.
;; Doom's (format +onsave) + apheleia autodetects it, but be explicit.
(after! python
  (set-formatter! 'ruff "ruff format --stdin-filename=%b -"
    :modes '(python-mode));  ; Why: use ruff for fast, consistent Python formatting over LSP.
  (setq! +format-with-lsp nil))  ;; prefer ruff over lsp formatting

;; Prettier handles markdown structure: tables, list indentation, fences.
;; Installed globally via pnpm at ~/.local/share/pnpm/bin/prettier.
;; Directly set apheleia alists instead of using set-formatter!, because
;; Doom's markdown module may register its own formatter entry that
;; overrides set-formatter! when markdown-mode is loaded lazily.
(use-package! apheleia
  :defer t
  :config
  (setf (alist-get 'prettier-markdown apheleia-formatters)
        '("prettier" "--parser" "markdown"))
  (setf (alist-get 'markdown-mode apheleia-mode-alist) 'prettier-markdown)
  (setf (alist-get 'gfm-mode apheleia-mode-alist) 'prettier-markdown))

;; Use marked for compilation so markdown-open renders HTML in BrowserOS
;; via browse-url-of-buffer (text/html now routed to browseros.desktop).
;; markdown-open-command can be a function; markdown-mode now rejects nil.
(after! markdown-mode
  (setq! markdown-open-command
        (lambda ()
          (interactive)
          (let ((browse-url-browser-function 'browse-url-xdg-open))
            (browse-url-of-buffer
             (markdown-standalone (generate-new-buffer-name "*marked*")))))))
