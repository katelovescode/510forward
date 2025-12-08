terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source                = "bpg/proxmox"
      version               = "0.89.0"
      configuration_aliases = [proxmox.root]
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = false
}

provider "proxmox" {
  alias     = "root"
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_root_api_token
  insecure  = false
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# TODO: need to create the config for gitlab VM; ssh url (check all configs in gitlab.rb)
# needs to be the Host value on my local machine, i.e. `gitlab` instead of `gitlab.510forward.space`
# because NGINX Proxy Manager can't proxy SSH commands

# TODO: some way to script the configuration of the OpenTofu User, Group, Role, Permissions
# TODO: put a note to self that you can't copy-paste in Proxmox shell?
# TODO: change root password?
# TODO: create users?
# TODO: install vim
# TODO: repository management - blocked by current bug: https://github.com/bpg/terraform-provider-proxmox/issues/2341


# Manual config needed:
# Create OpenTofu user
# Set OpenTofu user permissions
# Manually change root password
# Backups

# TODO: install qemu-agents on VMs