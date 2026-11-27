#!/usr/bin/env python3
"""Validate Pascal Anything docs and CLI↔skill parity.

Inspired by awesome-reverse-engineer-anything's validate_list.py:
bilingual section parity, required files, and skill commands that must
exist in `pascal-anything --help`.
"""
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "README.md",
    "README.pt-BR.md",
    "AGENTS.md",
    "CONTRIBUTING.md",
    "LICENSE-MIT",
    "LICENSE-APACHE",
    "llms.txt",
    "skills/pascal-anything/SKILL.md",
    "docs/SDD.md",
    "docs/platforms.md",
    "docs/faq.md",
    "docs/faq.pt-BR.md",
    "docs/showcase.md",
    "docs/stack.md",
    "docs/stack.pt-BR.md",
    "docs/translations.md",

    "docs/research.md",
    "docs/upstream-rust-anything.json",
    "docs/upstream-awesome-rea.json",
]

# Heading text after "# " / "## " — compare structure between EN and PT README
README_SECTION_COUNT_MIN = 5


# Commands that must appear in both `pascal-anything help` and SKILL.md
SKILL_CMDS = [
    "analyze",
    "bridge",
    "record",
    "build",
    "diff",
    "gate",
    "go",
    "doctor",
    "setup",
    "mcp",
]



def fail(msg: str) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    sys.exit(1)


def headings(path: Path) -> list[str]:
    out: list[str] = []
    in_fence = False
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip().startswith("```"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        # ATX headings only: one or more #, then a space, then text
        m = re.match(r"^(#{1,6})\s+(\S.*)$", line)
        if m:
            out.append(m.group(2).strip())
    return out



def check_required() -> None:
    for rel in REQUIRED_FILES:
        p = ROOT / rel
        if not p.is_file():
            fail(f"missing required file: {rel}")


def check_readme_parity() -> None:
    en = headings(ROOT / "README.md")
    pt = headings(ROOT / "README.pt-BR.md")
    if len(en) < README_SECTION_COUNT_MIN or len(pt) < README_SECTION_COUNT_MIN:
        fail(f"README heading count too low (EN={len(en)}, PT={len(pt)})")
    if len(en) != len(pt):
        fail(
            "README.md and README.pt-BR.md heading counts differ "
            f"(EN={len(en)}, PT={len(pt)}). Keep section parity."
        )
    # Cross-links present
    en_text = (ROOT / "README.md").read_text(encoding="utf-8")
    pt_text = (ROOT / "README.pt-BR.md").read_text(encoding="utf-8")
    if "README.pt-BR.md" not in en_text:
        fail("README.md must link to README.pt-BR.md")
    if "README.md" not in pt_text:
        fail("README.pt-BR.md must link to README.md")


def check_skill_vs_help() -> None:
    help_bin = ROOT / "bin" / "pascal-anything"
    if not help_bin.is_file():
        # allow missing binary in pure-doc CI steps; warn only
        print("WARN: bin/pascal-anything missing; skipping CLI↔skill check")
        return
    try:
        proc = subprocess.run(
            [str(help_bin), "--help"],
            capture_output=True,
            text=True,
            timeout=30,
            check=False,
        )
    except OSError as exc:
        print(f"WARN: could not run pascal-anything --help: {exc}")
        return
    help_text = (proc.stdout or "") + (proc.stderr or "")
    missing = [c for c in SKILL_CMDS if c not in help_text]
    if missing:
        fail(f"SKILL commands missing from --help: {', '.join(missing)}")
    skill = (ROOT / "skills/pascal-anything/SKILL.md").read_text(encoding="utf-8")
    for c in SKILL_CMDS:
        if c not in skill:
            fail(f"command `{c}` missing from skills/pascal-anything/SKILL.md")


def check_upstream_trackers() -> None:
    import json

    for name in (
        "docs/upstream-rust-anything.json",
        "docs/upstream-awesome-rea.json",
    ):
        data = json.loads((ROOT / name).read_text(encoding="utf-8"))
        if "upstream" not in data and "repo" not in data:
            fail(f"{name} missing key: upstream (or repo)")
        if "lastSeenSha" not in data:
            fail(f"{name} missing key: lastSeenSha")
        if "lastSeenAt" not in data and "lastCheckedAt" not in data:
            fail(f"{name} missing lastSeenAt or lastCheckedAt")



def main() -> None:
    check_required()
    check_readme_parity()
    check_upstream_trackers()
    check_skill_vs_help()
    print("validate_project.py: OK")


if __name__ == "__main__":
    main()
