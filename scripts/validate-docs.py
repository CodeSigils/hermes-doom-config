#!/usr/bin/env python3
"""Validate documentation health: stale guidance, cross-references, script registry, domain file inventory, section inventory, skill essentials, snippet inventory, pipe artifacts, frontmatter, module claim alignment, PROFILE table sync, and snippet syntax."""

from __future__ import annotations

import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    yaml = None  # type: ignore[assignment]

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
SNIPPET_HEADER = re.compile(r"^### ([\w-]+) \((\d+)\)$")
PIPE_ARTIFACT = re.compile(r"^\|\|")
FRONTMATTER = re.compile(r"^---\s*$")
SECTION_PURPOSE = re.compile(r"^;;\s+(.+)")
MODULE_CATEGORY = re.compile(r"^\s+:(input|completion|ui|editor|emacs|term|checkers|tools|os|lang|email|app|config)")
COMMENTED_MODULE = re.compile(r"^\s+;;(.+)")
UNCOMMENTED_MODULE = re.compile(r"^\s+(?:\([^)]+\)|[a-z][-a-z]+)")
PROFILE_MODULE_ROW = re.compile(r'^\| `:(\w+)`\s+\|\s+(.+?)\s+\|$')
README_DISABLED_LIST = re.compile(r"Not currently enabled: (.*?)\.")


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
    findings.extend(section_comment_findings())
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


def snippet_inventory_findings() -> list[str]:
    """Check that references/yasnippets.md snippet counts match disk."""
    yasnippets = ROOT / "references" / "yasnippets.md"
    text = yasnippets.read_text()

    claimed: dict[str, int] = {}
    for line in text.splitlines():
        if match := SNIPPET_HEADER.match(line):
            claimed[match.group(1)] = int(match.group(2))

    snippets_dir = ROOT / "snippets"
    actual_dirs = {d.name for d in snippets_dir.iterdir() if d.is_dir()}
    findings: list[str] = []

    for mode in sorted(actual_dirs):
        mode_dir = snippets_dir / mode
        actual_count = len(
            [f for f in mode_dir.iterdir() if f.is_file() and f.name != ".yas-parents"]
        )
        claimed_count = claimed.get(mode)
        if claimed_count is None:
            findings.append(
                f"MISSING: snippets/{mode} exists on disk but has no inventory "
                f"table in references/yasnippets.md"
            )
        elif actual_count != claimed_count:
            findings.append(
                f"SNIPPET_DRIFT: references/yasnippets.md claims "
                f"{claimed_count} snippets for {mode} "
                f"but disk has {actual_count}"
            )

    for mode in sorted(set(claimed) - actual_dirs):
        findings.append(
            f"STALE: references/yasnippets.md lists {mode} "
            f"but directory snippets/{mode}/ does not exist"
        )
    return findings


def pipe_artifact_findings(files: list[Path]) -> list[str]:
    """Check markdown table rows for double-pipe artifacts (|| at line start)."""
    findings: list[str] = []
    for path in files:
        for line_number, line in enumerate(path.read_text().splitlines(), start=1):
            if PIPE_ARTIFACT.match(line) and ALLOW_MARKER not in line:
                findings.append(
                    f"PIPE_ARTIFACT: {display(path)}:{line_number}: "
                    f"table row starts with double pipe (|| artifact): "
                    f"{line.strip()}"
                )
    return findings


def frontmatter_findings() -> list[str]:
    """Check SKILL.md YAML frontmatter is valid and has required keys."""
    text = SKILL_FILE.read_text()
    lines = text.splitlines()
    if len(lines) < 2 or not FRONTMATTER.match(lines[0]):
        return ["MISSING: SKILL.md has no YAML frontmatter block"]

    # Find closing ---
    end = None
    for i in range(1, len(lines)):
        if FRONTMATTER.match(lines[i]):
            end = i
            break
    if end is None:
        return ["BROKEN: SKILL.md frontmatter has no closing ---"]

    if yaml is None:
        return ["WARNING: PyYAML not installed, cannot validate frontmatter structure"]

    try:
        data = yaml.safe_load("\n".join(lines[1:end]))
    except yaml.YAMLError as e:
        return [f"BROKEN: SKILL.md frontmatter YAML parse error: {e}"]

    if not isinstance(data, dict):
        return ["BROKEN: SKILL.md frontmatter is not a YAML mapping"]

    findings: list[str] = []
    for key in ("name",):
        if key not in data:
            findings.append(f"MISSING: SKILL.md frontmatter has no '{key}' field")
    return findings


def section_comment_findings() -> list[str]:
    """Check every section file has a non-empty purpose comment on line 2."""
    sections_dir = ROOT / "sections"
    findings: list[str] = []
    for path in sorted(sections_dir.glob("*.el")):
        first_lines = path.read_text().splitlines()
        if len(first_lines) < 2 or not first_lines[1].startswith(";;"):
            findings.append(
                f"MISSING: {display(path)} lacks a purpose comment on line 2"
            )
        elif not SECTION_PURPOSE.match(first_lines[1]):
            findings.append(
                f"WARNING: {display(path)} line 2 comment may be empty or malformed: "
                f"{first_lines[1].strip()}"
            )
    return findings


