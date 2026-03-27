# Disaster Recovery Runbook

## Prerequisites

These files are gitignored and live only on the controller. If the controller is
intact, skip ahead. If it's also gone, see "Controller loss" below.

**`.envrc`** — contains the 1Password service account token and fetches the Ansible
SSH key from 1Password on shell entry. Not in git. direnv must be installed and
`direnv allow` run from the repo root.

Verify the controller is ready before starting:

```bash
cd ~/Projects/510forward
direnv allow          # loads .envrc, fetches ansible SSH key from 1Password
op vault list         # confirms 1Password is accessible
make install          # if dependencies aren't installed
```

---

## Step 1 — Bootstrap

```bash
make bootstrap
```

- Creates OS users: `kate`, `ansible`, `opentofu`
- Creates Proxmox PAM users and roles: `kate@pam` (Administrator), `ansible` and `opentofu` (scoped service roles + API tokens)
- Stores SSH keys and API tokens in 1Password
- Configures apt repos (no-subscription)
- Issues the Let's Encrypt TLS cert for `enterprise.510forward.space` via Proxmox ACME + Cloudflare DNS-01
- Configures local storage content types (snippets, ISO, etc.)

Bootstrap uses `validate_certs: false` for Proxmox API calls — the ACME cert hasn't
been issued yet at that point.

If DNS on enterprise is broken, bootstrap will temporarily write `1.1.1.1` to
`/etc/resolv.conf` automatically.

---

## Step 2 — Provision VMs

```bash
make tofu-proxmox ARGS='apply'
```

- Creates VMs, initialized with cloud-init

If only one VM needs to be recreated:

```bash
make tofu-recreate HOSTS=centaurus
make tofu-recreate HOSTS=norville
make tofu-recreate HOSTS=centaurus,norville
```

---

## Step 3 — Configure

```bash
make play
```

Configures all services.

---

## Step 4 — Verify

```bash
make verify
```

Confirms the full stack is healthy

---

## Partial recovery

If only one service is broken, target it directly:

```bash
# Recreate just the Pi-hole VM and reconfigure it
make tofu-recreate HOSTS=centaurus
make play  # idempotent — only centaurus will have meaningful changes

# Recreate just norville and reconfigure it
make tofu-recreate HOSTS=norville
make play

# Pi-hole config drifted but VM is fine
make play  # idempotent

# Force Pi-hole sync from primary to replica
make sync-pihole
```

---

## Controller loss

If the controller is also gone, reconstruct it first:

1. Clone the repo on a new machine
2. Install direnv
3. Recreate `.envrc` — the 1Password service account token is embedded in the
   original `.envrc`. Without a backup, create a new service account in 1Password
   and update the token. **Back up `.envrc` externally.**
4. Run `direnv allow`, then proceed from Step 1.
