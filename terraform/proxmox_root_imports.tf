import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = proxmox_virtual_environment_acme_account.letsencrypt
  id = "letsencrypt"
}

