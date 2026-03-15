#!/usr/bin/env python3
"""
Pre-commit hook that checks:
1. All secrets.yml files are vault-encrypted (always runs)
2. All secrets.yml keys have a corresponding entry in secrets.example.yml
   (only runs when ansible-vault is available)
"""
import sys
import subprocess
import shutil
import configparser
import yaml
from pathlib import Path

VAULT_HEADER = "$ANSIBLE_VAULT;1.1;AES256"
errors = []

git_result = subprocess.run(
    ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"],
    capture_output=True,
    text=True
)

secrets_files = [
    Path(f) for f in git_result.stdout.split("\0")
    if f.endswith("secrets.yml")
]

searched_dirs = sorted({f.parts[0] for f in secrets_files})
print(f"Searching: {', '.join(searched_dirs)}", file=sys.stderr)
print(f"To exclude a directory, add it to .gitignore", file=sys.stderr)

# --- Header check (always runs) ---
for secrets_file in secrets_files:
    with open(secrets_file) as f:
        first_line = f.readline().strip()
    if first_line != VAULT_HEADER:
        errors.append(f"{secrets_file} is not vault-encrypted")

if errors:
    for e in errors:
        print(f"ERROR: {e}", file=sys.stderr)
    sys.exit(1)

# --- Completeness check (ansible-vault required) ---
if not shutil.which("ansible-vault"):
    print("ansible-vault not found, skipping completeness check", file=sys.stderr)
    sys.exit(0)

config = configparser.ConfigParser()
script_dir = Path(__file__).parent
config.read(script_dir / ".." / "ansible.cfg")
vault_password_file = config.get("defaults", "vault_password_file", fallback=None)

if not vault_password_file:
    print("ERROR: vault_password_file not set in ansible.cfg", file=sys.stderr)
    sys.exit(1)

for secrets_file in secrets_files:
    example_file = secrets_file.parent / "secrets.example.yml"
    if not example_file.exists():
        errors.append(f"Missing: {example_file}")
        continue

    result = subprocess.run(
        ["ansible-vault", "view", str(secrets_file), "--vault-password-file", vault_password_file],
        capture_output=True,
        text=True
    )
    if result.returncode != 0:
        errors.append(f"Failed to decrypt {secrets_file}: {result.stderr.strip()}")
        continue

    secrets_keys = set(yaml.safe_load(result.stdout).keys())

    with open(example_file) as f:
        example_content = yaml.safe_load(f)
    example_keys = set(example_content.keys()) if example_content else set()

    missing = secrets_keys - example_keys
    if missing:
        errors.append(f"{example_file} is missing keys: {', '.join(sorted(missing))}")

if errors:
    for e in errors:
        print(f"ERROR: {e}", file=sys.stderr)
    sys.exit(1)

sys.exit(0)