resource "proxmox_virtual_environment_user" "root_user" {
  comment  = "Managed by OpenTofu"
  user_id  = "root@pam"
  email    = var.kate_email
  password = var.proxmox_root_password
}

resource "proxmox_virtual_environment_role" "open_tofu_role" {

  role_id = "OpenTofu"
  privileges = [
    "Datastore.AllocateSpace",
    "Datastore.AllocateTemplate",
    "Datastore.Audit",
    "Group.Allocate",
    "Mapping.Audit",
    "Permissions.Modify",
    "Pool.Audit",
    "Realm.AllocateUser",
    "SDN.Audit",
    "SDN.Use",
    "Sys.Audit",
    "Sys.Modify",
    "User.Modify",
    "VM.Allocate",
    "VM.Audit",
    "VM.Config.CDROM",
    "VM.Config.CPU",
    "VM.Config.Cloudinit",
    "VM.Config.Disk",
    "VM.Config.HWType",
    "VM.Config.Memory",
    "VM.Config.Network",
    "VM.Config.Options",
    "VM.GuestAgent.Audit",
    "VM.PowerMgmt"
  ]
}

resource "proxmox_virtual_environment_group" "open_tofu_group" {

  comment  = "Managed by OpenTofu - OpenTofu group"
  group_id = "OpenTofu"
  acl {
    path      = "/"
    propagate = true
    role_id   = "OpenTofu"
  }
}

resource "proxmox_virtual_environment_user" "open_tofu_user" {

  comment = "Managed by OpenTofu - OpenTofu user"
  user_id = "opentofu@pve"
  groups  = ["OpenTofu"]
}

resource "proxmox_virtual_environment_user_token" "open_tofu_user_token" {

  token_name            = "opentofu"
  user_id               = "opentofu@pve"
  privileges_separation = false
  comment               = "Managed by OpenTofu - OpenTofu user token"
}

resource "proxmox_virtual_environment_acme_account" "letsencrypt" {

  name      = "letsencrypt"
  contact   = var.kate_email
  directory = "https://acme-v02.api.letsencrypt.org/directory"
  tos       = "https://letsencrypt.org/documents/LE-SA-v1.5-February-24-2025.pdf"
}

resource "proxmox_virtual_environment_acme_dns_plugin" "letsencrypt" {
  plugin = "letsencrypt"
  api    = "letsencrypt"
}