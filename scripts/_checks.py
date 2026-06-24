"""Validation check functions — one public function per check, each
accepting a ``Repo`` and returning a ``CheckResult``.

Checks are grouped loosely by domain (markdown, scripts, sections,
snippets, frontmatter, module alignment).  Helper functions are private.
"""

from __future__ import annotations

import re
from pathlib import Path

from _findings import CheckResult
from _repo import Repo

try:
    import yaml
except ImportError:
    yaml = None  # type: ignore[assignment]

# ---------------------------------------------------------------------------
# Stale active-guidance patterns
# ---------------------------------------------------------------------------

STALE_PATTERNS: tuple[tuple[re.Pattern[str], str], ...] = (
    (re.compile(r"doom rollback"), "Removed in Doom 3 (stub only, does nothing)"),
    (re.compile(r"doom clean"), "Removed in Doom 3 (use doom gc)"),
    (re.compile(r"pinfile[.]el"), "Pins are declared via :pin in packages.el"),
    (re.compile(r"straight/versions/"), "Directory no longer exists in Doom 3"),
    (re.compile(r"\bsetopt\b"), "Doom 3 kept setq! as the local standard"),
    (re.compile(r"[+]babel"), "Not a valid :lang org flag in Doom 3"),
)


def stale_findings(repo: Repo, files: list[Path]) -> CheckResult:
    """Scan all markdown for stale active-guidance patterns."""
    findings: list[str] = []
    for path in files:
        for line_number, line in enumerate(
            repo.read_text(path).splitlines(), start=1
        ):
            if repo.allow_marker in line:
                continue
            for pattern, explanation in STALE_PATTERNS:
                if pattern.search(line):
                    findings.append(
                        f"STALE: {repo.display(path)}:{line_number}: "
                        f"{explanation}: {line.strip()}"
                    )
    return CheckResult(
        "Stale Pattern Scan", findings, "No stale active guidance found."
    )


# ---------------------------------------------------------------------------
# Cross-reference integrity
# ---------------------------------------------------------------------------

BACKTICK_PATH = re.compile(
    r"`((?:[.]/)?(?:references/|scripts/|[.]agents/)[^`]+"
    r"|(?:DOOM-API|PROFILE|AGENTS|README)[.]md"
    r"|domains/[^`]+)`"
)
MARKDOWN_LINK = re.compile(r"!?\[[^\]]*]\(([^)]+)\)")


def _candidate_paths(line: str) -> set[str]:
    candidates: set[str] = {m.group(1).strip() for m in BACKTICK_PATH.finditer(line)}
    for m in MARKDOWN_LINK.finditer(line):
        target = m.group(1).strip().split(maxsplit=1)[0]
        if not re.match(r"^(?:https?://|mailto:|#)", target):
            candidates.add(target)
    return candidates


def _resolves(source: Path, raw_target: str, repo: Repo) -> bool:
    target = raw_target.split("#", 1)[0]
    if not target or any(marker in target for marker in ("<", ">", "[", "]", "*")):
        return True
    if target.startswith("~/") or "$" in target:
        return True

    if target.startswith(("./", "../")):
        choices = [source.parent / target]
    elif source.is_relative_to(repo.skill_root):
        choices = [repo.skill_root / target, repo.root / target, source.parent / target]
    else:
        choices = [repo.root / target, repo.skill_root / target, source.parent / target]
    return any(choice.exists() for choice in choices)


def reference_findings(repo: Repo, files: list[Path]) -> CheckResult:
    """Check that all local backtick-quoted paths and markdown links resolve."""
    findings: list[str] = []
    for path in files:
        for line_number, line in enumerate(
            repo.read_text(path).splitlines(), start=1
        ):
            for target in sorted(_candidate_paths(line)):
                if not _resolves(path, target, repo):
                    findings.append(
                        f"BROKEN: {repo.display(path)}:{line_number}: {target}"
                    )
    return CheckResult(
        "Cross-Reference Integrity",
        findings,
        "All local documentation references resolve.",
    )


# ---------------------------------------------------------------------------
# Script inventory
# ---------------------------------------------------------------------------

