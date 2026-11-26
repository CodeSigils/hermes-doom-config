# Environment setup

This configuration enables Doom modules in `init.el`; that file is the source
of truth. A fresh machine needs Doom Emacs and its prerequisites first. After
installing this configuration, run `doom sync` and `doom doctor`, then read the
installed README for each enabled module whose workflow you plan to use.

## Select dependencies from enabled workflows

An agent helping with setup should inspect the active modules and flags in
`init.el`, the corresponding installed Doom module documentation, and any
configuration in `sections/`. Ask which workflows the user needs when that
changes the dependency choices. Check what is already installed before offering
installation commands. Distinguish required tools from optional features and
report missing tools without assuming every `doom doctor` warning needs a fix.

For the current setup, useful checks include:

| Enabled workflow | Check before setup | Expected behavior |
| --- | --- | --- |
| Python, shell, YAML LSP | An Eglot-compatible server for each language | Server connects and offers relevant features in a project buffer |
| Python formatting | `ruff` visible to Emacs | Saving a Python file formats it with Ruff |
| Markdown formatting and preview | `prettier`; `marked` and a graphical browser for preview | Formatting and preview work in their respective workflows |
| Jinx | Enchant and the requested dictionaries | Corrections work for the configured languages; see [Jinx](jinx.md) |
| Org and Org-roam | Configured notes directories and a usable Org-roam database | A disposable node can be indexed and found |
| vterm, PDF, tree-sitter | Installed module prerequisites and build support | The particular terminal, PDF or parsing workflow works |
| Ansible, Docker, direnv | Relevant executables for the features actually used | Their enabled integrations work when invoked |

Doom does not install external language servers just because `+lsp` is enabled.
Inspect the installed Eglot server list and the relevant module README before
choosing one. In this environment `pylsp`, `bash-language-server`, and
`yaml-language-server` are used for Python, shell, and YAML respectively;
other machines can choose compatible alternatives. The installed Eglot also
lists Ruff as a Python server alternative. The Python server can provide
completion without changing the project's policy of running mypy separately.

Check executable availability in both the shell and the actual Emacs session:
`command -v NAME` and `M-: (executable-find "NAME")`. A graphical session can
have a different `exec-path`; restart or reload as appropriate after installation
and follow [workflow smoke checks](../.agents/skills/doom-emacs/domains/TROUBLESHOOTING.md#workflow-smoke-checks).
For Eglot, inspect `eglot-server-programs` for the buffer's major mode, confirm
the selected process in the affected buffer, and exercise a real connection.
A server executable being present does not establish that its runtime or
dependencies work. When a process exits, inspect its Eglot stderr buffer and
`*Messages*` before changing packages. Follow the LSP troubleshooting guide for
protocol logging and reconnecting.

On 2026-11-26 an isolated Doom session connected `pylsp`,
`bash-language-server`, and `yaml-language-server`, and Python completion
returned a relevant candidate. YAML server versions 2.0.0 and 1.25.0 installed
with the local pnpm setup exited because `vscode-languageserver-protocol` was
not found; 1.17.0 connected. The same 2.0.0 release installed with npm into an
isolated prefix connected from Doom. The temporary pnpm YAML server was removed
and the npm installation is exposed through the user's local executable path.
These are observations about this installation, not a general version or package
manager recommendation. Recheck package dependency resolution, the selected
executable, and an actual Eglot connection before upgrading or migrating tools.
The npm installation still requires a working Node executable in Emacs's
environment. Python and Markdown format-on-save were also
verified on disposable files; Jinx dictionary availability was checked, but
interactive spelling correction was not tested in that pass.

For each smoke pass, record the date, Emacs and Doom versions, relevant module
and server or formatter, test surface, observed result, and any checks not
performed. Redact user file contents and paths as appropriate. Keep a successful
dependency lookup, an LSP connection, and a completed editor workflow as separate
observations; do not infer one from another.

## Notes and recovery

The configuration directory and the Org notes directory are separate. Backing
up the configuration alone does not back up notes, attachments, or other
user data. Identify the user's existing backup system, data locations, and
restore procedure before suggesting changes; do not infer that a backup exists
or copy private notes into a diagnostics report. Confirm recovery with a safe
test of a disposable copy when the user wants a restore exercise. Treat the
Org-roam database as separate from the source notes and inspect the installed
Org-roam documentation before proposing any rebuild or deletion.
Ask where notes and attachments are kept, whether they are covered by an
existing backup, and whether a restore has been tested; unknown answers are
gaps to report, not evidence of a missing backup.

For package and Doom recovery, see [package management](package-management.md)
and the troubleshooting guide. Preserve existing work and identify the backup
and target before restoring anything.
