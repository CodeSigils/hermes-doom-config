# Doom Package Management Reference

Purpose: document Doom's package lifecycle — declaration, installation,
configuration, update, and troubleshooting — so agents can manage packages
correctly without guesswork.

## TL;DR — The Doom Package Workflow

```
packages.el:  (package! example-package)
    ↓
doom sync:    clones repo → builds → compiles → generates autoloads
    ↓
config.el:    (use-package! example-package :config ...)
    ↓
Restart (or M-x doom/reload)
```

---

## 1. Package Declaration with `package!`

Every external package must be declared in `packages.el` with the `package!`
macro before it can be installed.

### Basic Syntax

```elisp
(package! some-package)
```

This installs from MELPA, ELPA, or Emacsmirror depending on where it's found.
Doom pins all built-in packages to a specific commit. Extra packages outside
that pin list resolve to their latest available version unless a `:recipe` or
`:pin` is provided.

### Options

| Option     | Purpose                                                     | Example                                    |
| ---------- | ----------------------------------------------------------- | ------------------------------------------ |
| `:recipe`  | Install from a specific source (git repo, local path, etc.) | `:recipe (:host github :repo "user/repo")` |
| `:pin`     | Pin to a specific commit                                    | `:pin "1a2b3c4d"`                          |
| `:disable` | Skip installation of a built-in package                     | `:disable t`                               |
| `:branch`  | Use a specific branch (required if default != `master`)     | `:recipe (:branch "develop")`              |
| `:files`   | Only use specific files from the repo                       | `:files ("*.el")`                          |

### Recipe Format

The `:recipe` option uses straight.el's recipe format:

```elisp
;; From GitHub (most common)
(package! my-package
  :recipe (:host github :repo "user/my-package"))

;; With branch and files filter
(package! my-package
  :recipe (:host github :repo "user/my-package"
           :branch "main"
           :files ("*.el" "src/*.el")))

;; Override a built-in package's recipe (inherits other properties)
(package! builtin-package :recipe (:nonrecursive t))
```

The full recipe format is documented at:
https://github.com/radian-software/straight.el#the-recipe-format

### Lookup Reference

| Action                    | Key / Command                            |
| ------------------------- | ---------------------------------------- |
| Jump to `package!` docs   | `C-h f package!` (in Emacs)              |
| List installed packages   | `M-x list-packages`                      |
| Show straight recipe info | `M-x straight-get-info-for-current`      |
| Browse local repos        | `~/.config/emacs/.local/straight/repos/` |

---

## 2. Package Configuration with `use-package!`

Configure packages in `config.el` using Doom's `use-package!` wrapper, not
vanilla `use-package`.

```elisp
(use-package! some-package
  :defer t                    ;; load lazily (default for :commands, :mode, :hook)
  :commands some-command      ;; autoload when this command is called
  :hook (mode . some-hook)    ;; enable in specific modes
  :init                       ;; runs before package loads
  :config                     ;; runs after package loads
  (setq! some-var value))
```

Doom's `use-package!` differs from vanilla `use-package`:

- It inherits Doom's deferral and autoload system via straight.el
- Vanilla `use-package` can cause timing bugs because it doesn't understand
  straight's deferred loading

**Rule:** always use `use-package!` in `config.el`. If you see `use-package`
(without `!`), it should be converted.

See `DOOM-API.md` for full syntax and examples.

---

## 3. The `doom sync` Pipeline

After changing `packages.el`, `init.el`, or `config.el`, run:

```sh
doom sync
```

This is the single command that:

1. Reads `packages.el` and resolves all `package!` declarations
2. Clones missing repos via straight.el into `~/.config/emacs/.local/straight/repos/`
3. Builds packages into `~/.config/emacs/.local/straight/build/`
4. Byte-compiles `.el` files into `.elc`
5. (With native-comp) generates `.eln` files
6. Regenerates autoloads
7. Syncs your selected profile

### When to Run

| Event                               | Required?                     |
| ----------------------------------- | ----------------------------- |
| Added a `package!` to `packages.el` | Yes                           |
| Removed a `package!`                | Yes                           |
| Changed `init.el` modules           | Yes                           |
| Changed `config.el` (config only)   | Usually — `doom sync` is safe |
| Changed documentation files         | No                            |

**After `doom sync`, always run `doom doctor`** to catch errors.

---

## 4. Updating Packages

### Individual Package

```sh
doom update <package-name>
```

This updates a single package and its dependencies, rebuilding only what
changed.

### All Packages

```sh
doom update
```

