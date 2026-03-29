output "template_file_id" {
  description = "File ID of the Ubuntu Noble LXC template"
  value       = proxmox_virtual_environment_download_file.ubuntu_noble_lxc_template.id
}
