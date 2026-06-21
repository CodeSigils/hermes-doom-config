# Doom Config Procedures

Step-by-step instructions for common config tasks. Read this when you need
to make a concrete change to `init.el`, `packages.el`, or `config.el`.

**Parent skill:** `SKILL.md` — compact core with file roles, API essentials,
safety checks, pitfalls, and the Quick Index for all domain files. Load
SKILL.md first for the minimal context every Doom edit needs.

## A. Adding a Module to init.el

1. Find the appropriate category section under `(doom! ...)`
2. Uncomment the module line (never delete commented modules)
3. Consult the module's README.org at
   `~/.config/emacs/modules/<cat>/<mod>/` to verify available flags
4. Add `+flag` suffixes as needed, e.g. `(org +roam +dragndrop)`
5. Run: `doom sync`
6. Restart Emacs

## B. Installing a Package

1. Add to `packages.el`:
   - **MELPA:** `(package! package-name)`
   - **Git repo:** `(package! name :recipe (:host github :repo "user/repo"))`
2. Run: `doom sync`
3. Restart Emacs
4. Configure in `config.el` with `use-package!` or `after!`

See `references/package-management.md` for pinning, updates, straight recipes,
and lockfile troubleshooting.

## C. Adding a Mode Hook

Use Doom's `add-hook!` helper from `config.el`:

```elisp
(add-hook! '(mode1-mode-hook mode2-mode-hook) #'some-minor-mode)
(add-hook! 'prog-mode-hook #'some-global-thing)
```

## D. Configuring a Built-in Module

Use `after!` in `config.el`:

```elisp
(after! company
  (setq company-idle-delay 0.2)
  (set-company-backend! 'prog-mode 'company-files ...))
```

Do not try to `use-package!` modules that Doom already manages. Use `after!`.

## E. Setting a Keybinding

Use `map!` in `config.el`:

```elisp
(map! :leader :desc "Description" "f f" #'some-command)
(map! :n "C-c C-f" #'find-file)  ; Normal mode only
```

## F. Enabling a Minor Mode Globally

```elisp
(some-global-mode 1)
;; or via hooks when there's no global mode
(add-hook! '(prog-mode-hook text-mode-hook) #'some-mode)
```

## G. Upgrading the Doom Framework

1. **Backup first:** `cp -a ~/.config/doom ~/.config/doom.backup.$(date +%Y%m%d)`
2. **Run upgrade:** `doom upgrade`
3. **Verify:** `doom sync && doom doctor`
4. **Check doctor output** for deprecation warnings
5. **If something breaks:** restore `~/.config/doom.backup.*` from backup

Do not skip the backup. Framework changes can introduce API changes that break
your config.
