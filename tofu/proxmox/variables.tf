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

variable "bootstrapping_vms" {
  description = "VMs currently being bootstrapped. These receive elevated RAM for initial service installation; all others use runtime RAM. Default empty = all VMs at runtime. Example: -var 'bootstrapping_vms=[\"memory-alpha\"]'"
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for v in var.bootstrapping_vms : contains(["centaurus", "norville", "dorothy", "codsworth", "memory-alpha"], v)])
    error_message = "bootstrapping_vms must only contain known host names: centaurus, norville, dorothy, codsworth, memory-alpha."
  }
}