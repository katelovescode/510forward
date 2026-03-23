terraform {
  required_version = ">= 1.8"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.98"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}