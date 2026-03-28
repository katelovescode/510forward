module "ubuntu_noble_vm_template" {
  source              = "./templates/ubuntu-noble-vm"
  sysadmin_public_key = var.sysadmin_public_key
  ansible_public_key  = var.ansible_public_key
}

module "ubuntu_noble_lxc_template" {
  source = "./templates/ubuntu-noble-lxc"
}