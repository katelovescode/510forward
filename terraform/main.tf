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

  kate_email            = var.kate_email
  proxmox_root_password = var.proxmox_root_password
}

module "proxmox_opentofu" {
  source     = "./modules/proxmox_opentofu"
  depends_on = [module.proxmox_root]

  proxmox_import_enabled                            = var.proxmox_import_enabled
  proxmox_node_1                                    = var.proxmox_node_1
  proxmox_gateway                                   = var.proxmox_gateway
  proxmox_ip_address                                = var.proxmox_ip_address
  proxmox_bridge_port                               = var.proxmox_bridge_port
  kate_email                                        = var.kate_email
  proxmox_image_datastore                           = var.proxmox_image_datastore
  proxmox_vm_ct_datastore                           = var.proxmox_vm_ct_datastore
  kate_public_key                                   = var.kate_public_key
  proxmox_pihole_root_password                      = var.proxmox_pihole_root_password
  proxmox_homepage_root_password                    = var.proxmox_homepage_root_password
  proxmox_bookstack_root_password                   = var.proxmox_bookstack_root_password
  proxmox_gitlab_root_password                      = var.proxmox_gitlab_root_password
  proxmox_ubuntu_server_2024_template_root_password = var.proxmox_ubuntu_server_2024_template_root_password
  proxmox_nginx_proxy_manager_root_password         = var.proxmox_nginx_proxy_manager_root_password
  proxmox_mac_prefix                                = var.proxmox_mac_prefix
  proxmox_dns_cf_token                              = var.proxmox_dns_cf_token
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
