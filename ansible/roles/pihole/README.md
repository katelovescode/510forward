# pihole role

Installs and configures Pi-hole v6 in a primary/replica setup. centaurus is the primary; andromeda is the replica. nebula-sync replicates config from primary to replica. Also manages DNS resolver config on both Pi-hole nodes to avoid circular dependencies.

## What it does

- Installs Pi-hole v6 from the official installer
- Configures Pi-hole via `pihole-FTL --config` (never by templating `pihole.toml` directly)
- Sets the admin password from 1Password
- Manages custom local DNS via dnsmasq in `/etc/dnsmasq.d/99-ansible-local-dns.conf`
- Installs nebula-sync on the primary as a systemd timer for replication to replicas
- Configures systemd-resolved on both Pi-hole nodes to use public DNS (not themselves)

## Pi-hole v6 config management

Pi-hole v6 stores config in `pihole.toml`. FTL owns this file and rewrites it with comments and defaults on every start. **Do not template the full file** — any changes will be overwritten and the role will always show as changed.

The correct pattern: read the current value with `pihole-FTL --config <key>`, compare it to the desired value, and only call `pihole-FTL --config <key> <value>` if they differ. Note that `pihole-FTL --config` always exits 0 and always prints the value — you must read and compare explicitly.

Array values are read back as `[ val1, val2 ]` (no quotes). Set them using the `argv:` form in Ansible to avoid shell word-splitting.

Custom DNS entries go in `/etc/dnsmasq.d/` (not `custom.list`, which Pi-hole v6 no longer reads directly). `misc.etc_dnsmasq_d = true` must be set in `pihole.toml`. Use `systemctl restart pihole-FTL` to apply config changes — `pihole restartdns` does not reload `dnsmasq.d` or `pihole.toml`.

## Why Pi-hole nodes use public DNS for themselves

Pi-hole nodes cannot use themselves as DNS resolvers — if Pi-hole is down, the node loses DNS and can't restart the service. centaurus and andromeda use `1.1.1.1` and `1.0.0.1` as upstreams directly.

The resolver is managed via a systemd-resolved drop-in at `/etc/systemd/resolved.conf.d/ansible-dns.conf` with `DNSStubListener=no`. This also resolves the ARM64 FTL bug (see below). The drop-in is interface-agnostic, which matters for andromeda which is on WiFi with a fragile NM connection name.

## ARM64 FTL port 53 conflict (andromeda)

On andromeda (Raspberry Pi 5, ARM64), pihole-FTL v6 has a bug where the outer FTL process binds port 53 successfully, then the embedded dnsmasq tries to bind the same port in a second phase and fails with "Address in use". FTL appears active (`systemctl is-active` shows active, `ss` shows port 53 bound) but doesn't process queries.

**Root cause and fix:** systemd-resolved's stub listener at `127.0.0.53:53` conflicts with FTL binding `0.0.0.0:53`. Setting `DNSStubListener=no` in the resolved drop-in frees port 53 exclusively for FTL. The `/etc/resolv.conf` symlink is also updated to `/run/systemd/resolve/resolv.conf` (the non-stub version) so the upstream DNS servers are used rather than the now-disabled stub.

Note: systemd-resolved is not installed by default on Raspbian trixie. The pihole role installs it on hosts that need it.

## nebula-sync

nebula-sync runs on the primary only (`when: pihole_primary | default(false)`). It replicates to all other `pihole_nodes` group members. It runs as a systemd timer (not cron) for journald logging and clean manual triggering via `systemctl start nebula-sync`.

`RUN_GRAVITY=false` by default — running gravity on replicas causes FTL webserver instability. Run `make sync-pihole` to trigger a manual sync.

## listeningMode must be ALL

Pi-hole must be set to `listeningMode = ALL` (not `LOCAL`) to answer DNS queries from other VLANs. `LOCAL` only responds to the local subnet.

## adlists

StevenBlack unified hosts and Hagezi Multi PRO are managed via sqlite3 directly on the primary. nebula-sync replicates the database to replicas.
