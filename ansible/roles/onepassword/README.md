# onepassword role

Abstraction over the `op` CLI for reading, upserting, and deleting 1Password items from Ansible.

## What it does

- `read` — fetches an item by title, sets `onepassword_item_result` fact on all play hosts
- `upsert` — creates or updates an item; only writes if field values have changed (idempotent)
- `delete` — removes an item

## Authentication pattern

**All secrets used by roles in this codebase must come from 1Password via this role.** Never hardcode credentials, store them in plaintext vars, or prompt the user to paste them at runtime. If a role needs a credential that doesn't exist in 1Password yet, add a task to create it there first (see `proxmox_user/tasks/api_token.yml` for the upsert pattern).

To read a secret:

```yaml
- name: Read my secret
  ansible.builtin.include_role:
    name: onepassword
  vars:
    onepassword_action: read
    onepassword_item:
      title: "My 1Password Item"
  no_log: true

- name: Use the secret
  ansible.builtin.set_fact:
    _my_role_secret: >-
      {{
        onepassword_item_result.fields |
        selectattr('label', 'equalto', 'credential') |
        map(attribute='value') | first
      }}
  no_log: true
```

## Why `delegate_to: localhost`

The `op` CLI runs on the controller (the machine running Ansible), not on remote hosts. All `op` commands are delegated to localhost where the service account token is available via the `.envrc`.

## op CLI quirks

- `op item create` and `op item edit` fail when stdin is a pipe — always append `</dev/null` to shell commands that call these.
- `op item create --category ssh` does not support `--template`.
- `ssh-keygen -y -f /dev/stdin` fails on macOS — write the key to a temp file via `mktemp` instead.

## Item title validation

A pre-commit hook (`ansible/scripts/check_1password_titles.py`) validates all item title strings referenced in the codebase against actual 1Password items at commit time. If you rename an item in 1Password, update every reference in the code before committing — the hook will catch mismatches. The hook skips gracefully if `op` is not signed in.
