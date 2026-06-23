# Yasnippet Reference

Yasnippet is the snippet system used by this Doom config. Snippets live under `snippets/<major-mode>/` and are triggered
by typing a key followed by the expansion key (Tab or SPC by default).

## Directory Structure

````
snippets/
├── emacs-lisp-mode/    # 14 snippets (add-hook, cond, defmacro, defun, ...)
├── javascript-mode/    # 12 snippets (=>, afn, cl, clg, const, ...)
├── json-mode/          #  1 snippet (:)
├── latex-mode/         #  9 snippets (begin, bm, cs, enum, fig, ...)
├── markdown-mode/      #  5 snippets (##, ---, [, ```, table)
├── org-mode/           #  8 snippets (<e, <h, <q, <v, [[, img, src, table)
├── python-mode/        # 13 snippets (!py, adef, cl, def, for, ...)
├── sh-mode/            #  7 snippets (!, case, export, fn, for, if, while)
├── text-mode/          #  2 snippets (date, todo)
├── typescript-mode/    #  2 snippets (int, type) + .yas-parents pointing to js-mode
└── yaml-mode/          #  2 snippets (: , li)
````

## File Format

Each snippet file is plain text. A `# -*- mode: snippet -*-` line at the top tells Emacs which major mode to use when editing the file (optional, but recommended for proper syntax highlighting). Lines above a `# --` separator are metadata directives; the remainder is the template body.

```text
# -*- mode: snippet -*-    ; file-local variable for Emacs (optional)
# name: <human-readable description>
# key: <trigger key>
# --
<template body>
```

Supported directives (metadata lines above `# --`):

| Directive        | Required | Purpose                                                                        |
| ---------------- | -------- | ------------------------------------------------------------------------------ |
| `# key:`         | Yes^     | Trigger string — type this followed by Tab to expand                           |
| `# name:`        | No       | Human-readable description (defaults to filename if absent)                    |
| `# condition:`   | No       | Emacs-Lisp condition; snippet only expands when non-nil                        |
| `# group:`       | No       | Menu/sub-menu grouping                                                         |
| `# expand-env:`  | No       | Override variables during expansion (e.g. `yas-indent-line`)                   |
| `# binding:`     | No       | Direct keybinding for expansion                                                |
| `# type:`        | No       | `snippet` (default) or `command`                                               |
| `# uuid:`        | No       | Unique identifier (loading a second snippet with same UUID replaces the first) |
| `# contributor:` | No       | Snippet author credit (no functional effect)                                   |

^ `# key:` is required for trigger-key expansion. Without it the snippet can still be inserted via `M-x yas-insert-snippet` or the menu.

The filename is used as the default key if `# key:` is absent, but this config always sets `# key:` explicitly.

## Template Syntax

| Construct          | Example                                   | Meaning                               |
| ------------------ | ----------------------------------------- | ------------------------------------- |
| `$0`               | `$0`                                      | Final exit position (cursor end)      |
| `$1`, `$2`         | `$1`                                      | Tab-stop field (numeric order)        |
| `${1:default}`     | `${1:func_name}`                          | Field with default text               |
| `${2:${3:nested}}` | -                                         | Nested field (field 3 inside field 2) |
| `$1`               | `$1` (in body below field 1)              | Mirror — repeats field 1's text       |
| `$(expr)`          | `$(format-time-string \"%Y-%m-%d\")`      | Evaluated Lisp expression             |
| `\`expr\``         | `` `(format-time-string \"%Y-%m-%d\")` `` | Backquote Lisp expression             |
| `\${`              | `\${1:\$1}`                               | Escaped literal `${` (no expansion)   |

### Tab-stop order

- `$0` is always the final cursor position.
- `$1` through `$9` define tab-stop order. Press Tab to jump from $1 to $2 to $3, etc., ending at $0.
- If a field has a default (`${1:default}`), the default text is inserted and selected so you can type over it.

### Mirrors

A bare `$1` after `${1:...}` has been defined mirrors the typed text into all occurrences. For example:

```text
# key: begin
# --
\begin{${1:environment}}
$0
\end{$1}
```

When you type `table` into the `environment` field, both `${1:environment}` and `$1` in `\end{$1}` get the value
`table`.

## Inheritance

Yasnippet supports snippet inheritance via `.yas-parents` files. This config uses it:

| File                                    | Contents  | Effect                                     |
| --------------------------------------- | --------- | ------------------------------------------ |
| `snippets/typescript-mode/.yas-parents` | `js-mode` | TypeScript buffers inherit all JS snippets |

When a `.yas-parents` file exists in a mode directory, it contains a whitespace-separated list of parent mode names on one or more lines. Snippets from the parent mode are available in the child mode, but the child's own snippets can override parent snippets with the same key.

## Snippet Inventory

### emacs-lisp-mode (14)

