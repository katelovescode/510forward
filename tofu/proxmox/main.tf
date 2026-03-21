provider "proxmox" {
  endpoint  = "https://enterprise.510forward.space:8006"
  api_token = var.proxmox_api_token
  insecure  = false

  ssh {
    agent       = false
    username    = "opentofu"
    private_key = var.opentofu_ssh_private_key
  }
}