# Drift Prevention Map

When you change a source of truth, update its dependent files in the same change. See `AGENTS.md` for automated enforcement. Rows marked `(automated)` are checked by validate-docs.py and block commits on drift.

| Source of truth | Update in same change |
|---|---|
| `init.el` | `PROFILE.md` module table, `README.md` notable modules |
| `init.el` / `packages.el` | Re-evaluate `.agents/` files for stale module references, install patterns, flags |
| `packages.el` | `PROFILE.md` packages table |
| `config.el` | `sections/*.el`, `PROFILE.md` custom functions table (automated), `DOOM-API.md` patterns, `README.md` File Layout |
| `config.el` / `sections/*.el` | Re-evaluate `.agents/` files for stale examples, paths, procedures (automated advisory)
| `DOOM-API.md` | `.agents/skills/doom-emacs/SKILL.md` Doom API Essentials (automated), `domains/PROCEDURES.md` sections C, D, E |
| `sections/*.el` (user/ functions) | `PROFILE.md` custom functions table (automated) |
| `sections/*.el` (config values) | Recheck `PROFILE.md` summaries and topic references |
| `AGENTS.md` | `PROFILE.md` Config Policies Summary, `README.md` agent entry section |
| `SECURITY.md` | `README.md` security link, `AGENTS.md` Security Policy, `references/INDEX.md` local docs |
| `scripts/` | `SKILL.md` Scripts table, `AGENTS.md` workflow, CI routing |
| `.github/workflows/ci.yml` | `README.md` maintenance guidance, script contracts |
| `SKILL.md` Scripts table | `README.md` Agent Script Awareness diagram |
| `domains/` | `SKILL.md` Quick Index table |
| `references/best-practices.md` | `AGENTS.md` Reference Map, `SKILL.md` Quick Index, Reference Sources, `PROFILE.md` Related Files |
| `references/yasnippets.md` | `AGENTS.md` Reference Map, `SKILL.md` Quick Index, Reference Sources |
| `references/jinx.md` | `AGENTS.md` Reference Map, `SKILL.md` Quick Index, Reference Sources |
| `references/snippet-validation.md` | `AGENTS.md` Reference Map, `SKILL.md` Quick Index, Reference Sources |
| `snippets/` | `references/yasnippets.md` (inventory) |
| Doom module source | Recheck version-sensitive API and topic guidance |
| Doom CLI | `references/package-management.md` |

Stale documentation is worse than missing documentation — the agent cannot distinguish it from truth.

## Documentation ownership

| Concern | Owner | Consumers and recheck trigger |
|---|---|---|
| Current configuration inventory | `PROFILE.md`; config files are authoritative | README and summaries; recheck on config changes |
| Repository policy | `AGENTS.md` | Skill summaries; recheck on policy changes |
| Doom macro guidance | `DOOM-API.md` | Skill essentials and procedures; recheck against installed source on API changes |
| Package lifecycle | `references/package-management.md` | Procedures and index; recheck on CLI changes |
| Diagnosis | `domains/TROUBLESHOOTING.md` | Index links; route package recovery to `references/package-management.md`; recheck on failures or behavior changes |
| Jinx setup and workaround | `references/jinx.md` | Profile and troubleshooting; recheck on Jinx, compat or Emacs updates |
| Source discovery | `references/INDEX.md` | Entry guides; recheck paths on Doom layout changes |

The skill and domains serve agents working on this configuration. The repository
owns the payload; local discovery may link directly to it. Root policies,
references and scripts remain in the checkout. Recheck this boundary when the
payload, discovery path or consumers change. Existing checks cover selected
exact relationships, not semantic freshness.
