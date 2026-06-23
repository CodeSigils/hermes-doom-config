# Snippet Validation Reference

Procedure for validating yasnippet syntax against the official parser source.

## Validation Chain (from least to most authoritative)

1. **Official rendered docs** — https://joaotavora.github.io/yasnippet/ (Writing Snippets > File Content, Template Syntax)
2. **Org source files** — https://github.com/joaotavora/yasnippet/tree/master/doc/ (snippet-development.org)
3. **Parser source code** — https://raw.githubusercontent.com/joaotavora/yasnippet/master/yasnippet.el (the `yas--parse-template` function)

Always validate against source (3) before claiming a snippet is wrong. The rendered docs may omit edge cases that the parser handles.

## Header / Directive Parsing (from `yas--parse-template`)

The parser in `yasnippet.el` works like this:

1. Searches for `^# --\\s-*\n` (a line containing `# --` with optional trailing whitespace).
2. If found: everything above is the directive header, everything below is the template body.
3. If NOT found: the entire file is treated as the template body (no directives).
4. Lines above `# --` matching `^# *\\([^ ]+?\\) *: *\\(.*?\\)$` are parsed as directives.

### Recognized Directives

The parser recognizes exactly 9 directive names:

| Directive     | Action                                                  |
|---------------|---------------------------------------------------------|
| `key`         | Sets trigger key (defaults to filename if absent)       |
| `name`        | Sets display name (defaults to filename if absent)      |
| `condition`   | Emacs-Lisp condition (evaluated with `yas--read-lisp`)  |
| `group`       | Menu grouping (split on `.` for nesting)                |
| `expand-env`  | Override variables during expansion (`let` varlist form)|
| `binding`     | Direct keybinding                                       |
| `type`        | `snippet` (default) or `command`                        |
| `uuid`        | Unique identifier                                       |
| `contributor` | Acknowledged (parser no-ops this)                       |

Unrecognized directives produce a warning message but do not prevent loading.

### What is NOT a directive

- `# -*- mode: snippet -*-` — an Emacs file-local variable, completely ignored by the parser. It tells Emacs to use snippet-mode when editing the file.

### `# key:` vs filename

From the parser source:
```elisp
(unless (or key binding)
  (setq key (and file (file-name-nondirectory file))))
```

If neither `key` nor `binding` is set, the key defaults to the filename. An explicit `# key:` always overrides.

### `# name:` defaults

From the parser source:
```elisp
(name (and file (file-name-nondirectory file)))
```

`# name:` defaults to the filename. It is optional but recommended for human readability.

## Tab-Stop Semantics (from field navigation code)

The relevant parser and navigation code:

- `$N` (bare) — tab stop field `N`. Parsed by the template reader.
- `${N:default}` — tab stop `N` with placeholder text.
- `$0` — the exit marker. Code: `yas-next-field-will-exit-p` returns t when the next field after the current one is the exit field.

Key points:
- `$0` is NOT a regular tab-stop field. It is the cursor exit position. It does not need to be numerically ordered.
- Mirrors (`$1` after `${1:...}` has been defined) work regardless of their position relative to `$0`.
- `$N` and `${N:...}` are the two syntaxes for tab-stop fields.
- The parser does not enforce ordering. Navigation follows numeric order, skipping mirrors.

## Validation Procedure

### Automated checks

```python
import re, os
from pathlib import Path

snippets = Path("snippets")

# Regex patterns
SEP_RE = re.compile(r'^# --\\s*$', re.MULTILINE)
DIRECTIVE_RE = re.compile(r'^#\\s*([^ ]+?)\\s*:\\s*(.*?)\\s*$', re.MULTILINE)

for sf in sorted(snippets.rglob("*")):
    if not sf.is_file() or sf.name == ".yas-parents":
        continue
    content = sf.read_text()
    mode = sf.parent.name

    # 1. Check # -- separator
    sep = SEP_RE.search(content)
    if not sep:
        print(f"NO_SEP: {mode}/{sf.name}")

    # 2. Check directive names are recognized
    header = content[:sep.start()] if sep else ""
    for m in DIRECTIVE_RE.finditer(header):
        if m.group(1) not in ('uuid','type','key','name','condition',
                               'group','expand-env','binding','contributor','mode'):
            print(f"UNKNOWN_DIR: {mode}/{sf.name}: #{m.group(1)}:")

    # 3. Check body has content
    body = content[sep.end():] if sep else content
    if not body.strip():
        print(f"EMPTY_BODY: {mode}/{sf.name}")
```

### What to check manually

1. Every snippet has a `# --` separator (otherwise the whole file is treated as body with no directives).
2. All directives use recognized names.
3. `$0` is present as exit marker (optional but recommended).
4. No new field definitions appear after `$0` (fields before `$0` can have mirrors after it).
5. Tab-stop numbers are sequential without gaps (e.g., having `$3` but no `$1` is suspicious).

### False positives to ignore

- `$0` after `$N` in numeric ordering — `$0` is the exit marker, not a field.
- `$N` repeats (mirrors) — same field number used as both field and mirror.
- `# -*- mode: snippet -*-` — not a directive, ignored by parser.
- Filename not matching `# key:` — the filename is the default key, but explicit `# key:` overrides.
- No `# name:` directive — defaults to filename.
