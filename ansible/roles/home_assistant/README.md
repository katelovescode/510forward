# home_assistant role

Manages Home Assistant OS (HAOS) configuration on codsworth, creates the `homeassistant@pve` Proxmox user with appropriate permissions, and stores its API token in 1Password.

## What it does

- Creates four Proxmox roles and assigns them to a `homeassistant` group (see below)
- Creates `homeassistant@pve` in that group
- Creates an API token and stores it in 1Password ("Proxmox Home Assistant API Token")
- Templates `/config/configuration.yaml` with `trusted_proxies` set to norville's IP
- Restarts HA core via the REST API when configuration changes

## SSH constraints on HAOS

HAOS runs an SSH add-on, not a standard sshd. Three things fall out of this:

- **User**: `ansible_user: hassio` (uid=1000, passwordless sudo via `wheel` group). There is no `ansible` user on HAOS — HAOS is a purpose-built appliance OS with a mostly read-only filesystem and no traditional user management. The SSH add-on only exposes `hassio`; creating additional OS users isn't possible.
- **File transfer**: The SSH add-on has no `sftp-server` or `scp`. `ansible_ssh_transfer_method: piped` avoids failed attempts and suppresses warnings.
- **become**: `ansible_become: true` required for all tasks that touch `/config/`.

## Why `ha core restart` uses the REST API

`ha core restart` is a CLI command that requires the `SUPERVISOR_TOKEN` environment variable, which is only injected into interactive HAOS shell sessions — not Ansible SSH connections. The only reliable way to restart HA from Ansible is via the REST API:

```
POST /api/services/homeassistant/restart
Authorization: Bearer <long-lived-token>
```

// TODO: change this - we should be doing upsert on 1Password with this, and should find a way to create the token automatically

The long-lived token is created once manually in HA (Profile → Security → Long-lived access tokens) and stored in 1Password as "Home Assistant Ansible API Token" (field: `credential`). The role fetches it via the `onepassword` role before it could be needed by the handler.

## Proxmox permissions — why four separate roles

The proxmoxve integration's [recommended permission model](https://github.com/dougiteixeira/proxmoxve#suggestion-for-creating-permission-roles-for-use-with-integration) uses purpose-specific roles rather than one catch-all role. This makes it easy to grant or revoke individual capabilities:

| Role                          | Privileges                                 | Purpose                        |
| ----------------------------- | ------------------------------------------ | ------------------------------ |
| `HomeAssistant.Audit`         | `VM.Audit`, `Sys.Audit`, `Datastore.Audit` | Read VM/node/storage state     |
| `HomeAssistant.NodePowerMgmt` | `Sys.PowerMgmt`                            | Node shutdown/restart          |
| `HomeAssistant.Update`        | `Sys.Modify`                               | Read available package updates |
| `HomeAssistant.VMPowerMgmt`   | `VM.PowerMgmt`                             | Start/stop/restart VMs         |

All four are assigned to the `homeassistant` group at path `/` with propagation.

// TODO: when we start adding automated installation of these things, we should move the documentation there and out of the general README

## Why the proxmoxve integration uses IP, not hostname

`enterprise.510forward.space` is `npm_proxied` — Pi-hole returns norville's IP for it. Nothing listens on port 8006 at norville; NPM only proxies port 443. The integration must connect directly to `192.168.30.170:8006`.

SSL verification must be disabled when connecting by IP — the Let's Encrypt cert is issued for the hostname, not the IP address. This is the same constraint as OpenTofu.

## trusted_proxies

HA requires that the reverse proxy's IP is listed in `http.trusted_proxies` in `configuration.yaml`, otherwise it ignores `X-Forwarded-For` headers and logs all requests as coming from norville's IP. The role templates this value from `hostvars['norville']['ip_address']`.
