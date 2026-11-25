# Security Policy

## Reporting a Vulnerability

Report security issues privately through
[GitHub private vulnerability reporting](https://github.com/CodeSigils/hermes-doom-config/security/advisories/new)
for this repository. Do not open a public issue for suspected vulnerabilities,
and do not include secrets, tokens, credentials, private keys, or exploit
details in public reports.

When reporting, include enough detail to reproduce and assess the issue:

- affected file, workflow, script, or configuration area;
- the commit or branch where you observed it;
- impact and reproduction steps;
- a minimal proof of concept, with sensitive values redacted.

## Scope

This repository contains a personal Doom Emacs configuration, helper scripts,
GitHub Actions workflows, and agent-facing documentation/skills. Security-relevant
issues include:

- **Secrets exposure:** credentials, tokens, private keys, or secret-bearing
  values committed in config, scripts, docs, snippets, CI logs, or history.
- **CI/workflow security:** unsafe GitHub Actions permissions, unpinned or
  untrusted action usage, script injection, unsafe checkout/credential
  handling, or release/push automation risks.
- **Script/tooling safety:** destructive or unsafe behavior in repository
  scripts, validation gaps that could hide security-relevant drift, or supply
  chain risks in pinned tooling/images.
- **Agent/configuration guidance:** instructions that encourage leaking secrets,
  bypassing review/safety controls, or applying unsafe repository operations.

This is not a packaged runtime application. Reports about normal editor behavior
or upstream Doom/Emacs/package vulnerabilities should be directed upstream when
appropriate, but configuration patterns in this repo that create exposure are in
scope.

## Handling

- Suspected credential exposure should be treated as an incident: stop use,
  rotate/revoke the credential, and assess impact before cleanup.
- Do not post raw secret values in issues, pull requests, commit messages, or
  logs. Redact evidence to filenames, paths, counts, or status.
- Fixes should include the smallest safe change, validation, and documentation
  updates needed to prevent recurrence.
- Git history rewrites are disruptive and do not replace credential rotation.
  Only consider history remediation as a separate, explicit, coordinated action
  after revocation/rotation.

## Supported Versions

Security fixes are applied to the default `master` branch. This repository does
not publish versioned releases; use the latest `master` commit.

## Policy Maintenance

When this repository's security scope, reporting process, supported branch, or
security-relevant controls change, update this file in the same change and keep
related references in `README.md`, `AGENTS.md`, and `references/INDEX.md`
current.
