import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_root.proxmox_virtual_environment_acme_account.letsencrypt
  id = "letsencrypt"
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_root.proxmox_virtual_environment_acme_dns_plugin.letsencrypt
  id = "letsencrypt"
}

import {
  to = module.proxmox_root.proxmox_virtual_environment_user.root_user
  id = "root@pam"
}

import {
  to = module.proxmox_root.proxmox_virtual_environment_role.open_tofu_role
  id = "OpenTofu"
}

import {
  to = module.proxmox_root.proxmox_virtual_environment_group.open_tofu_group
  id = "OpenTofu"
}

import {
  to = module.proxmox_root.proxmox_virtual_environment_user.open_tofu_user
  id = "opentofu@pve"
}

import {
  to = module.proxmox_root.proxmox_virtual_environment_user_token.open_tofu_user_token
  id = "opentofu@pve!opentofu"
}