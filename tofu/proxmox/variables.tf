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
  description = "SSH public key injected into provisioned hosts for the kate user"
  type        = string
}

variable "ansible_public_key" {
  description = "SSH public key injected into provisioned hosts for the ansible user"
  type        = string
}

variable "ansible_private_key" {
  description = "SSH private key for the ansible user, used to bootstrap LXC containers via remote-exec"
  type        = string
  sensitive   = true
}

variable "haos_version" {
  description = "Home Assistant OS version to deploy (check github.com/home-assistant/operating-system/releases)"
  type        = string
}