SCRIPT_ROW = re.compile(r"^\|\s*`([^`]+[.](?:sh|py))`\s*\|")


def _registered_scripts(repo: Repo) -> set[str]:
    text = repo.read_text(repo.skill_file)
    try:
        section = text.split("## Scripts", 1)[1].split("\n## ", 1)[0]
    except IndexError:
        return set()
    return {
        m.group(1)
        for line in section.splitlines()
        if (m := SCRIPT_ROW.match(line))
    }


def inventory_findings(repo: Repo) -> CheckResult:
    """Check agreement between ``scripts/`` directory and SKILL.md Scripts table."""
    actual = {
        p.name
        for p in (repo.root / "scripts").iterdir()
        if p.is_file()
        and p.suffix in (".sh", ".py")
        and p.name != "config.sh"
        and not p.name.startswith("_")
    }
    registered = _registered_scripts(repo)
    findings: list[str] = []
    for name in sorted(actual - registered):
        findings.append(
            f"MISSING: scripts/{name} is not registered in SKILL.md Scripts table"
        )
    for name in sorted(registered - actual):
        findings.append(
            f"STALE: SKILL.md Scripts table lists missing scripts/{name}"
        )
    if "scripts/config.sh" not in repo.read_text(repo.skill_file):
        findings.append(
            "MISSING: SKILL.md must explicitly classify scripts/config.sh "
            "as a support library"
        )
    return CheckResult(
        "Script Inventory Coverage",
        findings,
        "SKILL.md Scripts table and scripts directory agree.",
    )


# ---------------------------------------------------------------------------
# Domain file inventory
# ---------------------------------------------------------------------------

DOMAIN_ROW = re.compile(r"`(domains/[^`]+)`")


def domain_inventory_findings(repo: Repo) -> CheckResult:
    """Check every file under ``.agents/`` has a row in SKILL.md Quick Index."""
    actual: set[str] = set()
    for path in repo.skill_root.rglob("*"):
        if not path.is_file():
            continue
        rel = str(path.relative_to(repo.skill_root))
        if rel == "SKILL.md":
            continue
        actual.add(rel)

    text = repo.read_text(repo.skill_file)
    try:
        qi_section = text.split("## Quick Index", 1)[1].split("\n## ", 1)[0]
    except IndexError:
        return CheckResult(
            "Domain File Inventory Coverage",
            ["MISSING: SKILL.md has no Quick Index section"],
            "",
        )

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
    return CheckResult(
        "Domain File Inventory Coverage",
        findings,
        "All .agents/ domain files are registered in SKILL.md Quick Index.",
    )


# ---------------------------------------------------------------------------
# Section inventory + header comments
# ---------------------------------------------------------------------------

SECTION_LOAD = re.compile(r'^\(load! "sections/([^"]+)"\)')
SECTION_PURPOSE = re.compile(r"^;;\s+(.+)")


def _section_comment_findings(repo: Repo) -> list[str]:
    """Check every section file has a non-empty purpose comment on line 2."""
    findings: list[str] = []
    for path in sorted((repo.root / "sections").glob("*.el")):
        first_lines = repo.read_text(path).splitlines()
        if len(first_lines) < 2 or not first_lines[1].startswith(";;"):
            findings.append(
                f"MISSING: {repo.display(path)} lacks a purpose comment on line 2"
            )
        elif not SECTION_PURPOSE.match(first_lines[1]):
            findings.append(
                f"WARNING: {repo.display(path)} "
                f"line 2 comment may be empty or malformed: "
                f"{first_lines[1].strip()}"
            )
    return findings


