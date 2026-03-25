# verify/

Acceptance tests for live infrastructure, organized by concern. Run via `make verify` after `make play`.

Each file is a self-contained playbook imported by `../verify.yml`:

| File                 | What it checks                                                                                                        |
| -------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `dns.yml`            | Pi-hole FTL running on both nodes; all internal hostnames resolve correctly from enterprise, centaurus, and andromeda |
| `qemu.yml`           | `qemu-guest-agent` running on all QEMU VMs                                                                            |
| `npm.yml`            | NPM backends reachable from norville; all proxied subdomains reachable end-to-end via HTTPS                           |
| `tls.yml`            | Proxmox Let's Encrypt cert valid; NPM wildcard cert valid; HTTP redirects to HTTPS                                    |
| `home_assistant.yml` | HA API responding; Proxmox API token authenticates                                                                    |
| `gitlab.yml`         | GitLab reachable end-to-end via NPM                                                                                   |

## Manual acceptance tests

The following require manual intervention (destructive or stateful):

- **Pi-hole nodes use public DNS (no circular dependency)**

  ```bash
  # On centaurus AND andromeda — should show 1.1.1.1, NOT 192.168.30.x
  resolvectl status | grep "DNS Servers"
  ```

- **Andromeda takes over when centaurus is down**

  ```bash
  sudo systemctl stop pihole-FTL   # on centaurus
  dig google.com @192.168.30.55    # should still resolve via andromeda
  sudo systemctl start pihole-FTL  # restore
  ```

- **All hosts survive both Pi-holes being down (fallback DNS)**

  ```bash
  # Stop pihole-FTL on both, then verify each host falls back to 1.1.1.1
  dig google.com   # on enterprise — resolv.conf fallback
  dig google.com   # on centaurus/andromeda — systemd-resolved drop-in
  ```

- **Pi-hole clustering in sync**
  ```bash
  make sync-pihole
  # Compare blocklist counts in both Pi-hole UIs
  ```
