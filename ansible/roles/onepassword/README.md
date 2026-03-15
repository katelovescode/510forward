# Ansible Role: onepassword

## Overview

This role provides an interface for managing 1Password items, primarily login credentials and custom fields, using the `op` command-line tool. It ensures idempotency by checking for existing items before creation or update.

## Requirements

- The `op` command-line tool must be installed and configured for `onepassword_become_user`.
- Variables should be stored in `secrets.yml` and encrypted with Ansible Vault.

## Variables

See `defaults/main.yml` for default values and `meta/argument_specs.yml` for complete variable documentation.

## Public Entry Points (Tasks)

This role exposes several entry points (tasks) for managing 1Password items:

- `auth_check`
- `create_item`
- `update_item`
- `delete_item`
- `create_or_update_item`

For detailed parameter documentation, see `meta/argument_specs.yml`.
