#!/usr/bin/env python3
"""Check maintained agent configuration without reading credentials or runtime data."""

import argparse
import json
import re
import sys
import tomllib
from pathlib import Path


def check(root: Path, common: bool) -> list[str]:
    errors = []
    base = root / "dotfiles" if common else root
    skills = base / ".agents/skills"
    claude_skills = base / ".claude/skills"
    if not claude_skills.is_symlink() or claude_skills.resolve() != skills.resolve():
        errors.append(f"{claude_skills}: expected link to .agents/skills")
    names = set()
    for entry in sorted(skills.iterdir()):
        if entry.name.startswith("."):
            continue
        path = entry / "SKILL.md"
        if not path.is_file():
            errors.append(f"{path}: missing entrypoint")
            continue
        text = path.read_text()
        front = re.match(r"\A---\n(.*?)\n---(?:\n|$)", text, re.S)
        if not front:
            errors.append(f"{path}: missing YAML frontmatter")
            continue
        fields = front.group(1)
        name = re.search(r"^name:\s*['\"]?([a-z0-9]+(?:-[a-z0-9]+)*)['\"]?\s*$", fields, re.M)
        if not name or name.group(1) != entry.name:
            errors.append(f"{path}: name must match directory in kebab-case")
        elif name.group(1) in names:
            errors.append(f"{path}: duplicate name")
        else:
            names.add(name.group(1))
        if not re.search(r"^description:\s*\S", fields, re.M):
            errors.append(f"{path}: missing description")
        # Validate actual relative Markdown links, excluding examples and URLs.
        prose = re.sub(r"^```[^\n]*\n.*?^```\s*$", "", text, flags=re.M | re.S)
        prose = re.sub(r"`[^`\n]*`", "", prose)
        for target in re.findall(r"\]\(([^\s)]+)\)", prose):
            target = target.split("#", 1)[0]
            if not target or ":" in target or any(c in target for c in "<>*") or target.startswith("/"):
                continue
            if not (path.parent / target).exists():
                errors.append(f"{path}: broken link {target}")
    for path in [base / ".claude/settings.json", base / ".codex/config.toml"]:
        if path.is_file():
            try:
                if path.suffix == ".json":
                    data = json.loads(path.read_text())
                    if "ask" in data:
                        errors.append(f"{path}: ask belongs under permissions")
                else:
                    tomllib.loads(path.read_text())
            except (ValueError, tomllib.TOMLDecodeError):
                errors.append(f"{path}: invalid configuration syntax")
    agents = base / ".agents/AGENTS.md" if common else root / "AGENTS.md"
    if not agents.is_file():
        errors.append(f"{agents}: missing shared instructions")
    if common:
        codex = base / ".codex/AGENTS.md"
        if not codex.is_symlink() or codex.resolve() != agents.resolve():
            errors.append(f"{codex}: expected link to shared instructions")
        expected_import = "@../.agents/AGENTS.md"
        legacy = base / ".codex/skills"
        if any(p.is_symlink() and ".agents/skills" in str(p.readlink()) for p in legacy.iterdir()):
            errors.append(f"{legacy}: redundant legacy skill links")
    else:
        expected_import = "@AGENTS.md"
    claude = base / ".claude/CLAUDE.md" if common else root / "CLAUDE.md"
    if not claude.is_file() or claude.read_text().strip() != expected_import:
        errors.append(f"{claude}: expected {expected_import}")
    print(f"{root}: {len(names)} skills checked")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, help="Also check a project using shared .agents/skills")
    args = parser.parse_args()
    errors = check(Path(__file__).resolve().parents[1], common=True)
    if args.repo:
        errors += check(args.repo.resolve(), common=False)
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print("Agent configuration checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
