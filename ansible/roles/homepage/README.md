# homepage role

Installs and configures [Homepage](https://gethomepage.dev) v1.5.0 on dorothy. Manages a `homepage@pve` Proxmox API user for VM status widgets. Fetches all secrets from 1Password.

## What it does

- Installs Node.js and pnpm, builds Homepage from source, runs it as a systemd service on port 3000
- Creates a 1GB swapfile before the build step
- Creates `homepage@pve` Proxmox user with a read-only role and stores its API token in 1Password
- Fetches Pi-hole and NPM credentials from 1Password to populate service widgets
- Templates Homepage config files with live inventory data (VM IDs, IPs, service URLs)

## Why Node.js from source, not Docker

Homepage is distributed as a Docker image but dorothy runs Homepage directly on the OS via systemd. The upstream Docker image is the reference distribution but adds operational overhead (Docker socket exposure for widget access, volume management) for a service that is otherwise self-contained. Node.js from source gives a simpler systemd unit and direct filesystem access to config files.

## Why a 1GB swapfile is required

Homepage uses Next.js, which has a memory-intensive build step. On a VM with limited RAM, the build process OOM-kills without swap. The swapfile is created, formatted with `mkswap`, and activated before the build runs. It persists across reboots via `/etc/fstab`.

## Proxmox API user

Homepage needs read-only access to Proxmox to display VM status. The role creates:

- A `homepage` Proxmox role with `VM.Audit`, `Sys.Audit`, `Datastore.Audit`
- A `homepage` group with that role at path `/`
- A `homepage@pve` user in that group
- An API token stored in 1Password as "Proxmox Homepage API Token"

The token is fetched at runtime and written into Homepage's `services.yaml`. It is never stored in the repo.

## Secret management

All credentials (Pi-hole password, NPM credentials, Proxmox token) are fetched from 1Password using the `onepassword` role at play time. No secrets are stored in inventory or group_vars.
