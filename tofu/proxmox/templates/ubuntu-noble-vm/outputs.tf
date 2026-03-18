output "vm_id" {
  description = "VMID of the Ubuntu Noble cloud template"
  value       = proxmox_virtual_environment_vm.ubuntu_cloud_template.vm_id
}