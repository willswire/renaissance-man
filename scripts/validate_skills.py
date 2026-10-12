#!/usr/bin/env python3
"""Check every skill against the portable Agent Skills spec (agentskills.io).

The same skills/ tree is loaded by Claude Code, Codex, and Zed, so the rules
here are the intersection of what all three accept:

- each skill is a direct child of skills/ with a SKILL.md
- frontmatter has `name` and `description`
- `name` matches the folder name (Zed and Codex both require this)
- `name` is lowercase kebab-case, at most 64 characters
- `description` is at most 1024 characters
- the SKILL.md body stays under 500 lines (move detail into references/)
"""

import pathlib
import re
import sys

import yaml

NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
MAX_NAME = 64
MAX_DESCRIPTION = 1024
MAX_BODY_LINES = 500


def check(skill_md: pathlib.Path) -> list[str]:
    errors = []
    text = skill_md.read_text(encoding="utf-8")
    if not text.startswith("---"):
        return ["missing YAML frontmatter"]
    try:
        _, frontmatter, body = text.split("---", 2)
        meta = yaml.safe_load(frontmatter) or {}
    except ValueError:
        return ["frontmatter is not closed with ---"]
    except yaml.YAMLError as exc:
        return [f"frontmatter is not valid YAML: {exc}"]

    folder = skill_md.parent.name
    name = meta.get("name")
    description = meta.get("description")

    if not name:
        errors.append("missing `name`")
    else:
        if name != folder:
            errors.append(f"`name` is {name!r} but the folder is {folder!r}")
        if not NAME_RE.match(name) or len(name) > MAX_NAME:
            errors.append(f"`name` {name!r} must be lowercase kebab-case, at most {MAX_NAME} chars")

    if not description:
        errors.append("missing `description`")
    elif len(description) > MAX_DESCRIPTION:
        errors.append(f"`description` is {len(description)} chars (max {MAX_DESCRIPTION})")

    body_lines = len(body.strip().splitlines())
    if body_lines >= MAX_BODY_LINES:
        errors.append(f"body is {body_lines} lines (keep under {MAX_BODY_LINES}; move detail to references/)")

    return errors


def main() -> int:
    root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "skills")
    skills = sorted(p / "SKILL.md" for p in root.iterdir() if p.is_dir())
    failed = False
    for skill_md in skills:
        if not skill_md.exists():
            print(f"FAIL {skill_md.parent}: no SKILL.md")
            failed = True
            continue
        errors = check(skill_md)
        status = "FAIL" if errors else "ok  "
        print(f"{status} {skill_md.parent.name}")
        for err in errors:
            print(f"     - {err}")
        failed = failed or bool(errors)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
