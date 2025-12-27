terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source                = "bpg/proxmox"
      version               = "0.89.0"
      configuration_aliases = [proxmox.root]
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = false
}

provider "proxmox" {
  alias    = "root"
  endpoint = var.proxmox_endpoint
  insecure = false
}

module "proxmox_root" {
  source = "./modules/proxmox_root"
  providers = {
    proxmox = proxmox.root
  }
}

module "proxmox_opentofu" {
  source = "./modules/proxmox_opentofu"
}


# TODO: need to create the config for gitlab VM; ssh url (check all configs in gitlab.rb)
# needs to be the Host value on my local machine, i.e. `gitlab` instead of `gitlab.510forward.space`
# because NGINX Proxy Manager can't proxy SSH commands

# TODO: put a note to self that you can't copy-paste in Proxmox shell?
# TODO: install vim

# Manual config needed:
# Backups

# TODO: install qemu-agents on VMs

# set up 2fa for Kate
# Add a metrics server
# add password for HA user for proxmox
# add password for Homepage user for proxmox
