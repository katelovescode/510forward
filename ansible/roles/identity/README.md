# identity role

Manages SSH key lifecycle and `known_hosts` entries across the lab.

## What it does

- `known_hosts` — scans and registers host keys in `~/.ssh/known_hosts` on the controller
- `static_key` — places a static SSH public key on a user's `authorized_keys` (used for kate's personal sysadmin key)
- `upsert_key` — generates an SSH keypair if it doesn't exist, stores it in 1Password, and places the public key in `authorized_keys` (used for the ansible automation key)

## Two keys, two purposes

There are two SSH keys in this lab, intentionally separate:

| Key | Item | Managed by | Purpose |
|---|---|---|---|
| `id_ed25519_510forward` | "SysAdmin SSH Key" | Static — never rotated by Ansible | kate's personal sysadmin access |
| `id_ed25519_ansible_510forward` | "Ansible SSH Key" | `identity/upsert_key` | Ansible automation |

The ansible key is what cloud-init provisions on new VMs, so Ansible can connect immediately without any manual key setup. The sysadmin key is a separate break-glass path that Ansible never touches.

## known_hosts gotchas

Several non-obvious things apply when managing `known_hosts`:

- **`serial: 1`** on the pre-flight play — parallel writes to `~/.ssh/known_hosts` from multiple hosts corrupt entries. Keys must be written one at a time.
- **No `-H` flag** on `ssh-keyscan` — hashed host keys cause mismatches in the `known_hosts` module. Plain IPs only.
- **Strip comment lines** from keyscan output — the `known_hosts` module has newline handling issues with `#` comment lines.
- **Wait for SSH before scanning** — `ssh-keyscan` before sshd is ready silently returns nothing and leaves a stale (possibly empty) entry. The task retries until stdout is non-empty.
- **Retry on keyscan** (`retries: 5, delay: 3`) — sshd can accept TCP connections before it's fully ready to serve host keys. Retrying closes this race.
