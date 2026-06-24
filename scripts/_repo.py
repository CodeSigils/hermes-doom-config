"""Repository context for Doom config validation checks.

Provides a ``Repo`` object that holds the root path, caches text reads,
and exposes helpers (``display``, ``markdown_files``) shared by all checks.
"""

from __future__ import annotations

from pathlib import Path


class Repo:
    """Repository context — paths, caching, display helpers.

    Designed to be the sole authority for reading files so that checks
    share a single text cache and the caller can replace it in tests.
    """

    def __init__(self, root: Path) -> None:
        self.root = root
        self.skill_root = root / ".agents/skills/doom-emacs"
        self.skill_file = self.skill_root / "SKILL.md"
        self.allow_marker = "<!-- stale-check: allow -->"
        self._text_cache: dict[str, str] = {}

    @classmethod
    def discover(cls) -> Repo:
        """Auto-detect the repo root from this file's location (scripts/)."""
        return cls(Path(__file__).resolve().parent.parent)

    # -- helpers ---------------------------------------------------------------

    def display(self, path: Path) -> str:
        """Return path relative to repo root (for user-facing messages)."""
        return str(path.relative_to(self.root))

    def markdown_files(self) -> list[Path]:
        """All ``.md`` files in the repo, excluding hidden dirs."""
        return sorted(
            path
            for path in self.root.rglob("*.md")
            if ".git" not in path.parts and ".open-mem" not in path.parts
        )

    def read_text(self, path: Path) -> str:
        """Read ``path`` with in-memory caching keyed on resolved absolute path.

        Checks that read the same file multiple times (e.g. ``init.el``
        is read by three different checks) share a single disk access.
        """
        key = str(path.resolve())
        if key not in self._text_cache:
            self._text_cache[key] = path.read_text()
        return self._text_cache[key]
