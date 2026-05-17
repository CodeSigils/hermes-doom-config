# Jinx `incf`/`decf` Timer Failure

## Trigger

Use this note when Doom/Jinx spell checking reports errors like:

```text
Error running timer 'nil': (void-function incf)
Error running timer 'nil': (void-function decf)
```

It may appear after `M-$`, `SPC s c`, or unrelated Org commands such as `C-c C-,` because Jinx runs spell checking from an idle timer after the command.

## Root Cause

Jinx 2.7 uses legacy `(incf ...)` and `(decf ...)` calls while requiring `cl-lib`. Modern Emacs with `cl-lib` provides `cl-incf` and `cl-decf`; the unprefixed forms only appear when deprecated `cl` is loaded. If Jinx bytecode still contains `incf` or `decf`, the idle timer fails at runtime.

## Durable Fix Pattern

Patch the straight checkout before byte-compilation in `packages.el`:

```elisp
;; Jinx 2.7 currently calls legacy `incf`/`decf` while only requiring `cl-lib`.
;; Patch the straight checkout before byte-compilation so timers use cl-lib names.
(package! jinx
  :recipe (:host github :repo "minad/jinx"
           :pre-build
           (with-temp-buffer
             (insert-file-contents "jinx.el")
             (dolist (replacement '(("(incf " . "(cl-incf ")
                                    ("(decf " . "(cl-decf ")))
               (goto-char (point-min))
               (while (search-forward (car replacement) nil t)
                 (replace-match (cdr replacement) nil t)))
             (write-region nil nil "jinx.el"))))
```

Then run:

```sh
doom sync
doom doctor
```

Restart Emacs afterward; a running Emacs may still have the old bytecode loaded.

## Verification

Check the built bytecode does not contain legacy `incf` or `decf`:

```sh
strings ~/.config/emacs/.local/straight/build-30.2/jinx/jinx.elc | grep -E '\b(incf|decf)\b' || true
```

Expected: no output.

Optional load check:

```sh
emacs --batch \
  -L ~/.config/emacs/.local/straight/build-30.2/compat \
  -L ~/.config/emacs/.local/straight/build-30.2/jinx \
  --eval "(progn (require 'jinx) (message \"jinx loads OK: %s\" (featurep 'jinx)))"
```

## Cleanup Later

When upstream Jinx replaces `incf`/`decf` with `cl-incf`/`cl-decf` or otherwise fixes the issue, remove the `:pre-build` patch and run `doom sync`. Verify with the same `strings` command.
