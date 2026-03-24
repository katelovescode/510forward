# 510 Forward

![images/guinanpicard.jpg](images/guinanpicard.jpg)
_"The idea of fitting in just repels me."_ — Guinan

Homelab infrastructure as code. Proxmox-based home server managed with Ansible (configuration) and OpenTofu (provisioning). Secrets are stored in 1Password and injected at runtime via the `op` CLI; secrets that must be committed are encrypted with ansible-vault.

---

## Architecture

```
OpenTofu          →  what exists       (VMs, templates)
Ansible bootstrap →  one-time setup    (users, tokens, TLS cert, storage)
Ansible playbook  →  ongoing config    (services, idempotent, safe to re-run)
```

**Hosts:**

| Host | Type | Role |
|------|------|------|
| enterprise | Physical (mini PC) | Proxmox VE node |
| andromeda | Physical (Raspberry Pi 5) | Pi-hole secondary, desktop |
| centaurus | QEMU VM | Pi-hole primary + nebula-sync |
| norville | QEMU VM | NGINX Proxy Manager (Docker) |
| dorothy | QEMU VM | Homepage dashboard |
| codsworth | QEMU VM (HAOS) | Home Assistant |
| memory-alpha | QEMU VM | GitLab CE |
| hermes | QEMU VM | TBD |

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

All commands run from the repo root via `make`:

```bash
make install          # Install dependencies and pre-commit hooks
make bootstrap        # One-time bootstrap (run once, as sysadmin, before tofu apply)
make tofu-proxmox ARGS='plan'   # Preview VM changes
make tofu-proxmox ARGS='apply'  # Provision VMs
make play             # Run main Ansible playbook (idempotent)
make verify           # Run acceptance tests against live infrastructure
make lint             # ansible-lint + tflint
make sync-pihole      # Manually trigger nebula-sync on centaurus
make edit-secret FILE=ansible/inventory/group_vars/all/secrets.yml  # Edit a vault-encrypted file
```

`make bootstrap` is only required for initial setup or disaster recovery. Adding new services starts at `make tofu-proxmox ARGS='apply'` or `make play` depending on whether new VMs are needed.

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

That's it. `make play` applies both changes and every device on the network picks up the new DNS answer automatically.

---

## Secret management

**Decision framework:**

| | Secret | Not secret |
|---|---|---|
| **Multiple tools** | `.envrc` | `.envrc` or hardcoded |
| **OpenTofu only** | gitignored `.tfvars` (escape hatch — currently unused, tofu secrets go via 1Password) | `.tf` variable defaults |
| **Ansible only** | vault-encrypted file in `ansible/` | regular `vars.yml` |

**1Password is the canonical store for all secrets** except the `op` token itself (circular dependency — you need `op` to read from 1Password). Everything that can go in 1Password does. The layers above are access mechanisms, not separate secret stores.

**Current state:**

- **`.envrc`** — controller bootstrap config, loaded by `direnv`, never committed:
  - `OP_SERVICE_ACCOUNT_TOKEN` — root op credential; the only secret that can't live in 1Password
  - `OP_VAULT_ID` — 1Password vault ID; used by both `tofu/tofu.sh` and `ansible/scripts/vault_password.sh`
  - `SYSADMIN_PUBLIC_KEY` — kate's SSH public key; used by `tofu/tofu.sh`
  - Git author config and other non-secret controller config
- **Ansible vault** — `onepassword_vault`, `onepassword_become_user`, `sysadmin_public_key`, `proxmox_admin_password_salt`. These predate the 1Password-first approach; `OP_VAULT_ID` and `SYSADMIN_PUBLIC_KEY` are already in `.envrc` (vault copies are redundant). Candidates for full elimination — see below.
- **1Password** — all runtime secrets: Proxmox credentials and API tokens, SSH key pairs, Pi-hole/NPM/GitLab passwords, Cloudflare DNS token, ansible vault password.
- **OpenTofu** — no `.tfvars` secrets; all sensitive values fetched from 1Password at runtime via `tofu/tofu.sh`.

> **Planned simplification:** Ansible vault is redundant. `onepassword_vault` duplicates `OP_VAULT_ID`; `sysadmin_public_key` duplicates `SYSADMIN_PUBLIC_KEY` — both already in `.envrc`. `onepassword_become_user` is non-sensitive and becomes a plaintext var. `proxmox_admin_password_salt` moves to 1Password. Once vault is empty, `vault_password.sh`, the vault password item in 1Password, and all `secrets.yml` files can be removed. See future work in the plan doc.

A pre-commit hook (`ansible/scripts/check_secrets.py`) blocks commits if any secrets in `ansible/` are unencrypted. A second hook (`ansible/scripts/check_1password_titles.py`) validates that all 1Password item title references in code match items that exist in your 1Password vault.

---

## Disaster recovery

See `disaster-recovery-runbook.md` for the full DR procedure.

A pre-built auto-installer ISO lives on a USB stick. If you ever need to rebuild it (e.g. to update the PVE version or regenerate with new credentials), `make build-proxmox-iso` handles it — no lab hosts required, runs via Docker:

```bash
make build-proxmox-iso                        # default PVE 9.1-1
make build-proxmox-iso PVE_ISO_VERSION=9.2-1  # newer version
```

Fetches credentials from 1Password, downloads the PVE ISO, and produces a ready-to-flash ISO in `proxmox_installer/`. See `proxmox_installer/README.md` for details.

---

## Verification

`make verify` runs automated acceptance tests after `make play`. Tests are organized in `ansible/verify/` by concern: DNS, QEMU guest agent, NPM, TLS, Home Assistant, GitLab.

Some checks require manual intervention because they're stateful or destructive — stopping `pihole-FTL` to verify failover, or stopping both Pi-hole nodes to confirm fallback to `1.1.1.1`. These are documented in `ansible/verify/README.md`.
