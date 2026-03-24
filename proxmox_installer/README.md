# Proxmox Auto-Installer Configuration

These files configure the [Proxmox VE automated installer](https://pve.proxmox.com/wiki/Automated_Installation).

## Files

- `auto-installer-mode.toml` — tells the ISO to use answer-file mode and where to find it
- `answer.toml.template` — answer file template with placeholders for secrets
- `answer.toml` — generated file (gitignored, contains secrets — do not commit)

## Building the ISO

Requires Docker and `op` CLI signed in. Downloads the Proxmox VE ISO, generates
`answer.toml` from 1Password, and produces a ready-to-flash auto-install ISO:

```bash
make build-proxmox-iso
```

To target a specific PVE version (default is `9.0-1`):

```bash
make build-proxmox-iso PVE_ISO_VERSION=9.2-1
```

Output: `proxmox_installer/proxmox-ve_<version>-auto.iso` (gitignored).

Transfer the built ISO to a USB stick for booting the Proxmox instance to re-install. A second copy should be stored on the NAS once it's running.

This step automatically runs `generate-proxmox-answer`, so it's a one-step ISO generator.

## Generating answer.toml only

`generate-proxmox-answer` is available as a standalone target if you want to inspect or validate the generated file without building the full ISO:

```bash
make generate-proxmox-answer
```

Fetches from 1Password:

- **Root password** — "Proxmox Root User", field: `password` (hashed with SHA-512)
- **SSH public key** — "SysAdmin SSH Key", field: `public key`
