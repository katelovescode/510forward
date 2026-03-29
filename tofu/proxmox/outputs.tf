output "centaurus_lxc_id" {
  description = "Container ID assigned to centaurus by Proxmox"
  value       = proxmox_virtual_environment_container.centaurus.id
}

output "codsworth_vmid" {
  description = "VMID assigned to codsworth by Proxmox"
  value       = proxmox_virtual_environment_vm.codsworth.id
}

output "ubuntu_cloud_template_vmid" {
  description = "VMID of the Ubuntu Noble cloud template"
  value       = module.ubuntu_noble_vm_template.vm_id
}