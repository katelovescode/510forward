resource "proxmox_virtual_environment_file" "cloud_init_user_data" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "enterprise"

  source_raw {
    data      = templatefile("${path.module}/cloud-init.yml.tftpl", {
      hostname            = "ubuntu-cloud-template"
      sysadmin_public_key = var.sysadmin_public_key
      ansible_public_key  = var.ansible_public_key
    })
    file_name = "cloud-init-user-data.yml"
  }
}

resource "proxmox_virtual_environment_download_file" "ubuntu_noble_cloud_image" {
  content_type        = "iso"
  datastore_id        = "local"
  node_name           = "enterprise"
  url                 = "https://cloud-images.ubuntu.com/noble/20260321/noble-server-cloudimg-amd64.img"
  file_name           = "noble-server-cloudimg-amd64.img"
  overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_vm" "ubuntu_cloud_template" {
  name      = "ubuntu-cloud-template"
  node_name = "enterprise"
  vm_id     = 10001
  template  = true
  started   = false
  on_boot   = false

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.ubuntu_noble_cloud_image.id
    interface    = "scsi0"
    discard      = "on"
    ssd          = true
  }

  initialization {
    user_data_file_id = proxmox_virtual_environment_file.cloud_init_user_data.id
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  vga {
    type = "std"
  }

  boot_order = ["scsi0"]

  description = "Base Ubuntu 24.04 VM for cloning. Managed by OpenTofu"
}