"""Check result model and reporting.

``CheckResult`` wraps a list of findings with a title and a clean-message
fallback.  ``report()`` returns ``True`` when clean (no findings) and
``False`` when there are items to show.

Later you can add ``CheckResult.to_json()`` for CI output without touching
any check function.
"""

from __future__ import annotations

from dataclasses import dataclass, field


@dataclass
class CheckResult:
    """Result of a single validation check.

    Attributes
    ----------
    title:
        Human-readable section name for console output.
    findings:
        Per-item diagnostic strings, one per violation.
        Empty list means "everything OK".
    clean_message:
        What to print when findings is empty.
    """

    title: str
    findings: list[str] = field(default_factory=list)
    clean_message: str = ""

    @property
    def ok(self) -> bool:
        """``True`` when no findings were produced."""
        return not self.findings

    def report(self) -> bool:
        """Print the section to stdout and return ``True`` if clean."""
        print(f"=== {self.title} ===\n")
        if self.findings:
            print("\n".join(self.findings))
            print()
            return False
        print(f"{self.clean_message}\n")
        return True

    def to_json(self) -> dict:
        return {"title": self.title, "ok": self.ok, "findings": self.findings}
