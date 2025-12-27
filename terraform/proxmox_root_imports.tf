import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = proxmox_virtual_environment_acme_account.letsencrypt
  id = "letsencrypt"
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = proxmox_virtual_environment_acme_dns_plugin.letsencrypt
  id = "letsencrypt"
}

import {
  to = proxmox_virtual_environment_user.root_user
  id = "root@pam"
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = proxmox_virtual_environment_role.open_tofu_role
  id = "OpenTofu"
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = proxmox_virtual_environment_group.open_tofu_group
  id = "OpenTofu"
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = proxmox_virtual_environment_user.open_tofu_user
  id = "opentofu@pve"
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = proxmox_virtual_environment_user_token.open_tofu_user_token
  id = "opentofu@pve!opentofu"
}