# Jinx `incf`/`decf` Timer Failure

## Trigger

Use this note when Doom/Jinx spell checking reports errors like:

```text
Error running timer 'nil': (void-function incf)
Error running timer 'nil': (void-function decf)
```

It may appear after `M-$`, `SPC s c`, or unrelated Org commands such as `C-c C-,` because Jinx runs spell checking from an idle timer after the command.

## Root Cause

Jinx 2.7 uses legacy `(incf ...)` and `(decf ...)` calls while requiring `cl-lib`. Modern Emacs with `cl-lib` provides `cl-incf` and `cl-decf`; the unprefixed forms only appear when deprecated `cl` is loaded. Jinx also requires compat 31 for `completion-table-with-metadata`, so Doom's older compat pin can break correction UI commands with `(void-function completion-table-with-metadata)`.

## Durable Fix Pattern

Use plain Jinx package declaration, unpin compat, and provide runtime aliases in `config.el`:

```elisp
;; packages.el
(unpin! compat)

(package! jinx
  :recipe (:host github :repo "minad/jinx"))

;; config.el, before `(use-package! jinx ...)`
(require 'cl-lib)
(unless (fboundp 'incf)
  (defalias 'incf #'cl-incf))
(unless (fboundp 'decf)
  (defalias 'decf #'cl-decf))
```

Do not use a straight `:pre-build` patch for this repo: it modifies the Jinx
checkout before `doom sync -u` fetches updates, leaving a dirty worktree and
forcing an interactive discard/stash prompt.

Then run:

```sh
doom sync
doom doctor
```

Restart Emacs afterward; a running Emacs may still have the old bytecode loaded.

## Verification

Check Jinx loads with compat 31 and the runtime aliases available:

```sh
emacs --batch \
  -L ~/.config/emacs/.local/straight/build-30.2/compat \
  -L ~/.config/emacs/.local/straight/build-30.2/jinx \
  --eval "(progn (require 'cl-lib) (unless (fboundp 'incf) (defalias 'incf #'cl-incf)) (unless (fboundp 'decf) (defalias 'decf #'cl-decf)) (require 'compat) (require 'jinx) (message \"jinx loads OK: %s, completion metadata: %s\" (featurep 'jinx) (fboundp 'completion-table-with-metadata)))"
git -C ~/.config/emacs/.local/straight/repos/jinx status --short
```

Expected: load check succeeds and Jinx repo status is empty.

## Cleanup Later

When upstream Jinx replaces `incf`/`decf` with `cl-incf`/`cl-decf` or otherwise fixes the issue, remove the runtime aliases from `config.el` and run `doom sync`. Keep `(unpin! compat)` while Jinx or other unpinned packages require compat 31.
