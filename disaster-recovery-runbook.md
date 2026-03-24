# Disaster Recovery Runbook

## What survives, what doesn't

| Host | Type | Survives DR? |
|---|---|---|
| enterprise | Physical Proxmox host | Yes — it's the machine everything runs on |
| andromeda | Physical Raspberry Pi (Pi-hole replica) | Yes — independent hardware |
| centaurus | VM (Pi-hole primary) | No — recreated by tofu |
| norville | VM (NPM) | No — recreated by tofu |

Most likely scenario: centaurus and/or norville are gone (deleted, corrupted, disk
failure). Enterprise is up. Andromeda may or may not be up — it's independent.

---

## Prerequisites

These files are gitignored and live only on the controller. If the controller is
intact, skip ahead. If it's also gone, see "Controller loss" below.

**`ansible/secrets/vault_password`** — Ansible Vault decryption key. Required for
`make bootstrap` and `make play`. Not in git, not in 1Password (known gap). Back
this up externally.

**`.envrc`** — contains the 1Password service account token and fetches the Ansible
SSH key from 1Password on shell entry. Not in git. direnv must be installed and
`direnv allow` run from the repo root.

Verify the controller is ready before starting:

```bash
cd ~/Projects/510forward
direnv allow          # loads .envrc, fetches ansible SSH key from 1Password
op vault list         # confirms 1Password is accessible
ls ansible/secrets/vault_password  # confirms vault password is present
make install          # if dependencies aren't installed
```

---

## Step 1 — Bootstrap

```bash
make bootstrap
```

Runs as `root` on enterprise. Connects by SSH to `192.168.30.170` — no DNS needed.

What it does:
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

Connects to Proxmox API at `https://192.168.30.170:8006` directly — no DNS, no
dependency on Pi-hole or NPM. (`insecure = true` because the cert is for the
hostname, not the IP.)

What it does:
- Creates centaurus VM (Pi-hole primary, 192.168.30.77)
- Creates norville VM (NPM, 192.168.30.58)
- Cloud-init provisions both VMs with the Ansible SSH key from 1Password

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

Connects to all hosts by IP (`ansible_host` in host_vars) — no DNS needed. Runs as
the `ansible` user created in bootstrap.

Play order and dependencies:

| Play | Hosts | DNS needed? | Notes |
|---|---|---|---|
| Pre-flight | all | No | SSH wait + known_hosts by IP |
| Base config | centaurus, norville, andromeda | No (DHCP + 1.1.1.1 fallback) | ansible user, SSH hardening |
| Proxmox config | enterprise | No | repos, storage, DNS resolv.conf |
| Raspbian config | andromeda | No | wf-panel-pi clock config |
| Pi-hole | centaurus, andromeda | No (public DNS) | installs Pi-hole, configures DNS |
| NPM | norville | Yes (Pi-hole just came up) | Docker, NPM, TLS cert, proxy hosts |

Enterprise's `resolv.conf` is updated during "Proxmox config" to point at Pi-hole
IPs + `1.1.1.1` fallback. Pi-hole isn't running yet at that point, so DNS falls
through to `1.1.1.1` until the Pi-hole play completes a few steps later.

NPM cert issuance (Let's Encrypt via Cloudflare DNS-01) happens automatically during
the NPM play and takes up to 2 minutes. If it times out, re-run `make play` — the
cert task is idempotent and skips if the cert already exists.

---

## Step 4 — Verify

```bash
make verify
```

Confirms the full stack is healthy: DNS resolution, NPM end-to-end, TLS certs,
HTTP→HTTPS redirects.

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
4. Recover `ansible/secrets/vault_password`. If lost, all vault-encrypted files
   in the repo are unrecoverable and everything would need to be re-encrypted.
   **Store `vault_password` as a secure note in 1Password.**
5. Run `direnv allow`, then proceed from Step 1.
