# Emacs Lisp for Doom Config

A new Doom user doesn't need full Emacs Lisp fluency. Most config work uses a small subset of the language. This guide
covers what you'll encounter.

**Parent skill:** `SKILL.md` — compact core with file roles, API essentials, safety checks, pitfalls, and the Quick
Index for all domain files. Load SKILL.md first for the minimal context every Doom edit needs.

**Siblings:** `ARCHITECTURE.md`, `ELISP.md`, `PROCEDURES.md`, `TROUBLESHOOTING.md` — depth guides for framework,
elisp, procedures, and troubleshooting.

## Special Forms You Will Use

| Form            | Purpose                      | Example                                     |
| :-------------- | :--------------------------- | :------------------------------------------ |
| `setq`          | Set a variable's value       | `(setq company-idle-delay 0.2)`             |
| `setq-local`    | Set value for current buffer | `(setq-local truncate-lines nil)`           |
| `when`/`unless` | Conditional execution        | `(when (fboundp 'jinx-mode) (jinx-mode 1))` |
| `let`           | Temporary local binding      | `(let ((url-package-name "foo")) ...)`      |
| `defun`         | Define a named function      | `(defun user/my-fn () (message "hi"))`      |

## Key Patterns

**Guard optional integrations:**

```elisp
(when (fboundp 'some-command)
  (some-command 1))
```

**Prefer named functions over lambdas in hooks:**

```elisp
(defun user/my-hook-fn () (setq-local truncate-lines nil))
(add-hook 'org-mode-hook #'user/my-hook-fn)
```

**Custom prefix:** Use the user's custom prefix (e.g. `user/`) for all custom functions, variables, and private state.
Never use bare `my-` or no prefix — collisions with package-internal functions are silent and hard to debug.

## Discovering Emacs APIs

| Key / Command               | What it does                                   |
| :-------------------------- | :--------------------------------------------- |
| `C-h f`                     | Describe a function (args, docstring, source)  |
| `C-h v`                     | Describe a variable (current value, docstring) |
| `C-h o`                     | Describe any symbol                            |
| `C-h m`                     | List active minor modes in current buffer      |
| `M-x find-library`          | Jump to a library's source code                |
| `M-x toggle-debug-on-error` | Show full backtrace on next error              |

## Lexical Binding

Every `.el` file must start with:

```elisp
;;; filename.el -*- lexical-binding: t; -*-
```

Without it, closures capture variables by reference, not by value, causing subtle bugs. The byte-compiler also produces
better code with lexical binding.

## Runtime Debugging

- **`M-x toggle-debug-on-error`** — get a backtrace for errors that would normally show only a message
- **`M-x toggle-debug-on-quit`** (then `C-g`) — discover what's blocking on hang
- **`M-x profiler-start` / `M-x profiler-report`** — find performance bottlenecks
- **`(message "value: %s" my-var)`** — print to `*Messages*` buffer
- **`(insert (prin1-to-string my-var))`** — insert value into current buffer
