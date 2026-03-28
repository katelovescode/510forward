#!/usr/bin/env python3
"""
Pre-commit hook enforcing documentation and argument_specs requirements.

Rules:
  1. New proxmox_virtual_environment_vm or proxmox_virtual_environment_container
     resource added in a .tf file → docs/runbooks/add-new-host.md must be
     touched in the same commit.
  2. New directory under ansible/roles/ → must contain meta/argument_specs.yml.
  3. New role-prefixed variable ({{ rolename_* }}) added in a role task file →
     variable must be declared in the role's meta/argument_specs.yml.

Exits 0 if all rules pass, 1 if any violations are found.
"""
import re
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).parent.parent.parent


def get_staged_files():
    result = subprocess.run(
        ["git", "diff", "--cached", "--name-only", "--diff-filter=ACMR"],
        capture_output=True,
        text=True,
        cwd=REPO_ROOT,
    )
    return [Path(f) for f in result.stdout.splitlines() if f]


def get_staged_diff():
    result = subprocess.run(
        ["git", "diff", "--cached", "-U0"],
        capture_output=True,
        text=True,
        cwd=REPO_ROOT,
    )
    return result.stdout


def read_staged_file(rel_path):
    """Read a file's staged (index) content. Returns None if not staged."""
    result = subprocess.run(
        ["git", "show", f":{rel_path}"],
        capture_output=True,
        text=True,
        cwd=REPO_ROOT,
    )
    if result.returncode != 0:
        return None
    return result.stdout


def check_new_proxmox_resources(staged_files, diff_text):
    """Rule 1: New VM/LXC resources require add-new-host.md to be touched."""
    resource_pattern = re.compile(
        r'^\+\s*resource\s+"'
        r"(proxmox_virtual_environment_vm|proxmox_virtual_environment_container)"
        r'"\s+"'
    )

    found_new_resource = any(resource_pattern.match(line) for line in diff_text.splitlines())
    if not found_new_resource:
        return []

    runbook = Path("docs/runbooks/add-new-host.md")
    if runbook not in staged_files:
        return [
            "New Proxmox VM or LXC resource added but docs/runbooks/add-new-host.md "
            "was not staged. Update the runbook or touch it to acknowledge the change."
        ]
    return []


def check_new_roles(staged_files):
    """Rule 2: New role directories must contain meta/argument_specs.yml."""
    errors = []

    role_dirs = set()
    for f in staged_files:
        parts = f.parts
        if len(parts) >= 3 and parts[0] == "ansible" and parts[1] == "roles":
            role_dirs.add(parts[2])

    for role_name in sorted(role_dirs):
        role_path = REPO_ROOT / "ansible" / "roles" / role_name
        if not role_path.is_dir():
            continue
        specs_rel = f"ansible/roles/{role_name}/meta/argument_specs.yml"
        # Check staged index first, fall back to filesystem
        if read_staged_file(specs_rel) is None and not (role_path / "meta" / "argument_specs.yml").exists():
            errors.append(
                f"ansible/roles/{role_name}/ has no meta/argument_specs.yml — "
                "all roles must declare their variables in argument_specs."
            )

    return errors


def check_new_variables(diff_text):
    """Rule 3: New role-prefixed variables in task files must appear in argument_specs."""
    errors = []

    # Capture the primary variable name at the start of a Jinja2 expression.
    # Handles: {{ varname }}, {{ varname | filter }}, {{ varname if ... }}
    var_pattern = re.compile(r"\{\{-?\s*(\w+)")

    # Collect new variable usages per role from added lines in task files
    new_vars_by_role: dict[str, set[str]] = {}
    current_role = None
    in_task_file = False

    for line in diff_text.splitlines():
        if line.startswith("+++ b/"):
            path = Path(line[6:])
            parts = path.parts
            in_task_file = (
                len(parts) >= 5
                and parts[0] == "ansible"
                and parts[1] == "roles"
                and parts[3] == "tasks"
                and path.suffix in (".yml", ".yaml")
            )
            current_role = parts[2] if in_task_file else None
            continue

        if not in_task_file or not line.startswith("+") or line.startswith("+++"):
            continue

        added_line = line[1:]
        for m in var_pattern.finditer(added_line):
            varname = m.group(1)
            if current_role and varname.startswith(current_role + "_"):
                new_vars_by_role.setdefault(current_role, set()).add(varname)

    for role_name, varnames in sorted(new_vars_by_role.items()):
        specs_rel = f"ansible/roles/{role_name}/meta/argument_specs.yml"
        specs_text = read_staged_file(specs_rel)
        if specs_text is None:
            specs_path = REPO_ROOT / "ansible" / "roles" / role_name / "meta" / "argument_specs.yml"
            if not specs_path.exists():
                # Rule 2 will report the missing specs file — don't double-report
                continue
            specs_text = specs_path.read_text()

        for varname in sorted(varnames):
            # Look for the variable name as a YAML mapping key in argument_specs
            if not re.search(r"^\s+" + re.escape(varname) + r"\s*:", specs_text, re.MULTILINE):
                errors.append(
                    f"Variable '{varname}' used in ansible/roles/{role_name}/tasks/ "
                    f"but not declared in ansible/roles/{role_name}/meta/argument_specs.yml"
                )

    return errors


def main():
    staged_files = get_staged_files()
    diff_text = get_staged_diff()

    errors = []
    errors.extend(check_new_proxmox_resources(staged_files, diff_text))
    errors.extend(check_new_roles(staged_files))
    errors.extend(check_new_variables(diff_text))

    if errors:
        for e in errors:
            print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)

    print("OK: documentation and argument_specs checks passed", file=sys.stderr)
    sys.exit(0)


if __name__ == "__main__":
    main()
