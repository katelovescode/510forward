# 510 Forward

![images/guinanpicard.jpg](images/guinanpicard.jpg)
_"The idea of fitting in just repels me."_ — Guinan

Homelab infrastructure as code. Proxmox-based home server managed with Ansible (configuration) and OpenTofu (provisioning). Secrets are stored in 1Password and injected at runtime via the `op` CLI; secrets that must be committed are encrypted with ansible-vault.

---

## Architecture

```
OpenTofu          →  what exists                (VMs, templates)
Ansible bootstrap →  one-time setup             (users, tokens, TLS cert, storage)
Ansible playbook  →  ongoing config             (services, idempotent, safe to re-run)
Ansible verify    →  post-install verification
```

**Hosts:**

| Host         | Type                                        | Role                                   |
| ------------ | ------------------------------------------- | -------------------------------------- |
| enterprise   | Physical (mini PC)                          | Proxmox VE node                        |
| andromeda    | Physical (Raspberry Pi 5, touchscreen case) | Pi-hole secondary, HomeAssistant kiosk |
| centaurus    | QEMU VM                                     | Pi-hole primary + nebula-sync          |
| norville     | QEMU VM                                     | NGINX Proxy Manager (Docker)           |
| dorothy      | QEMU VM                                     | Homepage dashboard                     |
| codsworth    | QEMU VM (HAOS)                              | Home Assistant                         |
| memory-alpha | QEMU VM                                     | GitLab CE                              |
| hermes       | QEMU VM                                     | GitLab Runner                          |
| alexandria   | Physical (Tower, TrueNAS installed)         | NAS                                    |

**DNS + reverse proxy pattern:** Pi-hole returns norville's IP for all `*.510forward.space` subdomains. NPM on norville handles TLS termination and proxies to backends. Pi-hole nodes resolve directly to their own IPs (FTL self-protection) and are accessed via HTTP by IP.

---

## Prerequisites

Before running anything, the following must be done manually:

1. Proxmox VE installed on enterprise, accessible at its static IP
2. 1Password CLI (`op`) installed and authenticated on the controller
3. The following 1Password items created manually in your vault:
   - **"Proxmox Root User"** — root credentials for enterprise
   - **"Cloudflare DNS API Token"** — token with DNS edit permissions, field label `credential`, field name `DNS Homelab`
   - **"1Password Automation API Token"** — op service account token for Ansible/OpenTofu
4. `direnv` installed — run `direnv allow` after cloning to load secrets from 1Password into the shell environment
5. `make install` — installs ansible-core, ansible-lint, pre-commit, passlib, and Galaxy collections. Installs into the active virtualenv if one is active, otherwise installs globally via `pipx`. A virtualenv is recommended.

---

## Usage

Run `make help` to find out all available commands. The most common:

```bash
make install                    # Install dependencies and pre-commit hooks
make bootstrap                  # One-time bootstrap (run once, as sysadmin, before tofu apply)
make tofu-proxmox ARGS='plan'   # Preview VM changes
make tofu-proxmox ARGS='apply'  # Provision VMs
make play                       # Run main Ansible playbook (idempotent)
make verify                     # Run acceptance tests against live infrastructure
make lint                       # ansible-lint + tflint
```

`make bootstrap` is only required for initial setup or disaster recovery, but it's still idempotent. It only acts on Proxmox and gets the system "ready".

### Upgrades

```bash
make upgrade                    # all apt-managed hosts, one at a time
make upgrade LIMIT=andromeda    # single host
make upgrade LIMIT=qemu_vms     # group
```

Prompts before upgrading each host and again before rebooting if a reboot is required. Hosts are processed serially to avoid taking both Pi-hole nodes down simultaneously.

**memory-alpha is excluded** even with `LIMIT=memory-alpha`. GitLab CE can be installed via the apt repo, so `apt upgrade` might pull a new GitLab version. GitLab upgrades must follow a specific version path (no skipping major versions) and need to be intentional — they're not safe to run as part of a general upgrade sweep. To upgrade memory-alpha OS packages without touching GitLab, hold the package first: `apt-mark hold gitlab-ce`.

HAOS (codsworth) is also excluded — it manages its own updates.

---

## Adding a new service

Every service that needs a browser URL requires two changes, then `make play`:

1. **NPM proxy host** — add to `nginx_proxy_manager_proxy_hosts` in `ansible/inventory/host_vars/norville/vars.yml`:

   ```yaml
   - subdomain: myservice
     host: "{{ hostvars['myservice']['ip_address'] }}"
     port: 8080
     scheme: http
   ```

2. **Pi-hole DNS** — add to `ansible/inventory/host_vars/myservice/vars.yml`:
   ```yaml
   npm_proxied: true
   ```

---

## Secret management

**Decision framework:**

|                    | Secret                                  | Not secret              |
| ------------------ | --------------------------------------- | ----------------------- |
| **Multiple tools** | `.envrc` - OP Vault info and Git info   | `.envrc` or hardcoded   |
| **OpenTofu only**  | gitignored `.tfvars` (currently unused) | `.tf` variable defaults |
| **Ansible only**   | vault-encrypted file in `ansible/`      | regular `vars.yml`      |

Everything that can go in 1Password does.

> **Planned simplification:** Ansible vault is redundant. `onepassword_vault` duplicates `OP_VAULT_ID`; `sysadmin_public_key` duplicates `SYSADMIN_PUBLIC_KEY` — both already in `.envrc`. `onepassword_become_user` is non-sensitive and becomes a plaintext var. `proxmox_admin_password_salt` moves to 1Password. Once vault is empty, `vault_password.sh`, the vault password item in 1Password, and all `secrets.yml` files can be removed. See future work in the plan doc.

A pre-commit hook (`ansible/scripts/check_secrets.py`) blocks commits if any secrets in `ansible/` are unencrypted. A second hook (`ansible/scripts/check_1password_titles.py`) validates that all 1Password item title references in code match items that exist in your 1Password vault.

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

`make verify` runs automated acceptance tests after `make play`. These and manual tests are documented in `ansible/verify/README.md`.

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
    OR run `make play` with `raspbian_kiosk_enabled: false` in group_vars to disable
    autologin and revert to the login screen. Re-enable when done.
