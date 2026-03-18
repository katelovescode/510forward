module "ubuntu_noble_vm_template" {
  source              = "./templates/ubuntu-noble-vm"
  sysadmin_public_key = var.sysadmin_public_key
}