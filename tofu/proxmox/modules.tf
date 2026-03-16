module "ubuntu_noble_template" {
  source              = "./templates/ubuntu-noble"
  sysadmin_public_key = var.sysadmin_public_key
}