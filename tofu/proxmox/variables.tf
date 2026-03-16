variable "proxmox_api_token" {
  description = "API token for the opentofu@pam Proxmox user, format: opentofu@pam!opentofu_token=<uuid>"
  type        = string
  sensitive   = true
}

variable "opentofu_ssh_private_key" {
  description = "SSH private key for opentofu"
  type        = string
  sensitive   = true
}

variable "sysadmin_public_key" {
  description = "SSH public key injected into provisioned hosts"
  type        = string
}