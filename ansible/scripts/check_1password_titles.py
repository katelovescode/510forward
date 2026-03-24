#!/usr/bin/env python3
"""
Pre-commit hook that validates all 1Password item title references in the repo
exist in the Homelab vault.

Exits 0 if all titles are found (or op is unavailable), 1 if any are missing.
"""
import re
import subprocess
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).parent.parent.parent
VAULT = "homelab"

# Patterns that reference 1Password item titles
OP_GET_PATTERN = re.compile(r"\bop item get [\"']([^\"']+)[\"']")
OP_READ_PATTERN = re.compile(r"\bop read [\"']op://[^/]+/([^/?\"']+)/")
YAML_TITLE_PATTERN = re.compile(r"^\s+title:\s+[\"']([^\"']+)[\"']")


def get_tracked_files():
    result = subprocess.run(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"],
        capture_output=True,
        text=True,
    )
    return [Path(f) for f in result.stdout.split("\0") if f]


def get_vault_titles():
    result = subprocess.run(
        ["op", "item", "list", "--vault", VAULT, "--format", "json"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return None
    return {item["title"] for item in json.loads(result.stdout)}


def find_references(files):
    refs = {}  # title -> [(path, lineno)]

    for path in files:
        if not path.is_file():
            continue
        # Skip example/template files — they contain placeholder titles
        if path.name.endswith(".example") or ".example." in path.name:
            continue
        try:
            text = path.read_text()
        except (UnicodeDecodeError, PermissionError):
            continue

        is_yaml = path.suffix in (".yml", ".yaml")
        yaml_has_op = is_yaml and ("onepassword" in text.lower() or "op item" in text)

        for i, line in enumerate(text.splitlines(), 1):
            for m in OP_GET_PATTERN.finditer(line):
                title = m.group(1)
                refs.setdefault(title, []).append((path, i))

            for m in OP_READ_PATTERN.finditer(line):
                title = m.group(1)
                refs.setdefault(title, []).append((path, i))

            if yaml_has_op:
                m = YAML_TITLE_PATTERN.match(line)
                if m:
                    title = m.group(1)
                    refs.setdefault(title, []).append((path, i))

    return refs


def main():
    result = subprocess.run(["op", "whoami"], capture_output=True)
    if result.returncode != 0:
        print("op not signed in, skipping 1Password title check", file=sys.stderr)
        sys.exit(0)

    vault_titles = get_vault_titles()
    if vault_titles is None:
        print(f"Could not list items in vault '{VAULT}', skipping", file=sys.stderr)
        sys.exit(0)

    files = get_tracked_files()
    refs = find_references(files)

    errors = []
    for title, locations in sorted(refs.items()):
        # Skip Jinja2 template variables — they're resolved at runtime, not literal titles
        if "{{" in title:
            continue
        if title not in vault_titles:
            for path, lineno in locations:
                errors.append(f"{path}:{lineno}: 1Password item not found: '{title}'")

    if errors:
        for e in errors:
            print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)

    print(
        f"OK: {len(refs)} 1Password item title(s) verified in vault '{VAULT}'",
        file=sys.stderr,
    )
    sys.exit(0)


if __name__ == "__main__":
    main()
