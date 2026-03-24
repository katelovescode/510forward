# os_user role

Creates OS users in two variants: admin (human) and service (automation).

## What it does

- `admin_user` — creates a human user with a real password (hashed, stored in 1Password), sudo access, and a login shell
- `service_user` — creates a passwordless automation user with sudo access and no login shell requirement

## Why two variants

Admin users (e.g. `kate`) need a password for console login when SSH isn't available — for example, during initial Proxmox setup or if the SSH key is lost. Service users (e.g. `ansible`, `opentofu`) never log in interactively and don't need passwords. Keeping them separate makes the intent explicit and avoids accidentally granting password login to automation accounts.

## Password hashing

Admin user passwords are generated once and stored in 1Password. The role fetches the stored hash (or generates a new one on first run) using the `ansible.builtin.password_hash` filter with a stable salt from vault (`proxmox_admin_password_salt`). The salt must be stable across runs so the hash doesn't change on every play, which would show as a spurious change.
