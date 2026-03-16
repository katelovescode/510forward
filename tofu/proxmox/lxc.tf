resource "proxmox_virtual_environment_download_file" "debian_12_lxc_template" {
  content_type        = "vztmpl"
  datastore_id        = "local"
  node_name           = "enterprise"
  url                 = "http://download.proxmox.com/images/system/debian-12-standard_12.12-1_amd64.tar.zst"
  file_name           = "debian-12-standard_12.12-1_amd64.tar.zst"
  overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_container" "centaurus" {
  description  = "Pi-hole DNS. Managed by OpenTofu"
  node_name    = "enterprise"
  unprivileged = true
  started      = true

  initialization {
    hostname = "centaurus"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      keys = [var.sysadmin_public_key]
    }
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 4
  }

  network_interface {
    name        = "eth0"
    bridge      = "vmbr0"
    mac_address = "42:17:01:FD:F7:A4"
    firewall    = true
  }

  operating_system {
    template_file_id = proxmox_virtual_environment_download_file.debian_12_lxc_template.id
    type             = "debian"
  }
}