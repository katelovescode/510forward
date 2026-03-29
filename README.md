# 510 Forward

![images/guinanpicard.jpg](images/guinanpicard.jpg)
_"The idea of fitting in just repels me."_ — Guinan

Homelab infrastructure as code. Proxmox-based home server managed with Ansible (configuration) and OpenTofu (provisioning). Secrets are stored in 1Password and injected at runtime via the `op` CLI or `direnv` with `.envrc` depending on needs.

---

## Architecture

```
OpenTofu          →  what exists                (VMs, templates)
Ansible bootstrap →  one-time setup             (users, tokens, TLS cert, storage)
Ansible playbook  →  ongoing config             (services, idempotent, safe to re-run)
Ansible verify    →  post-install verification
```

**Hosts:**

| Host         | Role                                   | Type                                        |
| ------------ | -------------------------------------- | ------------------------------------------- |
| enterprise   | Proxmox VE node                        | Physical (mini PC)                          |
| andromeda    | Pi-hole secondary, HomeAssistant kiosk | Physical (Raspberry Pi 5, touchscreen case) |
| centaurus    | Pi-hole primary + nebula-sync          | LXC container                               |
| norville     | NGINX Proxy Manager (Docker)           | QEMU VM                                     |
| codsworth    | Home Assistant                         | QEMU VM (HAOS)                              |
| memory-alpha | GitLab CE                              | QEMU VM                                     |
| alexandria   | NAS                                    | Physical (Tower, TrueNAS installed)         |

**DNS + reverse proxy pattern:** Pi-hole returns norville's IP for all `*.510forward.space` subdomains. NPM on norville handles TLS termination and proxies to backends. Pi-hole nodes resolve directly to their own IPs (FTL self-protection) and are accessed via HTTP by IP.

---

## Prerequisites

Before running anything, the following must be done manually:

1. Proxmox VE installed on enterprise, accessible at its static IP
2. 1Password CLI (`op`) installed and authenticated on the controller
3. The following 1Password items created manually in the target vault:
   - **"Proxmox Root User"** — root credentials for enterprise
   - **"Cloudflare DNS API Token"** — token with DNS edit permissions, field label `credential`, field name `DNS Homelab`
   - **"1Password Automation API Token"** — op service account token for Ansible/OpenTofu
4. `direnv` installed — run `direnv allow` after cloning to load secrets from 1Password into the shell environment
5. `make install` — installs ansible-core, ansible-lint, pre-commit, passlib, and Galaxy collections. Installs into the active virtualenv if one is active, otherwise installs globally via `pipx`. A virtualenv is recommended.

---

## Usage

Run `make help` to find out all available commands

---

## Adding a new service

See [docs/add-new-host.md](docs/add-new-host.md)

## Secret management

Information that is either already defined in env vars or on the controller (GIT_AUTHOR_NAME, etc.), is needed by both tofu & ansible (SysAdmin SSH Key, etc.), or is
required for 1Password vault access (OP_SERVICE_ACCOUNT_TOKEN, etc.) live in .envrc. Everything else is in 1Password and pulled from there.

A pre-commit hook (`ansible/scripts/check_1password_titles.py`) validates that all 1Password item title references in code match items that exist in the 1Password vault.

---

## Disaster recovery

See `disaster-recovery-runbook.md` for the full DR procedure.

A pre-built Proxmox auto-installer ISO lives on a USB stick. If you ever need to rebuild the auto-installer ISO (e.g. to update the PVE version or regenerate with new credentials), `make build-proxmox-iso` handles it — no lab hosts required, runs via Docker:

```bash
make build-proxmox-iso                        # default PVE 9.1-1
make build-proxmox-iso PVE_ISO_VERSION=9.2-1  # newer version
```

Fetches credentials from 1Password, downloads the PVE ISO, and produces a ready-to-flash ISO in `proxmox_installer/`. See `proxmox_installer/README.md` for details.

---

## Verification

`ansible-playbook verify.yml` from the ansible directory - runs a verification playbook. See[ansible/verify/README.md](ansible/verify/README.md) for more info.

## Key Design Decisions

### SSH keys

Two separate keys, separate purposes:

- `id_ed25519_510forward` — kate's personal sysadmin key. Static, never rotated by
  Ansible. In 1Password, set on kate OS user via `identity/static_key`.
- `id_ed25519_ansible_510forward` — ansible automation key. Managed by Ansible via
  `identity/upsert_key`. Fetched from 1Password by `.envrc` and written to disk.
  Referenced in `ansible.cfg` as `private_key_file`.

Cloud-init provisions VMs with both keys and users so ansible can connect immediately.

### first_run_user pattern

- Default: `ansible` (cloud-init VMs, enterprise after bootstrap)
- `first_run_user: kate` — andromeda only. Raspbian doesn't have a `root` user; `kate`
  is the privileged user. SSH hardening is skipped for `raspbian_nodes` group.

  **Kiosk escape / recovery:**

  To get out of kiosk mode temporarily (e.g. for maintenance):
  1. Press `Alt+F4` or `Ctrl+Alt+T` to attempt to close/escape Chromium (may not work
     in strict kiosk mode).
  2. More reliably: switch to a virtual terminal with `Ctrl+Alt+F2`, log in as kate,
     do what you need, then `Ctrl+Alt+F7` (or F1) to return to the display.
  3. From the VT: `sudo systemctl stop lightdm` drops to console entirely; restart
     with `sudo systemctl start lightdm` when done.

  To boot outside kiosk mode (e.g. for a session as kate on the desktop):
  - Temporarily set `autologin-user=kate` in `/etc/lightdm/lightdm.conf` and reboot,
    OR run `ansible-playbook playbook.yml` from the ansible directory with
    `raspbian_kiosk_enabled: false` in group_vars to disable autologin and
    revert to the login screen. Re-enable when done.
