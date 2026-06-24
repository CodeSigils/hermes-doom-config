#!/usr/bin/env python3
"""Validate documentation health — CLI entry point.

Usage::

    python3 scripts/validate-docs.py

Imports every check from ``_checks``, runs them in order, and exits
non-zero if any check reports findings.
"""

from __future__ import annotations

import sys

from _checks import (
    cross_commit_drift_findings,
    domain_inventory_findings,
    emoji_findings,
    frontmatter_findings,
    inventory_findings,
    pipe_artifact_findings,
    profile_module_table_findings,
    readme_disabled_module_findings,
    reference_findings,
    section_inventory_findings,
    skill_essentials_findings,
    snippet_inventory_findings,
    snippet_syntax_findings,
    stale_findings,
)
from _findings import CheckResult
from _repo import Repo


def main() -> int:
    repo = Repo.discover()
    files = repo.markdown_files()

    checks: list[CheckResult] = [
        stale_findings(repo, files),
        reference_findings(repo, files),
        inventory_findings(repo),
        domain_inventory_findings(repo),
        skill_essentials_findings(repo),
        section_inventory_findings(repo),
        snippet_inventory_findings(repo),
        pipe_artifact_findings(repo, files),
        frontmatter_findings(repo),
        readme_disabled_module_findings(repo),
        profile_module_table_findings(repo),
        snippet_syntax_findings(repo),
        emoji_findings(repo, files),
        cross_commit_drift_findings(repo),
    ]

    ok = True
    for check in checks:
        if check.blocking:
            ok &= check.report()
        else:
            check.report()
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
