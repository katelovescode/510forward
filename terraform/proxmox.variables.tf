
variable "proxmox_api_token" {
  type        = string
  description = "API Token to access Proxmox"
  sensitive   = true
}

variable "proxmox_root_api_token" {
  type        = string
  description = "API Token to access Proxmox with root account"
  sensitive   = true
}

variable "proxmox_endpoint" {
  type        = string
  description = "IP address to access Proxmox (including Port)"
}

variable "proxmox_node" {
  type        = string
  description = "Hostname of the node you are acting on"
}

variable "proxmox_bridge_port" {
  type        = string
  description = "Name of the bridge port vmbr0 uses in your initial install of Proxmox (i.e. 'enp5s0'"
}

variable "proxmox_image_datastore" {
  type        = string
  description = "Name/ID of the datastore that retains ISOs and CT templates (i.e. 'local')"
}

variable "proxmox_vm_ct_datastore" {
  type        = string
  description = "Name/ID of the datastore that retains VM and CT disks (i.e. 'local-lvm')"
}

variable "kate_email" {
  type        = string
  description = "Sarge's email"
}

variable "proxmox_ip_address" {
  type        = string
  description = "IP Address for the parent Proxmox instance"
}

variable "proxmox_gateway" {
  type        = string
  description = "IP Address for the parent Proxmox gateway"
}

variable "proxmox_import_enabled" {
  type        = bool
  description = "For use with test environments vs production during import phase"
}