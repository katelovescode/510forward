resource "proxmox_virtual_environment_vm" "centaurus" {
  name      = "centaurus"
  node_name = "enterprise"
  on_boot   = true

  clone {
    vm_id = module.ubuntu_noble_vm_template.vm_id
    full  = true
  }

  cpu {
    cores = 1
    type  = "host"
  }

  memory {
    dedicated = 1024
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 10
    discard      = "on"
    ssd          = true
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      username = "ansible"
      keys     = [var.sysadmin_public_key]
    }
  }

  network_device {
    bridge      = "vmbr0"
    model       = "virtio"
    mac_address = "42:17:01:FD:F7:A4"
    firewall    = true
  }
}