# Forgejo Migration Design

**Date:** 2026-03-28
**Replaces:** GitLab CE on memory-alpha

## Goal

Replace GitLab CE with Forgejo on memory-alpha. GitLab's memory footprint (4GB+ at default settings) causes OOM kills at the current runtime allocation. Forgejo provides equivalent functionality for this homelab — code hosting, issues, PRs, and CI/CD via Forgejo Actions — at ~200-400MB idle.

Everything currently in GitLab can be discarded; all repos are current on the local device.

---

## Architecture

Forgejo runs as a systemd service (binary install, not Docker) on memory-alpha. The Forgejo Actions runner runs on the same VM as a second systemd service. NPM on norville handles TLS termination exactly as it does today — no proxy config changes needed.

```
Mac → norville (NPM, TLS) → memory-alpha:80 (Forgejo HTTP)
Mac → memory-alpha:22 (Forgejo SSH, git remotes)
```

### Database

SQLite at `/var/lib/forgejo/data/forgejo.db`. Appropriate for a single-user homelab. No separate database process. Web admin UI is built into Forgejo; direct DB access via TablePlus or DB Browser for SQLite if needed.

### Forgejo Actions Runner

Runs on memory-alpha alongside Forgejo. Idle resource usage is negligible. Can be split to a separate VM later if build load impacts Forgejo responsiveness.

---

## memory-alpha VM Sizing

Update `tofu/proxmox/vms.tf`:

| Setting | Current | New |
|---------|---------|-----|
| runtime memory | 4096 MB | 2048 MB |
| bootstrap memory | 8192 MB | 8192 MB (unchanged) |
| balloon | 1024 MB | 1024 MB (unchanged) |

---

## Ansible Role: `forgejo`

Replaces the `gitlab` role entirely. The gitlab role is deleted.

### Tasks

1. **Install dependencies** — `git`, `curl`, `ca-certificates`
2. **Create system user** — `forgejo` user, no login shell, home at `/var/lib/forgejo`
3. **Download Forgejo binary** — pinned version from `codeberg.org/forgejo/forgejo/releases`, verified via SHA256 checksum, installed to `/usr/local/bin/forgejo`
4. **Create directory structure** — `/var/lib/forgejo/{data,log,repos}`, `/etc/forgejo`, owned by `forgejo` user
5. **Template `app.ini`** — see configuration section below
6. **Install systemd service** — `forgejo.service`, enabled and started
7. **Set admin password** — upsert "Forgejo Admin Password" in 1Password; on fresh install, run `forgejo admin user create` to create the admin user
8. **Download runner binary** — pinned version, installed to `/usr/local/bin/forgejo-runner`
9. **Register runner** — fetch registration token via Forgejo API, store in 1Password as "Forgejo Runner Token", register runner
10. **Install runner systemd service** — `forgejo-runner.service`, enabled and started

### `app.ini` Configuration

```ini
[server]
DOMAIN           = memory-alpha.{{ domain }}
ROOT_URL         = https://memory-alpha.{{ domain }}/
HTTP_PORT        = 3000
SSH_DOMAIN       = memory-alpha.{{ domain }}
SSH_PORT         = 22
START_SSH_SERVER = false   ; use system SSH, not Forgejo's built-in

[database]
DB_TYPE = sqlite3
PATH    = /var/lib/forgejo/data/forgejo.db

[security]
INSTALL_LOCK = true

[service]
DISABLE_REGISTRATION = true   ; single-user homelab

[proxy]
PROXY_ENABLED = false
```

NPM trusted proxy is handled at the reverse proxy level (norville already sends `X-Forwarded-*` headers).

### Handlers

- `restart forgejo` — `systemctl restart forgejo`
- `restart forgejo-runner` — `systemctl restart forgejo-runner`

### `argument_specs.yml`

| Variable | Source | Description |
|----------|--------|-------------|
| `forgejo_version` | `host_vars/memory-alpha/vars.yml` | Pinned Forgejo release tag, e.g. `"v10.0.3"` |
| `forgejo_runner_version` | `host_vars/memory-alpha/vars.yml` | Pinned runner release tag, e.g. `"v6.3.1"` |
| `fqdn` | `host_vars/memory-alpha/vars.yml` | FQDN for this host |
| `domain` | `group_vars/all/vars.yml` | Base domain |
| `onepassword_vault` | `group_vars/all/vars.yml` | 1Password vault |
| `onepassword_become_user` | `group_vars/all/vars.yml` | Local op CLI user |

---

## Host Vars Changes (`host_vars/memory-alpha/vars.yml`)

Remove:
```yaml
gitlab_version: "18.10.1"
```

Add:
```yaml
forgejo_version: "v10.0.3"         # pin to latest stable at implementation time
forgejo_runner_version: "v6.3.1"   # pin to latest stable at implementation time
```

---

## Playbook Changes

`ansible/playbook.yml` — replace `gitlab` role with `forgejo` in the memory-alpha play.

---

## What Gets Deleted

- `ansible/roles/gitlab/` — entire role removed
- `ansible/verify/gitlab.yml` — replaced with `verify/forgejo.yml`

---

## Verify Play (`verify/forgejo.yml`)

- HTTP health check: `GET https://memory-alpha.{{ domain }}/api/healthz` returns 200
- SSH connectivity: `ssh -p 22 git@memory-alpha.{{ domain }}` returns Forgejo banner
- Runner registered: Forgejo API returns at least one active runner

---

## Execution Order

1. Fix memory_alpha OOM (reboot via Proxmox UI to clear OOM state)
2. Apply vms.tf memory change via targeted apply: `tofu apply -auto-approve -target=proxmox_virtual_environment_vm.memory_alpha`
3. Run `make host-bootstrap HOST=memory-alpha` — installs Forgejo, configures runner
4. Push local repos to Forgejo via SSH remotes

> **Note:** Steps 1-3 are blocked until the memory_alpha QEMU agent issue is resolved (separate concern — the agent timeout in the full tofu plan). Use targeted apply to work around it.
