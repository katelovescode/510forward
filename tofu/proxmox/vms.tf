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

resource "proxmox_virtual_environment_download_file" "haos_image" {
  content_type        = "iso"
  datastore_id        = "local"
  node_name           = "enterprise"
  url                 = "https://github.com/home-assistant/operating-system/releases/download/${var.haos_version}/haos_ova-${var.haos_version}.qcow2.xz"
  file_name           = "haos_ova-${var.haos_version}.qcow2.img"
  overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_vm" "codsworth" {
  name      = "codsworth"
  node_name = "enterprise"
  on_boot   = true
  started   = false
  bios      = "ovmf"
  machine   = "q35"

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048
  }

  efi_disk {
    datastore_id = "local-lvm"
    type         = "4m"
  }

  network_device {
    bridge      = "vmbr0"
    model       = "virtio"
    mac_address = "42:17:01:FD:C0:D5"
    firewall    = true
  }

  description = "Home Assistant OS VM. Managed by OpenTofu"

  # Disk and boot order are managed by null_resource.codsworth_disk below.
  # HAOS qcow2.xz requires decompression before import, which the Proxmox
  # download API does not do — so disk setup is handled via remote-exec.
  lifecycle {
    ignore_changes = [disk, boot_order, started]
  }
}

resource "null_resource" "codsworth_disk" {
  triggers = {
    vm_id        = proxmox_virtual_environment_vm.codsworth.id
    haos_version = var.haos_version
  }

  connection {
    type        = "ssh"
    host        = "192.168.30.170"
    user        = "opentofu"
    private_key = var.opentofu_ssh_private_key
  }

  provisioner "remote-exec" {
    inline = [
      # Decompress xz to qcow2 if not already done
      "test -f /var/lib/vz/template/iso/haos_ova-${var.haos_version}.qcow2 || sudo sh -c 'xz -dc /var/lib/vz/template/iso/haos_ova-${var.haos_version}.qcow2.xz > /var/lib/vz/template/iso/haos_ova-${var.haos_version}.qcow2'",
      # Import disk if scsi0 not already configured
      "sudo qm config ${proxmox_virtual_environment_vm.codsworth.id} | grep -q '^scsi0:' || sudo qm importdisk ${proxmox_virtual_environment_vm.codsworth.id} /var/lib/vz/template/iso/haos_ova-${var.haos_version}.qcow2 local-lvm",
      # Attach imported disk and set boot order if scsi0 still not set
      "sudo qm config ${proxmox_virtual_environment_vm.codsworth.id} | grep -q '^scsi0:' || sudo qm set ${proxmox_virtual_environment_vm.codsworth.id} --scsi0 local-lvm:vm-${proxmox_virtual_environment_vm.codsworth.id}-disk-1,aio=io_uring,cache=none,discard=on,ssd=1 --boot order=scsi0",
      # Start VM if not already running
      "sudo qm status ${proxmox_virtual_environment_vm.codsworth.id} | grep -q running || sudo qm start ${proxmox_virtual_environment_vm.codsworth.id}",
    ]
  }

  depends_on = [
    proxmox_virtual_environment_vm.codsworth,
    proxmox_virtual_environment_download_file.haos_image,
  ]
}

resource "proxmox_virtual_environment_vm" "memory_alpha" {
  name      = "memory-alpha"
  node_name = "enterprise"
  on_boot   = true

  clone {
    vm_id = module.ubuntu_noble_vm_template.vm_id
    full  = true
  }

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 8192
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 50
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

    user_data_file_id = proxmox_virtual_environment_file.cloud_init_config_memory_alpha.id
  }

  network_device {
    bridge      = "vmbr0"
    model       = "virtio"
    mac_address = "42:17:01:FD:A1:FA"
    firewall    = true
  }
}

resource "proxmox_virtual_environment_vm" "hermes" {
  name      = "hermes"
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
    dedicated = 4096
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 20
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

    user_data_file_id = proxmox_virtual_environment_file.cloud_init_config_hermes.id
  }

  network_device {
    bridge      = "vmbr0"
    model       = "virtio"
    mac_address = "42:17:01:FD:E4:3D"
    firewall    = true
  }
}

resource "proxmox_virtual_environment_file" "cloud_init_config_memory_alpha" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "enterprise"
  source_raw {
    data = templatefile("${path.module}/templates/ubuntu-noble-vm/cloud-init.yml.tftpl", {
      hostname            = "memory-alpha"
      sysadmin_public_key = var.sysadmin_public_key
      ansible_public_key  = var.ansible_public_key
    })
    file_name = "cloud-init-config-memory-alpha.yml"
  }
}

resource "proxmox_virtual_environment_file" "cloud_init_config_hermes" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "enterprise"
  source_raw {
    data = templatefile("${path.module}/templates/ubuntu-noble-vm/cloud-init.yml.tftpl", {
      hostname            = "hermes"
      sysadmin_public_key = var.sysadmin_public_key
      ansible_public_key  = var.ansible_public_key
    })
    file_name = "cloud-init-config-hermes.yml"
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