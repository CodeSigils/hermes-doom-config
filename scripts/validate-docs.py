#!/usr/bin/env python3
"""Validate stale guidance, local documentation references, and script registry."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILL_ROOT = ROOT / ".agents/skills/doom-emacs"
SKILL_FILE = SKILL_ROOT / "SKILL.md"
ALLOW_MARKER = "<!-- stale-check: allow -->"

STALE_PATTERNS = (
    (re.compile(r"doom rollback"), "Removed in Doom 3 (stub only, does nothing)"),
    (re.compile(r"doom clean"), "Removed in Doom 3 (use doom gc)"),
    (re.compile(r"pinfile[.]el"), "Pins are declared via :pin in packages.el"),
    (re.compile(r"straight/versions/"), "Directory no longer exists in Doom 3"),
    (re.compile(r"\bsetopt\b"), "Doom 3 kept setq! as the local standard"),
    (re.compile(r"[+]babel"), "Not a valid :lang org flag in Doom 3"),
)

BACKTICK_PATH = re.compile(
    r"`((?:[.]/)?(?:references/|scripts/|[.]agents/)[^`]+"
    r"|(?:DOOM-API|PROFILE|AGENTS|README)[.]md"
    r"|domains/[^`]+)`"
)
MARKDOWN_LINK = re.compile(r"!?\[[^\]]*]\(([^)]+)\)")
SCRIPT_ROW = re.compile(r"^\|\s*`([^`]+[.](?:sh|py))`\s*\|")
DOMAIN_ROW = re.compile(r"`(domains/[^`]+)`")
SECTION_LOAD = re.compile(r'^\(load! "sections/([^"]+)"\)')
API_MACRO_HEADER = re.compile(r"^### `([^`]+)`")
ESSENTIALS_BULLET = re.compile(r"^- \*\*`([^`]+)`\*\*")


def markdown_files() -> list[Path]:
    return sorted(
        path
        for path in ROOT.rglob("*.md")
        if ".git" not in path.parts and ".open-mem" not in path.parts
    )


def display(path: Path) -> str:
    return str(path.relative_to(ROOT))


def stale_findings(files: list[Path]) -> list[str]:
    findings: list[str] = []
    for path in files:
        for line_number, line in enumerate(path.read_text().splitlines(), start=1):
            if ALLOW_MARKER in line:
                continue
            for pattern, explanation in STALE_PATTERNS:
                if pattern.search(line):
                    findings.append(
                        f"STALE: {display(path)}:{line_number}: {explanation}: "
                        f"{line.strip()}"
                    )
    return findings


def candidate_paths(line: str) -> set[str]:
    candidates = {match.group(1).strip() for match in BACKTICK_PATH.finditer(line)}
    for match in MARKDOWN_LINK.finditer(line):
        target = match.group(1).strip().split(maxsplit=1)[0]
        if not re.match(r"^(?:https?://|mailto:|#)", target):
            candidates.add(target)
    return candidates


def resolves(source: Path, raw_target: str) -> bool:
    target = raw_target.split("#", 1)[0]
    if not target or any(marker in target for marker in ("<", ">", "[", "]", "*")):
        return True
    if target.startswith("~/") or "$" in target:
        return True

    if target.startswith(("./", "../")):
        choices = [source.parent / target]
    elif source.is_relative_to(SKILL_ROOT):
        choices = [SKILL_ROOT / target, ROOT / target, source.parent / target]
    else:
        choices = [ROOT / target, SKILL_ROOT / target, source.parent / target]
    return any(choice.exists() for choice in choices)


def reference_findings(files: list[Path]) -> list[str]:
    findings: list[str] = []
    for path in files:
        for line_number, line in enumerate(path.read_text().splitlines(), start=1):
            for target in sorted(candidate_paths(line)):
                if not resolves(path, target):
                    findings.append(f"BROKEN: {display(path)}:{line_number}: {target}")
    return findings


def registered_scripts() -> set[str]:
    text = SKILL_FILE.read_text()
    try:
        section = text.split("## Scripts", 1)[1].split("\n## ", 1)[0]
    except IndexError:
        return set()
    return {
        match.group(1)
        for line in section.splitlines()
        if (match := SCRIPT_ROW.match(line))
    }


def inventory_findings() -> list[str]:
    actual = {
        path.name
        for path in (ROOT / "scripts").iterdir()
        if path.is_file() and path.suffix in {".sh", ".py"} and path.name != "config.sh"
    }
    registered = registered_scripts()
    findings = [
        f"MISSING: scripts/{name} is not registered in SKILL.md Scripts table"
        for name in sorted(actual - registered)
    ]
    findings.extend(
        f"STALE: SKILL.md Scripts table lists missing scripts/{name}"
        for name in sorted(registered - actual)
    )
    if "scripts/config.sh" not in SKILL_FILE.read_text():
        findings.append(
            "MISSING: SKILL.md must explicitly classify scripts/config.sh "
            "as a support library"
        )
    return findings


def domain_inventory_findings() -> list[str]:
    """Check every file under .agents/ has a row in SKILL.md Quick Index, and vice versa."""
    actual: set[str] = set()
    for path in SKILL_ROOT.rglob("*"):
        if not path.is_file():
            continue
        rel = str(path.relative_to(SKILL_ROOT))
        if rel == "SKILL.md":
            continue
        actual.add(rel)

    text = SKILL_FILE.read_text()
    try:
        qi_section = text.split("## Quick Index", 1)[1].split("\n## ", 1)[0]
    except IndexError:
        return ["MISSING: SKILL.md has no Quick Index section"]

    referenced = set(DOMAIN_ROW.findall(qi_section))

    findings: list[str] = []
    for path in sorted(actual - referenced):
        findings.append(
            f"MISSING: {path} exists on disk but has no row in SKILL.md Quick Index"
        )
    for path in sorted(referenced - actual):
        findings.append(
            f"STALE: SKILL.md Quick Index references {path} but file does not exist"
        )
    return findings


def section_inventory_findings() -> list[str]:
    """Check every loaded section file exists, and every section file is loaded."""
    config_file = ROOT / "config.el"
    sections_dir = ROOT / "sections"

    loaded = {
        f"sections/{match.group(1)}.el"
        for line in config_file.read_text().splitlines()
        if (match := SECTION_LOAD.match(line.strip()))
    }
    actual = {
        str(path.relative_to(ROOT))
        for path in sections_dir.glob("*.el")
        if path.is_file()
    }

    findings = [
        f"BROKEN: config.el loads missing {path}" for path in sorted(loaded - actual)
    ]
    findings.extend(
        f"ORPHAN: {path} exists on disk but is not loaded from config.el"
        for path in sorted(actual - loaded)
    )
    # TODO: check header comment alignment against (load! ...) lines.
    return findings


def skill_essentials_findings() -> list[str]:
    """Check that DOOM-API.md core macros are all covered in SKILL.md Doom API Essentials."""
    doom_api = ROOT / "DOOM-API.md"
    skill = SKILL_FILE

    # Parse macro names from DOOM-API.md section 2 (### `macro-name`)
    api_macros: set[str] = set()
    in_section2 = False
    for line in doom_api.read_text().splitlines():
        if line.strip() == "## 2. The Core Macros (Learn These First)":
            in_section2 = True
            continue
        if in_section2:
            if line.startswith("## ") and "Core Macros" not in line:
                break
            if match := API_MACRO_HEADER.match(line):
                api_macros.add(match.group(1))

    # Parse macro names from SKILL.md Doom API Essentials bullets
    skill_macros: set[str] = set()
    in_essentials = False
    for line in skill.read_text().splitlines():
        if line.strip() == "## Doom API Essentials (Compact)":
            in_essentials = True
            continue
        if in_essentials:
            if line.startswith("## "):
                break
            if match := ESSENTIALS_BULLET.match(line):
                skill_macros.add(match.group(1))

    missing = sorted(api_macros - skill_macros)
    return [
        f"MISSING: DOOM-API.md documents `{macro}` but SKILL.md Doom API Essentials has no entry for it"
        for macro in missing
    ]


def report(title: str, findings: list[str], clean_message: str) -> bool:
    print(f"=== {title} ===\n")
    if findings:
        print("\n".join(findings))
        print()
        return False
    print(f"{clean_message}\n")
    return True


def main() -> int:
    files = markdown_files()
    ok = report(
        "Stale Pattern Scan",
        stale_findings(files),
        "No stale active guidance found.",
    )
    ok &= report(
        "Cross-Reference Integrity",
        reference_findings(files),
        "All local documentation references resolve.",
    )
    ok &= report(
        "Script Inventory Coverage",
        inventory_findings(),
        "SKILL.md Scripts table and scripts directory agree.",
    )
    ok &= report(
        "Domain File Inventory Coverage",
        domain_inventory_findings(),
        "All .agents/ domain files are registered in SKILL.md Quick Index.",
    )
    ok &= report(
        "Skill Essentials Coverage",
        skill_essentials_findings(),
        "All DOOM-API.md core macros are covered in SKILL.md Doom API Essentials.",
    )
    ok &= report(
        "Section Inventory Coverage",
        section_inventory_findings(),
        "All sections/*.el files are loaded from config.el.",
    )
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