def section_inventory_findings(repo: Repo) -> CheckResult:
    """Check every loaded section file exists, every section file is loaded,
    and every section file has a purpose comment."""
    config_file = repo.root / "config.el"
    sections_dir = repo.root / "sections"

    loaded = {
        f"sections/{m.group(1)}.el"
        for line in repo.read_text(config_file).splitlines()
        if (m := SECTION_LOAD.match(line.strip()))
    }
    actual = {
        str(p.relative_to(repo.root))
        for p in sections_dir.glob("*.el")
        if p.is_file()
    }

    findings: list[str] = [
        f"BROKEN: config.el loads missing {p}"
        for p in sorted(loaded - actual)
    ]
    findings.extend(
        f"ORPHAN: {p} exists on disk but is not loaded from config.el"
        for p in sorted(actual - loaded)
    )
    findings.extend(_section_comment_findings(repo))
    return CheckResult(
        "Section Inventory Coverage",
        findings,
        "All sections/*.el files are loaded from config.el.",
    )


# ---------------------------------------------------------------------------
# Skill essentials / DOOM-API macro coverage
# ---------------------------------------------------------------------------

API_MACRO_HEADER = re.compile(r"^### `([^`]+)`")
ESSENTIALS_BULLET = re.compile(r"^- \*\*`([^`]+)`\*\*")


def skill_essentials_findings(repo: Repo) -> CheckResult:
    """Check that every core macro in DOOM-API.md section 2 is listed in
    SKILL.md Doom API Essentials."""
    doom_api = repo.root / "DOOM-API.md"
    skill = repo.skill_file

    api_macros: set[str] = set()
    in_section2 = False
    for line in repo.read_text(doom_api).splitlines():
        if line.strip() == "## 2. The Core Macros (Learn These First)":
            in_section2 = True
            continue
        if in_section2:
            if line.startswith("## ") and "Core Macros" not in line:
                break
            if m := API_MACRO_HEADER.match(line):
                api_macros.add(m.group(1))

    skill_macros: set[str] = set()
    in_essentials = False
    for line in repo.read_text(skill).splitlines():
        if line.strip() == "## Doom API Essentials (Compact)":
            in_essentials = True
            continue
        if in_essentials:
            if line.startswith("## "):
                break
            if m := ESSENTIALS_BULLET.match(line):
                skill_macros.add(m.group(1))

    missing = sorted(api_macros - skill_macros)
    return CheckResult(
        "Skill Essentials Coverage",
        [
            "MISSING: DOOM-API.md documents `{macro}` "
            "but SKILL.md Doom API Essentials has no entry for it".format(macro=m)
            for m in missing
        ],
        "All DOOM-API.md core macros are covered in SKILL.md Doom API Essentials.",
    )


# ---------------------------------------------------------------------------
# Snippet inventory
# ---------------------------------------------------------------------------

SNIPPET_HEADER = re.compile(r"^### ([\w-]+) \((\d+)\)$")


def snippet_inventory_findings(repo: Repo) -> CheckResult:
    """Check that ``references/yasnippets.md`` snippet counts match disk."""
    yasnippets = repo.root / "references" / "yasnippets.md"
    text = repo.read_text(yasnippets)

    claimed: dict[str, int] = {}
    for line in text.splitlines():
        if m := SNIPPET_HEADER.match(line):
            claimed[m.group(1)] = int(m.group(2))

    snippets_dir = repo.root / "snippets"
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
                f"MISSING: snippets/{mode} exists on disk "
                f"but has no inventory table in references/yasnippets.md"
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
    return CheckResult(
        "Snippet Inventory Coverage",
        findings,
        "All snippets/ directories are registered "
        "in references/yasnippets.md and counts agree.",
    )


# ---------------------------------------------------------------------------
# Pipe artifact detection
# ---------------------------------------------------------------------------

PIPE_ARTIFACT = re.compile(r"^\|\|")


def pipe_artifact_findings(repo: Repo, files: list[Path]) -> CheckResult:
    """Check markdown table rows for ``||`` at line start (display artifact)."""
    findings: list[str] = []
    for path in files:
        for line_number, line in enumerate(
            repo.read_text(path).splitlines(), start=1
        ):
            if PIPE_ARTIFACT.match(line) and repo.allow_marker not in line:
                findings.append(
                    f"PIPE_ARTIFACT: {repo.display(path)}:{line_number}: "
                    f"table row starts with double pipe (|| artifact): "
                    f"{line.strip()}"
                )
    return CheckResult(
        "Pipe Artifact Detection",
        findings,
        "No double-pipe artifacts in markdown table rows.",
    )


