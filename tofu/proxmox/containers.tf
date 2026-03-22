resource "proxmox_virtual_environment_download_file" "debian_12_ct_template" {
  content_type        = "vztmpl"
  datastore_id        = "local"
  node_name           = "enterprise"
  url                 = "http://download.proxmox.com/images/system/debian-12-standard_12.7-1_amd64.tar.zst"
  overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_container" "dorothy" {
  node_name = "enterprise"
  on_boot   = true

  initialization {
    hostname = "dorothy"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      keys = [var.ansible_public_key]
    }
  }

  cpu {
    cores = 1
  }

  memory {
    dedicated = 1536
    swap      = 0
  }

  disk {
    datastore_id = "local-lvm"
    size         = 8
  }

  network_interface {
    name        = "eth0"
    bridge      = "vmbr0"
    mac_address = "42:17:01:FD:72:48"
    firewall    = true
  }

  operating_system {
    template_file_id = proxmox_virtual_environment_download_file.debian_12_ct_template.id
    type             = "debian"
  }
}
