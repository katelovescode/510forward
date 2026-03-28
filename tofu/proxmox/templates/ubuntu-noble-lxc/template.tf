resource "proxmox_virtual_environment_download_file" "ubuntu_noble_lxc_template" {
  content_type        = "vztmpl"
  datastore_id        = "local"
  node_name           = "enterprise"
  url                 = "http://download.proxmox.com/images/system/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
  file_name           = "ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
  overwrite_unmanaged = true
}