# ---------------------------------------------------------------------------
# SKILL.md YAML frontmatter
# ---------------------------------------------------------------------------

FRONTMATTER = re.compile(r"^---\s*$")


def frontmatter_findings(repo: Repo) -> CheckResult:
    """Check SKILL.md YAML frontmatter is valid and has required keys."""
    text = repo.read_text(repo.skill_file)
    lines = text.splitlines()
    if len(lines) < 2 or not FRONTMATTER.match(lines[0]):
        return CheckResult(
            "SKILL.md Frontmatter Validation",
            ["MISSING: SKILL.md has no YAML frontmatter block"],
            "",
        )

    end = None
    for i in range(1, len(lines)):
        if FRONTMATTER.match(lines[i]):
            end = i
            break
    if end is None:
        return CheckResult(
            "SKILL.md Frontmatter Validation",
            ["BROKEN: SKILL.md frontmatter has no closing ---"],
            "",
        )

    if yaml is None:
        return CheckResult(
            "SKILL.md Frontmatter Validation",
            ["WARNING: PyYAML not installed, cannot validate frontmatter structure"],
            "",
        )

    try:
        data = yaml.safe_load("\n".join(lines[1:end]))
    except yaml.YAMLError as e:
        return CheckResult(
            "SKILL.md Frontmatter Validation",
            [f"BROKEN: SKILL.md frontmatter YAML parse error: {e}"],
            "",
        )

    if not isinstance(data, dict):
        return CheckResult(
            "SKILL.md Frontmatter Validation",
            ["BROKEN: SKILL.md frontmatter is not a YAML mapping"],
            "",
        )

    findings: list[str] = []
    for key in ("name",):
        if key not in data:
            findings.append(f"MISSING: SKILL.md frontmatter has no '{key}' field")
    return CheckResult(
        "SKILL.md Frontmatter Validation",
        findings,
        "SKILL.md YAML frontmatter is valid.",
    )


# ---------------------------------------------------------------------------
# README disabled-module claims vs init.el
# ---------------------------------------------------------------------------

COMMENTED_MODULE = re.compile(r"^\s+;;(.+)")
"""Match a commented module line in ``init.el``::

       ;;corfu             ; complete with cap(f), cape...
"""


def readme_disabled_module_findings(repo: Repo) -> CheckResult:
    """Verify that every module the README claims is disabled is actually
    commented out in ``init.el``."""
    readme = repo.root / "README.md"
    init = repo.root / "init.el"

    # Extract backtick-quoted module names after "Not currently enabled:"
    readme_text = repo.read_text(readme)
    try:
        snippet = readme_text.split("Not currently enabled")[1].split(".", 1)[0]
    except IndexError:
        return CheckResult(
            "README Disabled Module Claims",
            ["MISSING: README.md has no 'Not currently enabled:' statement"],
            "",
        )
    readme_modules: set[str] = set(re.findall(r"`([a-z][-a-z0-9]*)`", snippet))
    if not readme_modules:
        return CheckResult(
            "README Disabled Module Claims",
            [
                "MISSING: README.md has no "
                "'Not currently enabled:' statement with module names"
            ],
            "",
        )

    # Build the set of actually commented module names from init.el.
    commented: set[str] = set()
    for line in repo.read_text(init).splitlines():
        if m := COMMENTED_MODULE.match(line):
            mname = m.group(1).strip()
            if mname and not mname.startswith(":"):
                bare = re.sub(r"^\(?([a-z][-a-z0-9]*).*", r"\1", mname)
                if bare and not bare.startswith(";"):
                    commented.add(bare)

    findings: list[str] = [
        f"STALE: README.md says '{mod}' is disabled "
        f"but it is not commented in init.el"
        for mod in sorted(readme_modules - commented)
    ]
    return CheckResult(
        "README Disabled Module Claims",
        findings,
        "README.md disabled modules match init.el.",
    )


# ---------------------------------------------------------------------------
# PROFILE module-table counts vs init.el
# ---------------------------------------------------------------------------

