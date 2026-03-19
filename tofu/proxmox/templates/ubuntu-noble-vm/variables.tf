variable "sysadmin_public_key" {
  description = "SSH public key injected into provisioned hosts for the kate user"
  type        = string
}

variable "ansible_public_key" {
  description = "SSH public key injected into provisioned hosts for the ansible user"
  type        = string
}