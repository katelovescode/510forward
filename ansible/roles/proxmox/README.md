# proxmox role

Configures the Proxmox VE host (enterprise): apt repositories, ACME/TLS cert, DNS resolver, and QEMU guest agent channels on VMs.

## Task structure

Tasks are split by the host they target:

- **`tasks/nodes/`** — runs on `proxmox_nodes` (enterprise): repos, ACME/TLS, storage, DNS resolvers, QEMU guest agent channel management via pvesh
- **`tasks/vms/`** — runs on `qemu_vms`: installs `qemu-guest-agent` package, checks the virtio-serial channel, manages the service state

`tasks/main.yml` imports `nodes/main.yml` and is what `roles: - proxmox` calls. The `vms/` tasks are called from a separate play in `playbook.yml` targeting `qemu_vms`.

// TODO maybe we can do the vm_guest_agent.yml tasks in the vms subfolder, it still makes more sense to me there. If we call it from main.yml in the vms subfolder, we can delegate_to: enterprise maybe

## What it does

**On enterprise (`nodes/`):**

- Configures the no-subscription apt repo (suite: `trixie`) and disables the enterprise repo
- Issues and renews the Let's Encrypt wildcard cert via Proxmox ACME with Cloudflare DNS-01
- Templates `/etc/resolv.conf` with Pi-hole nodes as primary/secondary DNS and `1.1.1.1` as fallback
- Enables the QEMU guest agent virtio-serial channel on VMs via pvesh
- Reboots VMs where the channel was just enabled so the agent can communicate

**On each VM (`vms/`):**

- Installs `qemu-guest-agent`
- Checks whether the virtio-serial channel is present at `/dev/virtio-ports/org.qemu.guest_agent.0`
- Starts the service if the channel is present, stops it if not

## ACME/TLS cert

The cert is issued for `enterprise.510forward.space` via Proxmox's built-in ACME client. Proxmox handles automatic renewal. A few pvesh gotchas:

- `pvesh create /cluster/acme/account` takes email without `mailto:` prefix
- DNS plugin API parameter is `--api`, not `--plugin`; plugin data is base64-encoded
- Node domain config: `pvesh set /nodes/{node}/config -acmedomain0 "domain=...,plugin=..."`; wildcards are rejected by pvesh validation — use specific hostname
- Certificate order endpoint: `/nodes/{node}/certificates/acme/certificate`
- `pvesh create .../acme/cert` is fire-and-forget (returns a task ID) — check the Proxmox task log for the result

## DNS resolver

`/etc/resolv.conf` on enterprise is templated by `tasks/dns.yml`. The resolver order is derived dynamically: Pi-hole node IPs from `groups['pihole_nodes']` (centaurus first, andromeda second — order in `hosts.yml` is intentional) plus `public_dns_servers[0]` as fallback.

## Why community.proxmox modules must delegate_to enterprise

// TODO: why is this true? Can't we just call those tasks on the enterprise host and leave it at that?

`community.proxmox` modules (`proxmox_group`, `proxmox_user`, `proxmox_access_acl`) connect to the Proxmox API. The controller cannot resolve bare `enterprise` (the hostname in `proxmox_api_node`), and `enterprise.510forward.space` is `npm_proxied` — it resolves to norville, where nothing listens on port 8006. On enterprise itself, the hostname resolves locally and `proxmoxer` is installed. All community.proxmox calls must `delegate_to: enterprise`.

## QEMU guest agent channel management

The guest agent virtio-serial channel is enabled via `pvesh set /nodes/enterprise/qemu/<vmid>/config --agent enabled=1`. This is done outside OpenTofu because the bpg/proxmox provider's `agent {}` block causes `tofu apply` to hang indefinitely on PVE 9 — the provider waits for the agent to respond, but the agent can't respond until the channel is enabled.

After enabling the channel, affected VMs are rebooted. The `ansible` role then runs and starts the guest agent service once the virtio device is present. This sequencing is why the proxmox play runs **before** the base configuration play in `playbook.yml`.

## validate_certs

`ansible.cfg` sets `validate_certs: true` globally for all community.proxmox modules. The default is `false` (most installs use self-signed certs). Bootstrap plays that call community.proxmox modules override to `false` at the play level because the ACME cert hasn't been issued yet at that point.