def readme_disabled_module_findings() -> list[str]:
    """Verify README's list of disabled modules matches init.el's commented modules."""
    readme = ROOT / "README.md"
    init = ROOT / "init.el"

    # Parse README disabled module list — extract backtick-quoted names
    readme_text = readme.read_text()
    readme_modules = set(re.findall(r"`([a-z][-a-z0-9]*)`", readme_text.split("Not currently enabled")[1].split(".", 1)[0] if "Not currently enabled" in readme_text else ""))
    if not readme_modules:
        return ["MISSING: README.md has no 'Not currently enabled:' statement with module names"]

    # Parse init.el for commented modules (excluding section headers)
    init_text = init.read_text()
    commented: set[str] = set()
    for line in init_text.splitlines():
        if m := COMMENTED_MODULE.match(line):
            mname = m.group(1).strip()
            if mname and not mname.startswith(":"):
                # Extract bare module name: "(mu4e +org +gmail)" -> "mu4e"
                bare = re.sub(r"^\(?([a-z][-a-z0-9]*).*", r"\1", mname)
                if bare and not bare.startswith(";"):
                    commented.add(bare)

    findings: list[str] = []
    for mod in sorted(readme_modules - commented):
        findings.append(
            f"STALE: README.md says '{mod}' is disabled but it is not commented in init.el"
        )
    return findings


def profile_module_table_findings() -> list[str]:
    """Compare PROFILE.md module table category counts against init.el."""
    profile = ROOT / "PROFILE.md"
    init = ROOT / "init.el"

    # Collect multi-line cell content per category
    lines = profile.read_text().splitlines()
    profile_counts: dict[str, int] = {}
    current_cat = ""
    column2_buffer = ""

    for line in lines:
        if m := PROFILE_MODULE_ROW.match(line):
            # Flush previous category
            if current_cat and column2_buffer:
                # Count comma-separated module entries
                profile_counts[current_cat] = len(
                    [e for e in column2_buffer.split(",") if e.strip()]
                )
            current_cat = m.group(1)
            column2_buffer = m.group(2).strip()
        elif current_cat and line.lstrip().startswith("|") and "`" in line:
            # Continuation of multi-line cell — extract second column
            parts = line.strip().split("|")
            if len(parts) >= 3:
                col2 = parts[2].strip()
                if col2:
                    column2_buffer += ", " + col2
        elif current_cat:
            # End of multi-line cell
            if column2_buffer:
                profile_counts[current_cat] = len(
                    [e for e in column2_buffer.split(",") if e.strip()]
                )
            current_cat = ""
            column2_buffer = ""

    # Flush last category
    if current_cat and column2_buffer:
        profile_counts[current_cat] = len(
            [e for e in column2_buffer.split(",") if e.strip()]
        )

    # Parse init.el: category -> count of uncommented modules
    init_counts: dict[str, int] = {}
    current_cat = ""
    for line in init.read_text().splitlines():
        if m := MODULE_CATEGORY.match(line):
            current_cat = m.group(1)
            init_counts.setdefault(current_cat, 0)
        elif current_cat and UNCOMMENTED_MODULE.match(line) and not line.lstrip().startswith(";"):
            init_counts[current_cat] = init_counts.get(current_cat, 0) + 1

    findings: list[str] = []
    for cat in sorted(set(profile_counts) | set(init_counts)):
        p_count = profile_counts.get(cat, 0)
        i_count = init_counts.get(cat, 0)
        if p_count != i_count:
            findings.append(
                f"MODULE_DRIFT: PROFILE.md shows {p_count} modules for :{cat} "
                f"but init.el has {i_count}"
            )
    return findings


def snippet_syntax_findings() -> list[str]:
    """Check snippet files for basic syntax validity."""
    snippets_dir = ROOT / "snippets"
    findings: list[str] = []
    key_or_name = re.compile(r"^# (?:key|name):")
    separator = re.compile(r"^# --")
    tabstop = re.compile(r"\$(\d+)")

    for mode_dir in sorted(snippets_dir.iterdir()):
        if not mode_dir.is_dir():
            continue
        for snippet_file in sorted(mode_dir.iterdir()):
            if not snippet_file.is_file() or snippet_file.name == ".yas-parents":
                continue
            rel = display(snippet_file)
            lines = snippet_file.read_text().splitlines()

            # Must have a # -- separator between header and body
            has_sep = any(separator.match(line) for line in lines)
            if not has_sep:
                findings.append(
                    f"SNIPPET_SYNTAX: {rel} has no `# --` separator"
                )

            # Must have a # key: or # name: header directive
            has_key = any(key_or_name.match(line) for line in lines)
            if not has_key:
                findings.append(
                    f"SNIPPET_SYNTAX: {rel} has no `# key:` or `# name:` directive"
                )

            # Check tab-stop ordering (exclude $0, the yasnippet exit marker)
            tabstops = []
            for line in lines:
                for t_match in tabstop.finditer(line):
                    val = int(t_match.group(1))
                    if val > 0:
                        tabstops.append(val)
            if tabstops:
                expected = sorted(tabstops)
                if tabstops != expected:
                    findings.append(
                        f"SNIPPET_SYNTAX: {rel} tab-stops out of order: "
                        f"expected {expected} but saw {tabstops}"
                    )
    return findings


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
    ok &= report(
        "Snippet Inventory Coverage",
        snippet_inventory_findings(),
        "All snippets/ directories are registered in references/yasnippets.md and counts agree.",
    )
    ok &= report(
        "Pipe Artifact Detection",
        pipe_artifact_findings(files),
        "No double-pipe artifacts in markdown table rows.",
    )
    ok &= report(
        "SKILL.md Frontmatter Validation",
        frontmatter_findings(),
        "SKILL.md YAML frontmatter is valid.",
    )
    ok &= report(
        "README Disabled Module Claims",
        readme_disabled_module_findings(),
        "README.md disabled modules match init.el.",
    )
    ok &= report(
        "PROFILE Module Table Sync",
        profile_module_table_findings(),
        "PROFILE.md module counts match init.el.",
    )
    ok &= report(
        "Snippet Syntax Validation",
        snippet_syntax_findings(),
        "All snippet files have valid syntax.",
    )
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