| Key      | Name                               |
| -------- | ---------------------------------- |
| add-hook | add-hook                           |
| cond     | cond                               |
| defmacro | defmacro                           |
| defun    | defun                              |
| dolist   | dolist                             |
| dotimes  | dotimes                            |
| header   | package header                     |
| let      | let                                |
| let\*    | let\*                              |
| push     | push                               |
| se       | setq                               |
| unless   | unless                             |
| wcb      | wrap-(let\*)-catch-(finally)-block |
| when     | when                               |

### javascript-mode (12)

| Key   | Name                 |
| ----- | -------------------- |
| =>    | arrow function       |
| afn   | async function       |
| cl    | class                |
| clg   | console.log          |
| const | const variable       |
| dob   | destructuring object |
| filt  | filter               |
| for   | for loop             |
| if    | if statement         |
| log   | console.log          |
| map   | map                  |
| try   | try/catch            |

### json-mode (1)

| Key | Name       |
| --- | ---------- |
| :   | key: value |

### latex-mode (9)

| Key   | Name        |
| ----- | ----------- |
| begin | \begin/\end |
| bm    | bold math   |
| cs    | cases       |
| enum  | enumerate   |
| fig   | figure      |
| fr    | frac        |
| it    | itemize     |
| sec   | section     |
| ssec  | subsection  |

### markdown-mode (5)

| Key   | Name            |
| ----- | --------------- |
| ##    | heading         |
| ---   | horizontal rule |
| [     | link            |
| ```   | code block      |
| table | table           |

### org-mode (8)

| Key   | Name            |
| ----- | --------------- |
| <e    | #+begin_example |
| <h    | #+begin_comment |
| <q    | #+begin_quote   |
| <v    | #+begin_verse   |
| [[    | org link        |
| img   | org image link  |
| src   | #+begin_src     |
| table | org table       |

### python-mode (13)

| Key    | Name                      |
| ------ | ------------------------- |
| !py    | shebang python            |
| adef   | async def                 |
| cl     | class                     |
| def    | def function              |
| for    | for ... in ... :          |
| ifmain | if **name** == "**main**" |
| imp    | import                    |
| init   | **init**                  |
| log    | logging setup             |
| prop   | @property                 |
| test   | pytest test               |
| try    | try/except                |
| with   | with open                 |

### sh-mode (7)

| Key    | Name           |
| ------ | -------------- |
| !      | shebang bash   |
| case   | case statement |
| export | export         |
| fn     | function       |
| for    | for loop       |
| if     | if then        |
| while  | while loop     |

### text-mode (2)

| Key  | Name |
| ---- | ---- |
| date | date |
| todo | todo |

### typescript-mode (2)

| Key  | Name      |
| ---- | --------- |
| int  | interface |
| type | type      |

Note: TypeScript mode inherits all 12 JavaScript snippets via `.yas-parents` pointing to `js-mode`.

### yaml-mode (2)

| Key | Name       |
| --- | ---------- |
| :   | key: value |
| li  | list item  |

## Best Practices

- **Always set `# -*- mode: snippet -*-`** — omitting it works but prevents proper font-lock when editing the snippet
  file.
- **Use explicit `# key:` directives** even when the key matches the filename. Makes snippet registration visible at a
  glance.
- **Order tab-stops logically** — `$1` for the first filled field, `$2` for the second, etc., ending with `$0` for the
  final position.
- **Use mirrors for repeated text** — `${1:name}` + `$1` below avoids typing the same value twice.
- **Keep $0 last** — the cursor exits the snippet at `$0`, so nothing should follow it if you want the user to continue
  from that point.
- **Prefer `${1:default}` over separate $1** — the default text guides the user on what to type.
- **Backquote Lisp expressions** (`` `(expr)` ``) for dynamic content like dates — uses Emacs's `format-time-string`.
- **Use `.yas-parents` for inheritance** — avoids duplicating snippets across related modes (e.g., TypeScript inheriting
  from JavaScript).

## Agent Workflow

When adding or modifying a snippet:

1. **Consult the official reference first.** The authoritative docs are at
   [joaotavora.github.io/yasnippet/](https://joaotavora.github.io/yasnippet/)
   (Writing Snippets section) and this file (`references/yasnippets.md`). Verify
   syntax, directives, and tab-stop semantics against these sources before
   writing or changing a snippet file.

2. **Follow the syntax checklist below** before committing.

## Syntax Checks

Before committing snippet changes, verify:

1. **Directives correct** — `# key:` and `# name:` are set; other directives are intentional.
2. **Tab-stop order correct** — `$1` through `$N` in order, ending with `$0` as the final exit position.
3. **No duplicate keys** within a mode directory.
4. **`.yas-parents` target exists** — the parent mode name must correspond to an existing mode directory.
5. **Body is valid** — literal `{`/`}` in JS/LaTeX bodies are fine (yasnippet only interprets `${...}` as field syntax
   when `${` opens together).

## External Resources

- **Official yasnippet documentation:** [joaotavora.github.io/yasnippet/](https://joaotavora.github.io/yasnippet/) — snippet syntax, field/mirror/transformation reference, and advanced usage.
- **Yasnippet GitHub repo:** [github.com/joaotavora/yasnippet](https://github.com/joaotavora/yasnippet) — issue tracker, examples, and source.
