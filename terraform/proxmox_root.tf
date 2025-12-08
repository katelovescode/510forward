# TODO:
# create OpenTofu user w/ root user & assign roles and groups etc
# get API tokens from data from the root?  Then do the same with the one for the opentofu thing?  Can you configure a provider with a variable?

resource "proxmox_virtual_environment_acme_account" "letsencrypt" {
  provider = proxmox.root

  name      = "letsencrypt"
  contact   = var.kate_email
  directory = "https://acme-v02.api.letsencrypt.org/directory"
  tos       = "https://letsencrypt.org/documents/LE-SA-v1.5-February-24-2025.pdf"
}