PROFILE_MODULE_ROW = re.compile(r'^\| `:(\w+)`\s+\|\s+(.+?)\s+\|$')
MODULE_CATEGORY = re.compile(
    r"^\s+:(input|completion|ui|editor|emacs|term|checkers|tools|os|lang|email|app|config)"
)
UNCOMMENTED_MODULE = re.compile(r"^\s+(?:\([^)]+\)|[a-z][-a-z]+)")


def profile_module_table_findings(repo: Repo) -> CheckResult:
    """Compare per-category module counts between PROFILE.md and ``init.el``."""
    profile = repo.root / "PROFILE.md"
    init = repo.root / "init.el"

    # -- PROFILE side: collect multi-line cell content per category -----------
    profile_counts: dict[str, int] = {}
    current_cat = ""
    column2_buffer = ""

    for line in repo.read_text(profile).splitlines():
        if m := PROFILE_MODULE_ROW.match(line):
            if current_cat and column2_buffer:
                profile_counts[current_cat] = len(
                    [e for e in column2_buffer.split(",") if e.strip()]
                )
            current_cat = m.group(1)
            column2_buffer = m.group(2).strip()
        elif current_cat and line.lstrip().startswith("|") and "`" in line:
            parts = line.strip().split("|")
            if len(parts) >= 3:
                col2 = parts[2].strip()
                if col2:
                    column2_buffer += ", " + col2
        elif current_cat:
            if column2_buffer:
                profile_counts[current_cat] = len(
                    [e for e in column2_buffer.split(",") if e.strip()]
                )
            current_cat = ""
            column2_buffer = ""

    if current_cat and column2_buffer:
        profile_counts[current_cat] = len(
            [e for e in column2_buffer.split(",") if e.strip()]
        )

    # -- init.el side: count uncommented modules per category -----------------
    init_counts: dict[str, int] = {}
    current_cat = ""
    for line in repo.read_text(init).splitlines():
        if m := MODULE_CATEGORY.match(line):
            current_cat = m.group(1)
            init_counts.setdefault(current_cat, 0)
        elif (
            current_cat
            and UNCOMMENTED_MODULE.match(line)
            and not line.lstrip().startswith(";")
        ):
            init_counts[current_cat] = init_counts.get(current_cat, 0) + 1

    findings: list[str] = []
    for cat in sorted(set(profile_counts) | set(init_counts)):
        p = profile_counts.get(cat, 0)
        i = init_counts.get(cat, 0)
        if p != i:
            findings.append(
                f"MODULE_DRIFT: PROFILE.md shows {p} modules for :{cat} "
                f"but init.el has {i}"
            )
    return CheckResult(
        "PROFILE Module Table Sync",
        findings,
        "PROFILE.md module counts match init.el.",
    )


# ---------------------------------------------------------------------------
# PROFILE custom-functions table vs actual user/ defuns
# ---------------------------------------------------------------------------

PROFILE_FN_ROW = re.compile(r"^\|\s*`user/([^`]+)`\s+\|")
DEFUN_USER = re.compile(r"\(defun\s+(user/[-\w]+)")


def profile_functions_findings(repo: Repo) -> CheckResult:
    """Compare the ``## Custom Functions`` table in PROFILE.md against
    actual ``(defun user/...)`` declarations in all `.el` files."""
    profile = repo.root / "PROFILE.md"
    text = repo.read_text(profile)

    try:
        section = text.split("## Custom Functions", 1)[1].split("## ", 1)[0]
    except IndexError:
        return CheckResult(
            "PROFILE Custom Functions Sync",
            ["MISSING: PROFILE.md has no ## Custom Functions section"],
            "",
        )

    claimed: set[str] = set()
    for line in section.splitlines():
        if m := PROFILE_FN_ROW.match(line):
            claimed.add(f"user/{m.group(1)}")

    actual: dict[str, set[str]] = {}
    for path in sorted(repo.root.rglob("*.el")):
        if ".git" in path.parts:
            continue
        for m in DEFUN_USER.finditer(repo.read_text(path)):
            fn = m.group(1)
            actual.setdefault(fn, set()).add(repo.display(path))

    actual_names = set(actual.keys())

    findings: list[str] = []
    for fn in sorted(claimed - actual_names):
        findings.append(
            f"STALE: PROFILE.md lists `{fn}` but no matching "
            f"(defun {fn} ...) exists on disk"
        )
    for fn in sorted(actual_names - claimed):
        locs = ", ".join(sorted(actual[fn]))
        findings.append(
            f"MISSING: (defun {fn} ...) in {locs} "
            f"is not listed in PROFILE.md ## Custom Functions table"
        )

    return CheckResult(
        "PROFILE Custom Functions Sync",
        findings,
        "PROFILE.md custom-functions table matches actual defuns.",
    )