Updates every installed package. Slower than individual updates but ensures
everything is current with Doom's pinned versions.

### Framework Update

```sh
doom upgrade
```

Updates the Doom framework itself (core, modules, CLI) plus all packages.
**Must be followed by `doom sync && doom doctor`.**

### Cleanup

```sh
doom purge
```

Removes orphaned repos and stale bytecode. Run after removing `package!`
declarations or after a `doom upgrade` that may have left stale builds.

---

## 5. Version Pinning and Conflicts

### How Pinning Works

Doom pins every built-in package to a specific commit. The pin list is in
`~/.config/emacs/pinfile.el` (or similar). This ensures reproducible installs
across `doom sync` runs.

### Unpinning (`unpin!`)

When a package needs a newer version than Doom pins (e.g., Jinx needing compat
31+ when Doom pins compat to an older commit), unpin it in `packages.el`:

```elisp
;; Unpin a single package
(unpin! some-package)

;; Unpin multiple
(unpin! package-a package-b)

;; Unpin everything (NOT recommended)
(unpin! t)
```

Unpinning lets straight.el install the latest version from the package's
default source instead of Doom's pinned commit.

### When to Re-pin

If a package update breaks compatibility, pin to a known-good commit:

```elisp
(package! some-package :pin "1a2b3c4d5e6f7890")
```

### Detecting Pin Conflicts

| Symptom                                 | Likely Cause                              |
| --------------------------------------- | ----------------------------------------- |
| `doom sync` fails on a specific package | Pin conflicts with package's dependencies |
| Package loads but feature is missing    | Package is pinned before a needed change  |
| `doom doctor` reports "build broken"    | Pin incompatibility or missing dependency |

---

## 6. straight.el Fundamentals

Doom uses straight.el as its package manager. Key facts:

| Directory                                   | Contents                         |
| ------------------------------------------- | -------------------------------- |
| `~/.config/emacs/.local/straight/repos/`    | Full git clones of every package |
| `~/.config/emacs/.local/straight/build/`    | Built/compiled package bytecode  |
| `~/.config/emacs/.local/straight/versions/` | Lock files recording commit SHAs |

Because repos are full git clones, you can inspect local source:

```sh
# See what commit is checked out
cd ~/.config/emacs/.local/straight/repos/jinx && git log --oneline -3

# Check for local modifications
cd ~/.config/emacs/.local/straight/repos/jinx && git status
```

---

## 7. Troubleshooting

### Package Not Found

```
Error: Cannot open load file: No such file or directory, <package>
```

**Check:** Is `(package! <package>)` in `packages.el`? Did you run `doom sync`?

### Build Failed

```
Warning (straight): Failed to build <package>
```

**Check:** `doom doctor` for details. May be a network issue, missing
dependency, or pin conflict.

### `unpin!` Not Working

```
Unknown macro: unpin!
```

**Check:** `unpin!` must be in `packages.el`, not `config.el`. It's a
`packages.el`-only macro.

### Stale Bytecode

After major Doom upgrades, old `.elc` files can cause confusing errors:

```sh
doom sync && doom clean
```

### Want to Start Fresh

```sh
doom sync -u   # Force reinstall of all packages from scratch
```

This removes and reclones every package repo. Useful when the straight lock
file is corrupted or too many pinned versions conflict. Time-consuming but
definitive.

---

## 8. Quick Reference

### File Locations

| File / Dir                                  | Purpose                                |
| ------------------------------------------- | -------------------------------------- |
| `~/.config/doom/packages.el`                | Package declarations (`package!`)      |
| `~/.config/doom/config.el`                  | Package configuration (`use-package!`) |
| `~/.config/emacs/.local/straight/repos/`    | Cloned source repos                    |
| `~/.config/emacs/.local/straight/build/`    | Built/compiled packages                |
| `~/.config/emacs/.local/straight/versions/` | Lock files with pinned commits         |

### Command Reference

| Command             | When to Use                                    |
| ------------------- | ---------------------------------------------- |
| `doom sync`         | After any change to `packages.el` or `init.el` |
| `doom sync -u`      | Full reinstall from scratch                    |
| `doom doctor`       | After every `doom sync` — validation           |
| `doom update <pkg>` | Update a single package                        |
| `doom update`       | Update all packages                            |
| `doom upgrade`      | Upgrade Doom framework + all packages          |
| `doom purge`        | Remove orphaned repos and stale bytecode       |
| `doom rollback`     | Revert last `doom upgrade`                     |
| `doom clean`        | Remove stale bytecode only                     |
