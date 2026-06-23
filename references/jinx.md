# Jinx Spell-Checking Reference

## Language Configuration

`jinx-languages` is a **space-separated string** of Hunspell dictionary codes:

```elisp
(setq! jinx-languages "en_US el_GR")
```

Format: `<language>_<country>` — standard Hunspell naming.

### Adding a Language

1. Determine the Hunspell code (e.g., `de_DE` for German, `fr_FR` for French, `el_GR` for Greek).
2. Add it to the space-separated `jinx-languages` string.
3. Ensure the Hunspell dictionary is installed at the system level.

## Dictionary Availability

Jinx delegates to Hunspell/Enchant at the system level. Check available
dictionaries with:

```sh
hunspell -D
```

This lists all installed dictionaries under `AVAILABLE DICTIONARIES`. On
Debian/Ubuntu, install additional dictionaries with:

```sh
sudo apt install hunspell-el   # Greek, for example
```

Package names follow the pattern `hunspell-<language_code>`.

## Source

The authoritative Jinx source lives in the installed straight repo:

```
~/.config/emacs/.local/straight/repos/jinx/jinx.el
```

Key documentation found inline in the source:

| Variable              | Type   | Description                                     |
|-----------------------|--------|-------------------------------------------------|
| `jinx-languages`      | string | "Dictionary language codes, as a string separated by whitespace." |
| `jinx-save-languages` | symbol | Whether to save `jinx-languages` as a file-local variable (`'ask`, `t`, `nil`). |
| `jinx-delay`          | float  | Idle timer delay before checking.               |
| `jinx-include-faces`  | list   | Faces to check per mode (comments, strings, etc.) |

## Verification

To confirm Jinx sees the dictionary:

1. Open a buffer in a mode that enables Jinx (text-mode, prog-mode, etc.)
2. Run `M-x jinx-languages` to see or change the active languages.
3. Misspell a word — Jinx should underline it in the active languages.
4. Correct with `M-$` (`jinx-correct`).

## Related

- `sections/spellcheck.el` — configuration in this repo
- `hunspell -D` — list all available system dictionaries
