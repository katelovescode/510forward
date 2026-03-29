# nesting=true is required for systemd 255 (Ubuntu 24.04) and enables port 53
# binding for Pi-hole in an unprivileged container.
# SSH keys are injected to root; the remote-exec provisioner bootstraps the
# ansible user so Ansible can connect
resource "proxmox_virtual_environment_container" "centaurus" {
  node_name     = "enterprise"
  start_on_boot = true
  started       = true
  unprivileged  = true

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
    dedicated = 512
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

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "root"
      host        = "192.168.30.77"
      private_key = var.ansible_private_key
    }

    inline = [
      "apt-get install -y -qq sudo",
      # ansible user
      "useradd -m -s /bin/bash ansible",
      "mkdir -p /home/ansible/.ssh",
      "chmod 700 /home/ansible/.ssh",
      "echo '${var.ansible_public_key}' > /home/ansible/.ssh/authorized_keys",
      "chmod 600 /home/ansible/.ssh/authorized_keys",
      "chown -R ansible:ansible /home/ansible/.ssh",
      "mkdir -p /etc/sudoers.d",
      "printf 'Defaults !fqdn\\nansible ALL=(ALL:ALL) NOPASSWD: ALL\\n' > /etc/sudoers.d/ansible",
      "chmod 440 /etc/sudoers.d/ansible",
      # kate user
      "useradd -m -s /bin/bash -G sudo kate",
      "mkdir -p /home/kate/.ssh",
      "chmod 700 /home/kate/.ssh",
      "echo '${var.sysadmin_public_key}' > /home/kate/.ssh/authorized_keys",
      "chmod 600 /home/kate/.ssh/authorized_keys",
      "chown -R kate:kate /home/kate/.ssh",
    ]
  }
}