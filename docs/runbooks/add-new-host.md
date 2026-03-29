# Adding a New Host

Covers adding a new VM or LXC container to the lab. Follow all steps —
skipping Tofu or Ansible leaves the host half-managed.

---

## Step 1 — Choose VM or LXC

| Use LXC when                   | Use VM when                             |
| ------------------------------ | --------------------------------------- |
| Single service, no Docker      | Runs Docker or Docker Compose           |
| No special kernel requirements | Needs its own kernel (e.g. HAOS)        |
| Standard Ubuntu workload       | Complex multi-process app (e.g. GitLab) |
| Low overhead is a priority     | Hardware passthrough required           |

When in doubt, use a VM. You can always migrate to LXC later.

---

## Step 2 — IP Addressing

You have two choices for this; you can let DHCP assign and add the IP address after it's assigned,
or you can set up a fixed IP address manually in Unifi before ever spinning up the host.

If you want to set it manually:

1. Pick an unused MAC in the lab's `42:17:01:FD:xx:xx` range. Check existing
   MACs in `tofu/proxmox/vms.tf` and `tofu/proxmox/lxcs.tf` to avoid conflicts.
2. In Unifi, create a fixed-IP DHCP reservation mapping the MAC to the chosen IP
   before provisioning. Hardcode the IP, and the fqdn if the host will have
   one, in in the host's `host_vars`.

Otherwise, let DHCP do its thing, check Unifi for the IP the host received
and then hardcode it in the `host_vars` along with the fqdn if the host will have one.

Either way, in order for ansible to access the host for `ansible-playbook playbook.yml`,
the IP address has to be hardcoded in the `host_vars` in the `ansible_host` and `ip_address`
vars before you run ansible, and you'll need the MAC address in tofu if you want to use
a fixed IP, so decide at this point before going further.

---

## Step 3 — Add to OpenTofu

### For a VM — `tofu/proxmox/vms.tf`

Add a `proxmox_virtual_environment_vm` resource and a
`proxmox_virtual_environment_file` cloud-init resource. Copy the pattern
from an existing VM (e.g. norville) or use the below example:

```hcl
resource "proxmox_virtual_environment_vm" "<hostname>" {
  name      = "<hostname>"
  node_name = "enterprise"
  on_boot   = true

  cpu {
    cores = <n>
    type  = "host"
  }

  memory {
    dedicated = <mb>
    floating  = <balloon_mb>
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = <gb>
    discard      = "on"
    ssd          = true
  }

  initialization {
    ip_config {
      ipv4 { address = "dhcp" }
    }
    user_account {
      username = "ansible"
      keys     = [var.ansible_public_key]
    }
    user_data_file_id = proxmox_virtual_environment_file.cloud_init_config_<hostname>.id
  }

  network_device {
    bridge      = "vmbr0"
    model       = "virtio"
    mac_address = "<reserved MAC if you need a fixed IP>"
    firewall    = true
  }
}
```

### For an LXC — `tofu/proxmox/lxcs.tf`

Add a `proxmox_virtual_environment_container` resource. Copy the pattern
from centaurus or use the below example:

```hcl
resource "proxmox_virtual_environment_container" "<hostname>" {
  node_name     = "enterprise"
  start_on_boot = true
  started       = true
  unprivileged  = true

  features { nesting = true }

  initialization {
    hostname = "<hostname>"
    ip_config { ipv4 { address = "dhcp" } }
    user_account {
      keys = [var.sysadmin_public_key, var.ansible_public_key]
    }
  }

  cpu    { cores = 1 }
  memory { dedicated = <mb>; swap = 0 }

  network_interface {
    name        = "eth0"
    bridge      = "vmbr0"
    mac_address = "<reserved MAC if you need a fixed IP>"
    firewall    = true
  }

  disk {
    datastore_id = "local-lvm"
    size         = <gb>
  }

  operating_system {
    template_file_id = module.ubuntu_noble_lxc_template.template_file_id
    type             = "ubuntu"
  }
}
```

---

## Step 4 — Add to Ansible inventory

### `ansible/inventory/hosts.yml`

Add the host to the appropriate groups:

```yaml
qemu_vms: # if VM
  hosts:
    <hostname>:

lxc_containers: # if LXC — gets first_run_user: root automatically
  hosts:
    <hostname>:
```

### `ansible/inventory/host_vars/<hostname>/vars.yml`

The `ip_address` here is used by Pi-hole to generate local DNS records, so it
needs to be known before the first playbook run. This is where your Step 2
decision comes into play:

```yaml
---
ansible_host: <ip>
ip_address: <ip>
fqdn: <hostname>.510forward.space
mac_address: "<reserved MAC>"
npm_proxied: true
```

**Alternative — DHCP first (no FQDN needed):**

```yaml
---
ansible_host: <fill in after first boot>
ip_address: <fill in after first boot>
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
  scheme: http # or https if the backend has TLS
```

---

## Step 7 — Provision and bootstrap

```bash
# Provision the new host
make tofu-proxmox ARGS='apply'
```

**If you used the DHCP path:** the host will boot and receive an IP
from DHCP. Before running bootstrap, check the Unifi client list for the new
MAC address and update `ansible_host` and `ip_address` in
`host_vars/<hostname>/vars.yml`. Bootstrap will fail without a reachable IP.

```bash
# Full run to pick up any cross-host effects (DNS records, NPM proxy hosts)
cd ansible && ansible-playbook playbook.yml
```

---

## Step 8 — Verify

```bash
cd ansible && ansible-playbook verify.yml # acceptance tests
```
