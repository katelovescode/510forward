# verify/

Acceptance tests for live infrastructure, organized by concern. Run via `make verify` after `make play`.

Each file is a self-contained playbook imported by `../verify.yml`:

| File | What it checks |
|------|----------------|
| `dns.yml` | Pi-hole FTL running on both nodes; all internal hostnames resolve correctly from enterprise, centaurus, and andromeda |
| `qemu.yml` | `qemu-guest-agent` running on all QEMU VMs |
| `npm.yml` | NPM backends reachable from norville; all proxied subdomains reachable end-to-end via HTTPS |
| `tls.yml` | Proxmox Let's Encrypt cert valid; NPM wildcard cert valid; HTTP redirects to HTTPS |
| `home_assistant.yml` | HA API responding; Proxmox API token authenticates |
| `gitlab.yml` | GitLab reachable end-to-end via NPM |

## What's not covered

Destructive and stateful tests are omitted — run these manually per the checklist in `.windsurf/plans/homelab-ansible-plan.md`:

- Pi-hole nodes use public DNS directly (not circular through themselves)
- Andromeda takes over DNS when centaurus is down
- All hosts fall back to `1.1.1.1` when both Pi-holes are down
- Pi-hole clusters are in sync (`make sync-pihole`)
