output "centaurus_vmid" {
  description = "VMID assigned to centaurus by Proxmox"
  value       = proxmox_virtual_environment_vm.centaurus.id
}

output "ubuntu_cloud_template_vmid" {
  description = "VMID of the Ubuntu Noble cloud template"
  value       = module.ubuntu_noble_vm_template.vm_id
}