# ---------------------------------------------------------------------------
# Snippet syntax validation
# ---------------------------------------------------------------------------


def snippet_syntax_findings(repo: Repo) -> CheckResult:
    """Check snippet files for basic syntax validity:
    ``# key:`` / ``# name:`` header, ``# --`` separator, ordered tab-stops.
    """
    snippets_dir = repo.root / "snippets"
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
            rel = repo.display(snippet_file)
            lines = repo.read_text(snippet_file).splitlines()

            has_sep = any(separator.match(line) for line in lines)
            if not has_sep:
                findings.append(f"SNIPPET_SYNTAX: {rel} has no `# --` separator")

            has_key = any(key_or_name.match(line) for line in lines)
            if not has_key:
                findings.append(
                    f"SNIPPET_SYNTAX: {rel} has no `# key:` or `# name:` directive"
                )

            tabstops: list[int] = []
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

    return CheckResult(
        "Snippet Syntax Validation",
        findings,
        "All snippet files have valid syntax.",
    )


# ---------------------------------------------------------------------------
# Cross-commit drift (advisory, non-blocking)
# ---------------------------------------------------------------------------

DRIFT_PAIRS: list[tuple[str, set[str]]] = [
    ("init.el", {"PROFILE.md", "README.md"}),
    ("config.el", {"PROFILE.md", "DOOM-API.md", "README.md"}),
    ("packages.el", {"PROFILE.md"}),
    (
        "DOOM-API.md",
        {
            ".agents/skills/doom-emacs/SKILL.md",
            ".agents/skills/doom-emacs/domains/PROCEDURES.md",
        },
    ),
    ("sections/", {"PROFILE.md"}),
    (".agents/", {".agents/skills/doom-emacs/SKILL.md"}),
    ("scripts/", {".agents/skills/doom-emacs/SKILL.md"}),
]


def cross_commit_drift_findings(repo: Repo) -> CheckResult:
    """Advisory check: when a source file is staged but none of its
    drift targets are, warn the user.

    Non-blocking (``blocking=False``) — better to over-notify than to
    silently allow drift.
    """
    import subprocess

    result = subprocess.run(
        ["git", "diff", "--cached", "--name-only"],
        capture_output=True,
        text=True,
        cwd=str(repo.root),
    )
    if result.returncode != 0:
        return CheckResult(
            "Cross-Commit Drift",
            [],
            "Could not check cross-commit drift (git diff failed).",
            blocking=False,
        )

    staged = set(result.stdout.splitlines())
    if not staged:
        return CheckResult(
            "Cross-Commit Drift",
            [],
            "No staged files -- cross-commit drift not applicable.",
            blocking=False,
        )

    findings: list[str] = []
    for source, dependents in DRIFT_PAIRS:
        source_changed = any(
            s.startswith(source) if source.endswith("/") else s == source
            for s in staged
        )
        if not source_changed:
            continue

        dependent_changed = any(
            d in staged for d in dependents
        )
        if not dependent_changed:
            deps_str = ", ".join(sorted(dependents))
            findings.append(
                f"WARNING: {source} staged but no dependent "
                f"({deps_str}) was staged. "
                f"Stage the dependent file(s) alongside this change, "
                f"or acknowledge this is a legitimate single-file fix."
            )

    return CheckResult(
        "Cross-Commit Drift",
        findings,
        "No cross-commit drift detected.",
        blocking=False,
    )
