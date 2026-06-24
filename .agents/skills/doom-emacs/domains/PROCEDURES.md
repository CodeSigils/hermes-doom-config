# Doom Config Procedures

Step-by-step instructions for common config tasks. Read this when you need to make a concrete change to `init.el`,
`packages.el`, or `config.el`.

**Parent skill:** `SKILL.md` — compact core with file roles, API essentials, safety checks, pitfalls, and the Quick
Index for all domain files. Load SKILL.md first for the minimal context every Doom edit needs.

**Siblings:** `ARCHITECTURE.md`, `ELISP.md`, `PROCEDURES.md`, `TROUBLESHOOTING.md` — depth guides for framework,
elisp, procedures, and troubleshooting.

## A. Adding a Module to init.el

1. Find the appropriate category section under `(doom! ...)`
2. Uncomment the module line (never delete commented modules)
3. Consult the module's README.org at `~/.config/emacs/modules/<cat>/<mod>/` to verify available flags
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

See `references/package-management.md` for pinning, updates, straight recipes, and lockfile troubleshooting.

## C. Adding a Mode Hook

Use Doom's `add-hook!` helper from `config.el`:

```elisp
(add-hook! '(mode1-mode-hook mode2-mode-hook) #'some-minor-mode)
(add-hook! 'prog-mode-hook #'some-global-thing)

;; Run at the end of the hook chain
(add-hook! 'some-mode :append #'enable-something)
;; Buffer-local hook (runs only in that buffer)
(add-hook! 'some-mode :local #'enable-something)
;; Inline named function — avoids a top-level defun
(add-hook! 'some-mode (defun user/setup () (setq-local x 5)))
```

## D. Configuring a Built-in Module

Use `after!` in `config.el`:

```elisp
(after! company
  (setq company-idle-delay 0.2)
  (set-company-backend! 'prog-mode 'company-files ...))

;; Compound: wait for any package
(after! (:or magit diff-hl)
  (do-something))
;; Compound: wait for a specific combination
(after! (:and org (:or python sh))
  (do-something))
```

Do not try to `use-package!` modules that Doom already manages. Use `after!`.

## E. Setting a Keybinding

Use `map!` in `sections/keys.el` (this repo centralizes all keybindings there):

```elisp
(map! :leader :desc "Description" "f f" #'some-command)
(map! :n "C-c C-f" #'find-file)  ; Normal mode only

;; Conditional — only if a module is enabled
(map! (:when (modulep! :completion company) :i "C-@" #'+company/complete))

;; Nested prefix group
(map! (:prefix "C-x" :i "C-l" #'+company/whole-lines))

;; Unbind a key set elsewhere
(map! :map lua-mode-map "SPC m b" nil)
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

Do not skip the backup. Framework changes can introduce API changes that break your config.

## H. Running a Config Maintenance Audit

Periodically audit the config repo for drift between documentation and actual state:

1. Read `init.el` and derive the actual enabled module inventory (active vs commented).
2. Compare README feature/module claims against that inventory — fix any claims for commented modules.
3. Check `git status --short` and tracked runtime artifacts (`git ls-files`). Runtime DB files
   (`.open-mem/memory.db*`, etc.) should be gitignored, not committed.
4. Run `doom doctor` — classify warnings as expected optional dependencies or config issues.
5. Run the stale-patterns check: `scripts/check-stale-patterns.sh`.
6. Check comments in config files for stale upstream Doom template advice
   (`with-eval-after-load`, standard `use-package`, deleting module lines, etc.).
7. Verify the snippet directory (if present) is documented in README.
8. Cross-check `.agents/` files (SKILL.md, domains/) against source config files and `DOOM-API.md` for stale patterns, missing updates, or drift from documented best practices.

## I. Evaluating a New Doom Package (Research Template)

Use this template when researching a package not yet installed. Example: evaluating
[xenodium/agent-shell](https://github.com/xenodium/agent-shell) — a native Emacs ACP agent UI.

**Research notes template:**

````markdown
## <Package Name> — <Brief Purpose>

**Current status:** not installed — evaluation only.

**Doom install:**

```elisp
;; packages.el
(package! <dependency-1>)
(package! <dependency-2>)
(package! <package-name>)

;; config.el
(after! <package-name>
  (setq <option> <value>))
```
````

**Known pitfalls:**

- List any gotchas found during evaluation.
- Note provider-specific quirks (e.g. `agent-shell-hermes-acp-command` may use
  symbols instead of strings — override with strings in Doom config).
- Check whether `executable-find` and `make-process` expect command strings, not symbols.

**Safety defaults for first trial:**

- Start conservatively: disable file access, text file capabilities.
- Do not globally enable auto-approval helpers.
- Add keybindings only after the basic flow works.

**Cross-check against upstream:**

- Verify the package's Doom install docs match the current Doom version.
- Check `doom doctor` for conflicts with enabled modules.
- If the package needs a CLI tool, add it to PROFILE.md system dependencies.

Remove this section once the research concludes and the result (installed or rejected) is documented.
