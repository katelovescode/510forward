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

variable "haos_version" {
  description = "Home Assistant OS version to deploy (check github.com/home-assistant/operating-system/releases)"
  type        = string
}

variable "phase" {
  description = "Deployment phase. 'bootstrap' provisions VMs with elevated RAM for initial service installation; 'runtime' uses reduced steady-state RAM. Pass -var phase=bootstrap when initializing a new VM."
  type        = string
  default     = "runtime"
  validation {
    condition     = contains(["bootstrap", "runtime"], var.phase)
    error_message = "phase must be 'bootstrap' or 'runtime'."
  }
}