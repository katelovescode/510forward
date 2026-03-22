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
    dedicated = 2048
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
      keys     = [var.ansible_public_key]
    }
    
    user_data_file_id = proxmox_virtual_environment_file.cloud_init_config.id
  }

  network_device {
    bridge      = "vmbr0"
    model       = "virtio"
    mac_address = "42:17:01:FD:F7:A4"
    firewall    = true
  }
}

resource "proxmox_virtual_environment_file" "cloud_init_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "enterprise"
  source_raw {
    data = templatefile("${path.module}/templates/ubuntu-noble-vm/cloud-init.yml.tftpl", {
      hostname            = "centaurus"
      sysadmin_public_key = var.sysadmin_public_key
      ansible_public_key  = var.ansible_public_key
    })
    file_name = "cloud-init-config.yml"
  }
}

resource "proxmox_virtual_environment_vm" "norville" {
  name      = "norville"
  node_name = "enterprise"
  on_boot   = true

  clone {
    vm_id = module.ubuntu_noble_vm_template.vm_id
    full  = true
  }

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 3072
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
      keys     = [var.ansible_public_key]
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_init_config_norville.id
  }

  network_device {
    bridge      = "vmbr0"
    model       = "virtio"
    mac_address = "42:17:01:FD:72:77"
    firewall    = true
  }
}

resource "proxmox_virtual_environment_file" "cloud_init_config_norville" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "enterprise"
  source_raw {
    data = templatefile("${path.module}/templates/ubuntu-noble-vm/cloud-init.yml.tftpl", {
      hostname            = "norville"
      sysadmin_public_key = var.sysadmin_public_key
      ansible_public_key  = var.ansible_public_key
    })
    file_name = "cloud-init-config-norville.yml"
  }
}

resource "proxmox_virtual_environment_vm" "dorothy" {
  name      = "dorothy"
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
    dedicated = 1536
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 8
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
      keys     = [var.ansible_public_key]
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_init_config_dorothy.id
  }

  network_device {
    bridge      = "vmbr0"
    model       = "virtio"
    mac_address = "42:17:01:FD:72:48"
    firewall    = true
  }
}

resource "proxmox_virtual_environment_file" "cloud_init_config_dorothy" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "enterprise"
  source_raw {
    data = templatefile("${path.module}/templates/ubuntu-noble-vm/cloud-init.yml.tftpl", {
      hostname            = "dorothy"
      sysadmin_public_key = var.sysadmin_public_key
      ansible_public_key  = var.ansible_public_key
    })
    file_name = "cloud-init-config-dorothy.yml"
  }
}