# Adding a New Host

Covers adding a new VM or LXC container to the lab. Follow all steps —
skipping Tofu or Ansible leaves the host half-managed.

---

## Step 1 — Choose VM or LXC

| Use LXC when | Use VM when |
|---|---|
| Single service, no Docker | Runs Docker or Docker Compose |
| No special kernel requirements | Needs its own kernel (e.g. HAOS) |
| Standard Ubuntu workload | Complex multi-process app (e.g. GitLab) |
| Low overhead is a priority | Hardware passthrough required |

When in doubt, use a VM. You can always migrate to LXC later.

---

## Step 2 — Reserve a MAC and assign a static IP in Unifi

1. Pick an unused MAC in the lab's `42:17:01:FD:xx:xx` range. Check existing
   MACs in `tofu/proxmox/vms.tf` and `tofu/proxmox/lxcs.tf` to avoid conflicts.
2. In Unifi, create a fixed-IP DHCP reservation mapping the MAC to the chosen IP
   before provisioning. This way the IP is known upfront and can be hardcoded in
   `host_vars` — no need to look it up after first boot.

---

## Step 3 — Add to OpenTofu

### For a VM — `tofu/proxmox/vms.tf`

Add entries to the `vm_memory` and `vm_phase` locals, then add a
`proxmox_virtual_environment_vm` resource and a
`proxmox_virtual_environment_file` cloud-init resource. Copy the pattern
from an existing VM (e.g. norville).

```hcl
# In locals:
vm_memory = {
  ...
  <hostname> = { bootstrap = <mb>, runtime = <mb>, balloon = <mb> }
}
vm_phase = {
  ...
  <hostname> = contains(var.bootstrapping_vms, "<hostname>") ? "bootstrap" : "runtime"
}

# Resource:
resource "proxmox_virtual_environment_vm" "<hostname>" {
  name      = "<hostname>"
  node_name = "enterprise"
  on_boot   = true
  ...
  memory {
    dedicated = local.vm_memory.<hostname>[local.vm_phase.<hostname>]
    floating  = local.vm_memory.<hostname>.balloon
  }
  network_device {
    mac_address = "<reserved MAC>"
    ...
  }
}
```

Update the `bootstrapping_vms` validation in `variables.tf` to include the
new hostname.

### For an LXC — `tofu/proxmox/lxcs.tf`

Add entries to the `lxc_memory` and `lxc_phase` locals, then add a
`proxmox_virtual_environment_container` resource. Copy the pattern from
dorothy (unprivileged) or centaurus (privileged — needed for port 53 binding
or other low-port/capability requirements).

```hcl
# In locals:
lxc_memory = {
  ...
  <hostname> = { bootstrap = <mb>, runtime = <mb> }
}
lxc_phase = {
  ...
  <hostname> = contains(var.bootstrapping_vms, "<hostname>") ? "bootstrap" : "runtime"
}
```

Update the `bootstrapping_vms` validation in `variables.tf` to include the
new hostname.

---

## Step 4 — Add to Ansible inventory

### `ansible/inventory/hosts.yml`

Add the host to the appropriate groups:

```yaml
qemu_vms:        # if VM
  hosts:
    <hostname>:

lxc_containers:  # if LXC — gets first_run_user: root automatically
  hosts:
    <hostname>:

apt_managed:     # if Ubuntu (almost always yes)
  hosts:
    <hostname>:
```

### `ansible/inventory/host_vars/<hostname>/vars.yml`

The `ip_address` here is used by Pi-hole to generate local DNS records, so it
needs to be known before the first playbook run. The two ways to get it:

- **Recommended (DNS/NPM access needed):** complete Step 2 first — Unifi
  fixed-IP reservation means the IP is assigned before the device boots and
  can be hardcoded here immediately.
- **Alternative (no DNS/NPM needed):** skip Step 2, let DHCP assign an IP on
  first boot, then fill it in. Only appropriate for hosts that won't have an
  FQDN and won't be proxied through NPM.

```yaml
---
ansible_host: <ip>
ip_address: <ip>
fqdn: <hostname>.510forward.space
mac_address: "<reserved MAC>"
npm_proxied: true       # if accessible via NPM
```

---

## Step 5 — Add app role to `ansible/playbook.yml`

If the host runs a specific service, add a play:

```yaml
- name: <Service name>
  hosts: <hostname>
  roles:
    - <role>
```

If no role exists yet, create one under `ansible/roles/` before this step.
All roles need `meta/argument_specs.yml` — the pre-commit hook enforces this.

---

## Step 6 — Add NPM proxy host (if web-accessible)

If the service has a web UI, add a proxy host entry in
`ansible/inventory/host_vars/norville/vars.yml` under
`nginx_proxy_manager_proxy_hosts`:

```yaml
- subdomain: <hostname>
  host: "{{ hostvars['<hostname>'].ip_address }}"
  port: <port>
  scheme: http   # or https if the backend has TLS
```

---

## Step 7 — Provision and bootstrap

```bash
# Provision the new host
make tofu-proxmox ARGS='apply'
```

**If you used the DHCP alternative in Step 2:** the host will boot and receive
an IP from DHCP. Check the Unifi client list for the new MAC address, then
update `ansible_host` and `ip_address` in `host_vars/<hostname>/vars.yml`
before continuing.

```bash
# Bootstrap it (elevates RAM, runs Ansible, restores RAM)
make host-bootstrap HOST=<hostname>
```

---

## Step 8 — Verify

```bash
make play     # full idempotent run to catch anything missed
make verify   # acceptance tests
```

---

## Notes

- **hermes (GitLab Runner)** is on hold pending executor decision (shell vs
  Docker). See `tofu/proxmox/vms.tf` for the commented-out resource. When
  ready to provision, uncomment it, add memory/phase entries to locals,
  restore the `bootstrapping_vms` validation entry, update the inventory,
  and follow this runbook from Step 5.
