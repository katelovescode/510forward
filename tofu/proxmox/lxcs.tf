locals {
  lxc_memory = {
    centaurus = { bootstrap = 512, runtime = 512 }
    dorothy   = { bootstrap = 2048, runtime = 512 }
  }

  lxc_phase = {
    centaurus = contains(var.bootstrapping_vms, "centaurus") ? "bootstrap" : "runtime"
    dorothy   = contains(var.bootstrapping_vms, "dorothy")   ? "bootstrap" : "runtime"
  }
}

# nesting=true is required for systemd 255 (Ubuntu 24.04) and enables port 53
# binding for Pi-hole in an unprivileged container.
# SSH keys are injected to root; first_run_user=root in host_vars triggers
# the ansible role to create the ansible user on first host-bootstrap run.
resource "proxmox_virtual_environment_container" "centaurus" {
  node_name    = "enterprise"
  start_on_boot = true
  started      = true
  unprivileged = true

  features {
    nesting = true
  }

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

resource "null_resource" "centaurus_lxc_ssh_setup" {
  depends_on = [proxmox_virtual_environment_container.centaurus]

  triggers = {
    container_id = proxmox_virtual_environment_container.centaurus.id
  }

  connection {
    type        = "ssh"
    host        = "enterprise.510forward.space"
    user        = "opentofu"
    private_key = var.opentofu_ssh_private_key
  }

  provisioner "remote-exec" {
    inline = [
      "sudo pct exec ${proxmox_virtual_environment_container.centaurus.id} -- mkdir -p /root/.ssh",
      "sudo pct exec ${proxmox_virtual_environment_container.centaurus.id} -- chmod 700 /root/.ssh",
      "sudo pct exec ${proxmox_virtual_environment_container.centaurus.id} -- bash -c 'echo \"${var.sysadmin_public_key}\" >> /root/.ssh/authorized_keys'",
      "sudo pct exec ${proxmox_virtual_environment_container.centaurus.id} -- bash -c 'echo \"${var.ansible_public_key}\" >> /root/.ssh/authorized_keys'",
      "sudo pct exec ${proxmox_virtual_environment_container.centaurus.id} -- chmod 600 /root/.ssh/authorized_keys",
      "sudo pct exec ${proxmox_virtual_environment_container.centaurus.id} -- sed -i 's/PermitRootLogin no/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config",
      "sudo pct exec ${proxmox_virtual_environment_container.centaurus.id} -- systemctl restart ssh",
    ]
  }
}

resource "proxmox_virtual_environment_container" "dorothy" {
  node_name    = "enterprise"
  start_on_boot = true
  started      = true
  unprivileged = true

  features {
    nesting = true
  }

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
