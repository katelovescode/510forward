provider "proxmox" {
  endpoint  = "https://192.168.30.170:8006"
  api_token = var.proxmox_api_token
  insecure  = true

  ssh {
    agent       = false
    username    = "opentofu"
    private_key = var.opentofu_ssh_private_key
  }
}
