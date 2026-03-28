locals {
  lxc_memory = {
    centaurus = { bootstrap = 512, runtime = 512 }
    dorothy   = { bootstrap = 512, runtime = 512 }
  }

  lxc_phase = {
    centaurus = contains(var.bootstrapping_vms, "centaurus") ? "bootstrap" : "runtime"
    dorothy   = contains(var.bootstrapping_vms, "dorothy")   ? "bootstrap" : "runtime"
  }
}

# Pi-hole requires privileged container to bind port 53 reliably.
# SSH keys are injected to root; first_run_user=root in host_vars triggers
# the ansible role to create the ansible user on first host-bootstrap run.
resource "proxmox_virtual_environment_container" "centaurus" {
  node_name    = "enterprise"
  on_boot      = true
  started      = true
  unprivileged = false

  initialization {
    hostname = "centaurus"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      keys = [var.sysadmin_public_key, var.ansible_public_key]
    }
  }

  cpu {
    cores = 1
  }

  memory {
    dedicated = local.lxc_memory.centaurus[local.lxc_phase.centaurus]
    swap      = 0
  }

  network_interface {
    name        = "eth0"
    bridge      = "vmbr0"
    mac_address = "42:17:01:FD:F7:A4"
    firewall    = true
  }

  disk {
    datastore_id = "local-lvm"
    size         = 8
  }

  operating_system {
    template_file_id = module.ubuntu_noble_lxc_template.template_file_id
    type             = "ubuntu"
  }
}

resource "proxmox_virtual_environment_container" "dorothy" {
  node_name    = "enterprise"
  on_boot      = true
  started      = true
  unprivileged = true

  initialization {
    hostname = "dorothy"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      keys = [var.sysadmin_public_key, var.ansible_public_key]
    }
  }

  cpu {
    cores = 1
  }

  memory {
    dedicated = local.lxc_memory.dorothy[local.lxc_phase.dorothy]
    swap      = 0
  }

  network_interface {
    name        = "eth0"
    bridge      = "vmbr0"
    mac_address = "42:17:01:FD:72:48"
    firewall    = true
  }

  disk {
    datastore_id = "local-lvm"
    size         = 6
  }

  operating_system {
    template_file_id = module.ubuntu_noble_lxc_template.template_file_id
    type             = "ubuntu"
  }
}
