# Disaster Recovery Runbook

Full rebuild of the lab from scratch. Follow steps in order — DNS comes up
first because everything else depends on it.

---

## Prerequisites

These files are gitignored and live only on the controller. If the controller
is intact, skip to Step 1. If the controller is also gone, see
[Controller loss](#controller-loss) first.

**`.envrc`** — contains the 1Password service account token and fetches the
Ansible SSH key from 1Password on shell entry. Not in git. `direnv` must be
installed and `direnv allow` run from the repo root.

Verify the controller is ready:

```bash
cd ~/Projects/510forward
direnv allow          # loads .envrc, fetches ansible SSH key from 1Password
op vault list         # confirms 1Password is accessible
make install          # if dependencies aren't installed
```

---

## Step 1 — Lab bootstrap (Proxmox host)

```bash
make lab-bootstrap
```

Runs as root/sysadmin (before automation users exist). Creates:

- OS users: `kate`, `ansible`, `opentofu`
- Proxmox PAM users and roles with scoped API tokens
- SSH keys and API tokens stored in 1Password
- apt repos (no-subscription), ACME/TLS cert, storage config

Uses `validate_certs: false` for Proxmox API calls — the ACME cert hasn't
been issued yet at this point.

If DNS on enterprise is broken, bootstrap temporarily writes `1.1.1.1` to
`/etc/resolv.conf` automatically.

---

## Step 2 — Provision VMs and LXC containers

```bash
make tofu-proxmox ARGS='apply'
```

Creates all VMs and LXC containers. MAC addresses are fixed so DHCP assigns
the same IPs as before.

---

## Step 3 — Bootstrap hosts (DNS first)

Centaurus must come first since it provides DNS for all other hosts.

```bash
make play LIMIT=centaurus
```

Verify DNS is working before continuing:

`dig @192.168.30.77 enterprise.510forward.space`

Then configure the remaining hosts:

```
make play
```

GitLab initialization takes several minutes after Ansible completes. Wait for the web UI to respond at https://memory-alpha.510forward.space before proceeding to Step 4.

---

## Step 4 — Full maintenance run

```bash
make play
```

Applies all remaining configuration across all hosts. Safe to re-run.

---

## Step 5 — Verify

```bash
make verify
```

Confirms the full stack is healthy.

---

## Partial recovery

If only one service is broken, target it directly:

```bash
# Reprovision a single VM from scratch
make tofu-recreate HOSTS=norville
make play LIMIT=norville

# Reprovision an LXC container from scratch
make tofu-proxmox ARGS='apply -target=proxmox_virtual_environment_container.centaurus'
make play LIMIT=centaurus

# Service config drifted but host is fine
make play                  # idempotent — only changed hosts will show tasks

# Force Pi-hole sync from primary to replica
make sync-pihole
```

---

## Controller loss

If the controller machine is also gone:

1. Clone the repo on a new machine
2. Install `direnv`
3. Recreate `.envrc` — the 1Password service account token lives here.
   Without a backup, create a new service account in 1Password and update
   the token. **Back up `.envrc` externally** (password manager, encrypted
   storage — anywhere not the repo).
4. Run `direnv allow`, then proceed from Step 1.
