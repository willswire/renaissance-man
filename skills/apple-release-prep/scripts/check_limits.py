#!/usr/bin/env python3
"""Check App Store Connect field lengths.

    python3 check_limits.py --field release_notes --text "..."
    python3 check_limits.py --field subtitle --file draft.txt
    python3 check_limits.py --metadata-dir fastlane/metadata/en-US

Counts characters the way App Store Connect does: the whole string including
spaces and newlines, with a trailing newline ignored. Over-limit fields are
rejected or truncated at submission, so this is worth running on every draft.
"""

import argparse
import sys
from pathlib import Path

LIMITS = {
    "name": 30,
    "subtitle": 30,
    "promotional_text": 170,
    "description": 4000,
    "keywords": 100,
    "release_notes": 4000,
    "reviewer_notes": 4000,
    "copyright": 200,
}

# Where each field lives under fastlane/metadata. Most are per-locale; copyright
# and reviewer notes are not, which is the detail people get wrong.
FASTLANE_PATHS = {
    "name": "<locale>/name.txt",
    "subtitle": "<locale>/subtitle.txt",
    "promotional_text": "<locale>/promotional_text.txt",
    "description": "<locale>/description.txt",
    "keywords": "<locale>/keywords.txt",
    "release_notes": "<locale>/release_notes.txt",
    "copyright": "copyright.txt",
    "reviewer_notes": "review_information/notes.txt",
}

# Practical targets, not Apple's limits. Release notes have no natural stopping
# point, so the useful signal is "this is longer than anyone will read", well
# before the hard cap.
SOFT_TARGETS = {"release_notes": 600}


def check(field: str, text: str) -> bool:
    text = text.rstrip("\n")
    limit = LIMITS.get(field)
    n = len(text)
    if limit is None:
        print(f"{field}: {n} chars (no known limit)")
        return True
    ok = n <= limit
    status = "OK" if ok else "OVER"
    print(f"{field}: {n}/{limit} chars — {status}")
    if not ok:
        print(f"  trim {n - limit} characters")
    soft = SOFT_TARGETS.get(field)
    if ok and soft and n > soft:
        print(f"  note: past the ~{soft} char point where notes stop being read")
    if field == "copyright":
        stripped = text.lstrip("\u00a9 ").strip()
        year = stripped[:4]
        if not (year.isdigit() and len(stripped) > 4):
            print("  note: expected '<year> <holder>' — the year the rights were")
            print("        obtained (first publication), not the current year")
    if field == "reviewer_notes" and not text.strip():
        print("  note: empty — omit the field rather than submitting filler")
    if field == "keywords":
        if ", " in text:
            print("  note: spaces after commas waste characters App Store Connect counts")
        terms = [t for t in text.split(",") if t.strip()]
        print(f"  {len(terms)} keyword terms")
    return ok


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--field", choices=sorted(LIMITS))
    p.add_argument("--text")
    p.add_argument("--file")
    p.add_argument("--metadata-dir", help="a fastlane locale dir, e.g. fastlane/metadata/en-US")
    a = p.parse_args()

    all_ok = True

    if a.metadata_dir:
        d = Path(a.metadata_dir)
        if not d.is_dir():
            print(f"not a directory: {d}", file=sys.stderr)
            return 2
        # Accept either a locale dir (fastlane/metadata/en-US) or the metadata
        # root, and check the non-localized files wherever they actually are.
        roots = [d, d.parent, d / "review_information", d.parent / "review_information"]
        found = False
        for field in sorted(LIMITS):
            rel = FASTLANE_PATHS[field].split("/")[-1]
            for r in roots:
                f = r / rel
                if f.exists():
                    found = True
                    all_ok &= check(field, f.read_text(encoding="utf-8"))
                    break
        missing = [f for f in ("release_notes",) if not any((r / "release_notes.txt").exists() for r in roots)]
        if missing:
            print("missing: release_notes.txt — required for every version")
            all_ok = False
        if not found:
            print(f"no known metadata files in or around {d}")
        return 0 if all_ok else 1

    if not a.field:
        p.error("--field is required unless --metadata-dir is used")
    if a.file:
        text = Path(a.file).read_text(encoding="utf-8")
    elif a.text is not None:
        text = a.text
    else:
        text = sys.stdin.read()

    return 0 if check(a.field, text) else 1


if __name__ == "__main__":
    raise SystemExit(main())
