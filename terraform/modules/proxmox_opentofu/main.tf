resource "proxmox_virtual_environment_time" "proxmox_time" {
  node_name = var.proxmox_node_1
  time_zone = "America/Chicago"
}

data "proxmox_virtual_environment_dns" "proxmox_dns" {
  node_name = var.proxmox_node_1
}

resource "proxmox_virtual_environment_dns" "proxmox_dns" {
  domain    = data.proxmox_virtual_environment_dns.proxmox_dns.domain
  node_name = data.proxmox_virtual_environment_dns.proxmox_dns.node_name

  servers = [
    var.proxmox_gateway
  ]
}

resource "proxmox_virtual_environment_network_linux_bridge" "vmbr0" {
  node_name = var.proxmox_node_1
  name      = "vmbr0"
  address   = join("", [var.proxmox_ip_address, "/", "24"])
  gateway   = var.proxmox_gateway
  ports = [
    var.proxmox_bridge_port
  ]
  vlan_aware = false
}

resource "proxmox_virtual_environment_hosts" "proxmox_hosts" {
  node_name = var.proxmox_node_1
  entry {
    address = "127.0.0.1"
    hostnames = [
      "localhost.localdomain",
      "localhost"
    ]
  }
  entry {
    address = var.proxmox_ip_address
    hostnames = [
      "proxmox.local",
      "proxmox",
    ]
  }
  entry {
    address = "::1"
    hostnames = [
      "ip6-localhost",
      "ip6-loopback",
    ]
  }
  entry {
    address = "fe00::0"
    hostnames = [
      "ip6-localnet",
    ]
  }
  entry {
    address = "ff00::0"
    hostnames = [
      "ip6-mcastprefix",
    ]
  }
  entry {
    address = "ff02::1"
    hostnames = [
      "ip6-allnodes",
    ]
  }
  entry {
    address = "ff02::2"
    hostnames = [
      "ip6-allrouters",
    ]
  }
  entry {
    address = "ff02::3"
    hostnames = [
      "ip6-allhosts",
    ]
  }
}

resource "proxmox_virtual_environment_apt_standard_repository" "no_subscription_repo" {
  handle = "no-subscription"
  node   = var.proxmox_node_1
}

resource "proxmox_virtual_environment_apt_repository" "no_subscription_repo" {
  enabled   = true
  file_path = proxmox_virtual_environment_apt_standard_repository.no_subscription_repo.file_path
  index     = proxmox_virtual_environment_apt_standard_repository.no_subscription_repo.index
  node      = proxmox_virtual_environment_apt_standard_repository.no_subscription_repo.node
}

resource "proxmox_virtual_environment_apt_standard_repository" "ceph_squid" {
  handle = "ceph-squid-enterprise"
  node   = var.proxmox_node_1
}

resource "proxmox_virtual_environment_apt_repository" "ceph_squid_repo" {
  enabled   = false
  file_path = proxmox_virtual_environment_apt_standard_repository.ceph_squid.file_path
  index     = proxmox_virtual_environment_apt_standard_repository.ceph_squid.index
  node      = proxmox_virtual_environment_apt_standard_repository.ceph_squid.node
}

resource "proxmox_virtual_environment_apt_standard_repository" "enterprise" {
  handle = "enterprise"
  node   = var.proxmox_node_1
}

resource "proxmox_virtual_environment_apt_repository" "enterprise_repo" {
  enabled   = false
  file_path = proxmox_virtual_environment_apt_standard_repository.enterprise.file_path
  index     = proxmox_virtual_environment_apt_standard_repository.enterprise.index
  node      = proxmox_virtual_environment_apt_standard_repository.enterprise.node
}

resource "proxmox_virtual_environment_role" "home_assistant_audit_role" {
  role_id = "HomeAssistant.Audit"

  privileges = [
    "Datastore.Audit",
    "Sys.Audit",
    "VM.Audit"
  ]
}

resource "proxmox_virtual_environment_role" "home_assistant_node_power_management_role" {
  role_id = "HomeAssistant.NodePowerMgmt"

  privileges = ["Sys.PowerMgmt"]
}

resource "proxmox_virtual_environment_role" "home_assistant_update_role" {
  role_id = "HomeAssistant.Update"

  privileges = ["Sys.Modify"]
}

resource "proxmox_virtual_environment_role" "home_assistant_vm_power_management_role" {
  role_id = "HomeAssistant.VMPowerMgmt"

  privileges = ["VM.PowerMgmt"]
}

resource "proxmox_virtual_environment_role" "homepage_audit_role" {
  role_id = "Homepage.Audit"

  privileges = [
    "Datastore.Audit",
    "Mapping.Audit",
    "Pool.Audit",
    "SDN.Audit",
    "Sys.Audit",
    "VM.Audit",
    "VM.GuestAgent.Audit"
  ]
}

resource "proxmox_virtual_environment_role" "homepage_power_management_role" {
  role_id = "Homepage.PowerMgmt"

  privileges = [
    "Sys.PowerMgmt",
    "VM.PowerMgmt"
  ]
}

resource "proxmox_virtual_environment_group" "home_assistant_group" {
  comment  = "Managed by OpenTofu - smart home server"
  group_id = "HomeAssistant"
  acl {
    path      = "/"
    propagate = true
    role_id   = "HomeAssistant.Audit"
  }
  acl {
    path      = "/"
    propagate = true
    role_id   = "HomeAssistant.NodePowerMgmt"
  }
  acl {
    path      = "/"
    propagate = true
    role_id   = "HomeAssistant.Update"
  }
  acl {
    path      = "/"
    propagate = true
    role_id   = "HomeAssistant.VMPowerMgmt"
  }
}

resource "proxmox_virtual_environment_group" "homepage_group" {
  comment  = "Managed by OpenTofu - dashboard"
  group_id = "Homepage"
  acl {
    path      = "/"
    propagate = true
    role_id   = "Homepage.Audit"
  }
  acl {
    path      = "/"
    propagate = true
    role_id   = "Homepage.PowerMgmt"
  }
}

resource "proxmox_virtual_environment_user" "home_assistant_user" {
  comment = "Managed by OpenTofu - smart home server"
  user_id = "homeassistant@pve"
  groups  = ["HomeAssistant"]
}

resource "proxmox_virtual_environment_user" "homepage_user" {
  comment = "Managed by OpenTofu - dashboard"
  user_id = "homepage@pve"
  groups  = ["Homepage"]
}

resource "proxmox_virtual_environment_user" "kate_user" {
  first_name = "Kate"
  comment    = "Managed by OpenTofu - Kate"
  user_id    = "kate@pam"
  email      = var.kate_email
  keys       = "x"
  last_name  = "Donaldson"
  acl {
    path      = "/"
    propagate = true
    role_id   = "Administrator"
  }
}

resource "proxmox_virtual_environment_user_token" "home_assistant_user_token" {
  token_name            = "homeassistant"
  user_id               = "homeassistant@pve"
  privileges_separation = false
  comment               = "Managed by OpenTofu - smart home"
}

resource "proxmox_virtual_environment_user_token" "homepage_user_token" {
  token_name            = "homepage"
  user_id               = "homepage@pve"
  privileges_separation = false
  comment               = "Managed by OpenTofu - dashboard"
}

resource "proxmox_virtual_environment_acl" "home_assistant_node_power_acl" {
  path     = "/"
  role_id  = proxmox_virtual_environment_role.home_assistant_node_power_management_role.role_id
  group_id = "HomeAssistant"
}

resource "proxmox_virtual_environment_acl" "home_assistant_vm_power_acl" {
  role_id  = proxmox_virtual_environment_role.home_assistant_vm_power_management_role.role_id
  path     = "/"
  group_id = "HomeAssistant"
}

resource "proxmox_virtual_environment_acl" "home_assistant_audit_acl" {
  role_id  = proxmox_virtual_environment_role.home_assistant_audit_role.role_id
  path     = "/"
  group_id = "HomeAssistant"
}

resource "proxmox_virtual_environment_acl" "home_assistant_update_acl" {
  role_id  = proxmox_virtual_environment_role.home_assistant_update_role.role_id
  path     = "/"
  group_id = "HomeAssistant"
}
resource "proxmox_virtual_environment_acl" "homepage_power_acl" {
  role_id  = proxmox_virtual_environment_role.homepage_power_management_role.role_id
  path     = "/"
  group_id = "Homepage"
}

resource "proxmox_virtual_environment_acl" "homepage_audit_acl" {
  role_id  = proxmox_virtual_environment_role.homepage_audit_role.role_id
  path     = "/"
  group_id = "Homepage"
}

resource "proxmox_virtual_environment_download_file" "debian_13_trixie" {
  content_type = "vztmpl"
  datastore_id = var.proxmox_image_datastore
  file_name    = "debian-13-generic-amd64.tar.zst"
  node_name    = var.proxmox_node_1
  url          = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-generic-amd64.qcow2"
}

resource "proxmox_virtual_environment_download_file" "debian_12_bookworm" {
  content_type = "vztmpl"
  datastore_id = var.proxmox_image_datastore
  file_name    = "debian-12-generic-amd64.tar.zst"
  node_name    = var.proxmox_node_1
  url          = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
}

resource "proxmox_virtual_environment_download_file" "ubuntu_24_04_3_live_server_amd64" {
  content_type = "iso"
  datastore_id = var.proxmox_image_datastore
  node_name    = var.proxmox_node_1
  url          = "https://releases.ubuntu.com/24.04.3/ubuntu-24.04.3-live-server-amd64.iso"
}

resource "proxmox_virtual_environment_download_file" "proxmox_9" {
  content_type = "iso"
  datastore_id = var.proxmox_image_datastore
  node_name    = var.proxmox_node_1
  url          = "https://enterprise.proxmox.com/iso/proxmox-ve_9.1-1.iso"
}

resource "proxmox_virtual_environment_container" "pihole" {
  console {
    enabled   = true
    tty_count = 2
    type      = "tty"
  }
  cpu {
    architecture = "amd64"
    cores        = 2
    units        = 1024
  }
  disk {
    acl           = false
    datastore_id  = var.proxmox_vm_ct_datastore
    mount_options = []
    quota         = false
    replicate     = false
    size          = 20
  }
  initialization {
    hostname = "pihole"
    ip_config {
      ipv4 {
        address = "dhcp"
      }
      ipv6 {
        address = "dhcp"
      }
    }
    user_account {
      keys = [
        var.kate_public_key
      ]
      password = var.proxmox_pihole_root_password
    }
  }
  memory {
    dedicated = 2048
    swap      = 512
  }
  network_interface {
    name     = "eth0"
    firewall = true
  }
  node_name = var.proxmox_node_1
  operating_system {
    template_file_id = proxmox_virtual_environment_download_file.debian_12_bookworm.id
    type             = "debian"
  }
  tags         = []
  unprivileged = true
}

resource "proxmox_virtual_environment_container" "homepage" {
  description = <<-EOT
            <div align='center'>
              <a href='https://Helper-Scripts.com' target='_blank' rel='noopener noreferrer'>
                <img src='https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/images/logo-81x112.png' alt='Logo' style='width:81px;height:112px;'/>
              </a>

              <h2 style='font-size: 24px; margin: 20px 0;'>Homepage LXC</h2>

              <p style='margin: 16px 0;'>
                <a href='https://ko-fi.com/community_scripts' target='_blank' rel='noopener noreferrer'>
                  <img src='https://img.shields.io/badge/&#x2615;-Buy us a coffee-blue' alt='spend Coffee' />
                </a>
              </p>

              <span style='margin: 0 10px;'>
                <i class="fa fa-github fa-fw" style="color: #f5f5f5;"></i>
                <a href='https://github.com/community-scripts/ProxmoxVE' target='_blank' rel='noopener noreferrer' style='text-decoration: none; color: #00617f;'>GitHub</a>
              </span>
              <span style='margin: 0 10px;'>
                <i class="fa fa-comments fa-fw" style="color: #f5f5f5;"></i>
                <a href='https://github.com/community-scripts/ProxmoxVE/discussions' target='_blank' rel='noopener noreferrer' style='text-decoration: none; color: #00617f;'>Discussions</a>
              </span>
              <span style='margin: 0 10px;'>
                <i class="fa fa-exclamation-circle fa-fw" style="color: #f5f5f5;"></i>
                <a href='https://github.com/community-scripts/ProxmoxVE/issues' target='_blank' rel='noopener noreferrer' style='text-decoration: none; color: #00617f;'>Issues</a>
              </span>
            </div>
        EOT
  console {
    enabled   = true
    tty_count = 2
    type      = "tty"
  }
  cpu {
    architecture = "amd64"
    cores        = 2
    units        = 1024
  }
  disk {
    acl           = false
    datastore_id  = var.proxmox_vm_ct_datastore
    mount_options = []
    quota         = false
    replicate     = false
    size          = 6
  }
  initialization {
    hostname = "homepage"
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_account {
      keys = [
        var.kate_public_key
      ]
      password = var.proxmox_homepage_root_password
    }
  }
  memory {
    dedicated = 4096
    swap      = 512
  }
  network_interface {
    name = "eth0"
  }
  node_name = var.proxmox_node_1
  operating_system {
    template_file_id = proxmox_virtual_environment_download_file.debian_12_bookworm.id
    type             = "debian"
  }
  tags = [
    "community-script",
    "dashboard"
  ]
  unprivileged = true
}

resource "proxmox_virtual_environment_vm" "bookstack" {
  agent {
    type    = "virtio"
    enabled = true
  }
  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
    units = 1024
  }
  # disk {
  #   size         = 3
  #   interface    = "ide2"
  #   datastore_id = var.proxmox_image_datastore
  # }
  disk {
    size         = 64
    interface    = "scsi0"
    iothread     = true
    datastore_id = var.proxmox_vm_ct_datastore
    file_format  = "raw"
  }
  keyboard_layout = "en-us"
  memory {
    dedicated = 4096
  }
  name = "bookstack"
  network_device {
    firewall = true
  }
  node_name = var.proxmox_node_1
  operating_system {
    type = "l26"
  }
  scsi_hardware = "virtio-scsi-single"
  vm_id         = 100
  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_account {
      keys     = [var.kate_public_key]
      password = var.proxmox_bookstack_root_password
      username = "kate"
    }
  }
}

resource "proxmox_virtual_environment_vm" "homeassistant" {
  agent {
    type    = "virtio"
    enabled = true
  }
  bios = "ovmf"
  cpu {
    cores = 2
    units = 1024
    flags = []
  }
  description = <<-EOT
            <div align='center'>
              <a href='https://Helper-Scripts.com' target='_blank' rel='noopener noreferrer'>
                <img src='https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/images/logo-81x112.png' alt='Logo' style='width:81px;height:112px;'/>
              </a>

              <h2 style='font-size: 24px; margin: 20px 0;'>Homeassistant OS VM</h2>

              <p style='margin: 16px 0;'>
                <a href='https://ko-fi.com/community_scripts' target='_blank' rel='noopener noreferrer'>
                  <img src='https://img.shields.io/badge/&#x2615;-Buy us a coffee-blue' alt='spend Coffee' />
                </a>
              </p>

              <span style='margin: 0 10px;'>
                <i class="fa fa-github fa-fw" style="color: #f5f5f5;"></i>
                <a href='https://github.com/community-scripts/ProxmoxVE' target='_blank' rel='noopener noreferrer' style='text-decoration: none; color: #00617f;'>GitHub</a>
              </span>
              <span style='margin: 0 10px;'>
                <i class="fa fa-comments fa-fw" style="color: #f5f5f5;"></i>
                <a href='https://github.com/community-scripts/ProxmoxVE/discussions' target='_blank' rel='noopener noreferrer' style='text-decoration: none; color: #00617f;'>Discussions</a>
              </span>
              <span style='margin: 0 10px;'>
                <i class="fa fa-exclamation-circle fa-fw" style="color: #f5f5f5;"></i>
                <a href='https://github.com/community-scripts/ProxmoxVE/issues' target='_blank' rel='noopener noreferrer' style='text-decoration: none; color: #00617f;'>Issues</a>
              </span>
            </div>
        EOT
  disk {
    size              = 32
    interface         = "scsi0"
    discard           = "on"
    file_format       = "raw"
    ssd               = true
    path_in_datastore = "vm-102-disk-0"
  }
  efi_disk {
    datastore_id      = var.proxmox_vm_ct_datastore
    file_format       = "raw"
    pre_enrolled_keys = false
    type              = "4m"
  }
  machine = "q35"
  memory {
    dedicated = 4096
  }
  name = "homeassistant"
  network_device {
    disconnected = false
  }
  node_name = var.proxmox_node_1
  operating_system {
    type = "l26"
  }
  serial_device {
    device = "socket"
  }
  tablet_device = false
  tags = [
    "community-script"
  ]
  vm_id = 102
  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_account {
      username = "root"
    }
  }
}

resource "proxmox_virtual_environment_vm" "gitlab" {
  agent {
    enabled = true
  }
  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
    units = 1024
  }
  description = <<-EOT
          ## TODO  
          - `truncate -s 0 /etc/machine-id /var/lib/dbus/machine-id`  
          - turn into template
      EOT
  disk {
    size         = 3
    interface    = "ide2"
    datastore_id = var.proxmox_image_datastore
  }
  disk {
    size         = 64
    interface    = "scsi0"
    iothread     = true
    datastore_id = var.proxmox_vm_ct_datastore
    file_format  = "raw"
  }
  memory {
    dedicated = 4096
  }
  name = "gitlab"
  network_device {
    firewall = true
  }
  node_name = var.proxmox_node_1
  operating_system {
    type = "l26"
  }
  scsi_hardware = "virtio-scsi-single"
  vm_id         = 105

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_account {
      keys     = [var.kate_public_key]
      password = var.proxmox_gitlab_root_password
      username = "kate"
    }
  }
}

resource "proxmox_virtual_environment_vm" "ubuntu_server_2024_template" {
  agent {
    enabled = true
  }
  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
    units = 1024
  }
  description = <<-EOT
            ## TODO  
            - `truncate -s 0 /etc/machine-id /var/lib/dbus/machine-id`  
            - turn into template
            - `hostnamectl set-hostname <newhostname>`
            - `passwd` to change user name
        EOT
  disk {
    size         = 3
    interface    = "ide2"
    datastore_id = var.proxmox_image_datastore
  }
  disk {
    size         = 64
    interface    = "scsi0"
    iothread     = true
    datastore_id = var.proxmox_vm_ct_datastore
    file_format  = "raw"
  }
  memory {
    dedicated = 4096
  }
  name      = "ubuntu-server-2024-template"
  node_name = var.proxmox_node_1
  network_device {
    firewall = true
  }
  operating_system {
    type = "l26"
  }
  scsi_hardware = "virtio-scsi-single"
  started       = false
  vm_id         = 999

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_account {
      keys     = [var.kate_public_key]
      password = var.proxmox_ubuntu_server_2024_template_root_password
      username = "kate"
    }
  }
}

resource "proxmox_virtual_environment_vm" "nginx_proxy_manager" {
  agent {
    enabled = true
  }
  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
    units = 1024
  }
  disk {
    size         = 3
    interface    = "ide2"
    datastore_id = var.proxmox_image_datastore
  }
  disk {
    size         = 64
    interface    = "scsi0"
    iothread     = true
    datastore_id = var.proxmox_vm_ct_datastore
    file_format  = "raw"
  }
  memory {
    dedicated = 4096
  }
  name = "nginx-proxy-manager"
  network_device {
    firewall = true
  }
  node_name = var.proxmox_node_1
  operating_system {
    type = "l26"
  }
  scsi_hardware = "virtio-scsi-single"
  vm_id         = 103

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_account {
      keys     = [var.kate_public_key]
      password = var.proxmox_nginx_proxy_manager_root_password
      username = "kate"
    }
  }
}

resource "proxmox_virtual_environment_certificate" "cert" {
  certificate = tls_self_signed_cert.proxmox_virtual_environment_certificate.cert_pem
  node_name   = var.proxmox_node_1
  private_key = tls_private_key.proxmox_virtual_environment_certificate.private_key_pem
}

resource "tls_private_key" "proxmox_virtual_environment_certificate" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "proxmox_virtual_environment_certificate" {
  # key_algorithm   = tls_private_key.proxmox_virtual_environment_certificate.algorithm
  private_key_pem = tls_private_key.proxmox_virtual_environment_certificate.private_key_pem

  subject {
    common_name  = "example.com"
    organization = "Terraform Provider for Proxmox"
  }

  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# __generated__ by OpenTofu from "default"
resource "proxmox_virtual_environment_cluster_firewall" "default" {
  ebtables       = null
  enabled        = null
  forward_policy = null
  input_policy   = null
  output_policy  = null
}

# __generated__ by OpenTofu from "Datacenter"
resource "proxmox_virtual_environment_cluster_options" "default" {
  bandwidth_limit_clone     = null
  bandwidth_limit_default   = null
  bandwidth_limit_migration = null
  bandwidth_limit_move      = null
  bandwidth_limit_restore   = null
  console                   = null
  crs_ha                    = null
  crs_ha_rebalance_on_start = null
  description               = null
  email_from                = var.kate_email
  ha_shutdown_policy        = null
  http_proxy                = null
  keyboard                  = "en-us"
  language                  = null
  mac_prefix                = var.proxmox_mac_prefix
  max_workers               = null
  migration_cidr            = null
  migration_type            = null
  next_id                   = null
  notify                    = null
}

# __generated__ by OpenTofu
resource "proxmox_virtual_environment_dns" "default" {
  domain    = "local"
  node_name = var.proxmox_node_1
  servers   = ["192.168.30.1"]
}

# __generated__ by OpenTofu from "container/proxmox/101"
resource "proxmox_virtual_environment_firewall_options" "pihole" {
  container_id  = 101
  dhcp          = null
  enabled       = null
  input_policy  = null
  ipfilter      = null
  log_level_in  = null
  log_level_out = null
  macfilter     = null
  ndp           = null
  node_name     = var.proxmox_node_1
  output_policy = null
  radv          = null
  vm_id         = null
}

# __generated__ by OpenTofu from "vm/proxmox/103"
resource "proxmox_virtual_environment_firewall_options" "nginx_proxy_manager" {
  container_id  = null
  dhcp          = null
  enabled       = null
  input_policy  = null
  ipfilter      = null
  log_level_in  = null
  log_level_out = null
  macfilter     = null
  ndp           = null
  node_name     = var.proxmox_node_1
  output_policy = null
  radv          = null
  vm_id         = 103
}

# __generated__ by OpenTofu from "vm/proxmox/999"
resource "proxmox_virtual_environment_firewall_options" "ubuntu_server_2024_template" {
  container_id  = null
  dhcp          = null
  enabled       = null
  input_policy  = null
  ipfilter      = null
  log_level_in  = null
  log_level_out = null
  macfilter     = null
  ndp           = null
  node_name     = var.proxmox_node_1
  output_policy = null
  radv          = null
  vm_id         = 999
}

# __generated__ by OpenTofu from "vm/proxmox/102"
resource "proxmox_virtual_environment_firewall_options" "homeassistant" {
  container_id  = null
  dhcp          = null
  enabled       = null
  input_policy  = null
  ipfilter      = null
  log_level_in  = null
  log_level_out = null
  macfilter     = null
  ndp           = null
  node_name     = var.proxmox_node_1
  output_policy = null
  radv          = null
  vm_id         = 102
}

# __generated__ by OpenTofu from "vm/proxmox/101"
resource "proxmox_virtual_environment_firewall_options" "bookstack" {
  container_id  = null
  dhcp          = null
  enabled       = null
  input_policy  = null
  ipfilter      = null
  log_level_in  = null
  log_level_out = null
  macfilter     = null
  ndp           = null
  node_name     = var.proxmox_node_1
  output_policy = null
  radv          = null
  vm_id         = 101
}

# __generated__ by OpenTofu from "container/proxmox/104"
resource "proxmox_virtual_environment_firewall_options" "homepage" {
  container_id  = 104
  dhcp          = null
  enabled       = null
  input_policy  = null
  ipfilter      = null
  log_level_in  = null
  log_level_out = null
  macfilter     = null
  ndp           = null
  node_name     = var.proxmox_node_1
  output_policy = null
  radv          = null
  vm_id         = null
}

# __generated__ by OpenTofu from "vm/proxmox/105"
resource "proxmox_virtual_environment_firewall_options" "gitlab" {
  container_id  = null
  dhcp          = null
  enabled       = null
  input_policy  = null
  ipfilter      = null
  log_level_in  = null
  log_level_out = null
  macfilter     = null
  ndp           = null
  node_name     = var.proxmox_node_1
  output_policy = null
  radv          = null
  vm_id         = 105
}

# __generated__ by OpenTofu from "vm/proxmox/101"
resource "proxmox_virtual_environment_firewall_rules" "bookstack" {
  container_id = null
  node_name    = var.proxmox_node_1
  vm_id        = 101
}

# __generated__ by OpenTofu from "vm/proxmox/999"
resource "proxmox_virtual_environment_firewall_rules" "ubuntu_server_2024_template" {
  container_id = null
  node_name    = var.proxmox_node_1
  vm_id        = 999
}

# __generated__ by OpenTofu from "node/proxmox"
resource "proxmox_virtual_environment_firewall_rules" "node_1" {
  container_id = null
  node_name    = var.proxmox_node_1
  vm_id        = null
}

# __generated__ by OpenTofu from "vm/proxmox/103"
resource "proxmox_virtual_environment_firewall_rules" "nginx_proxy_manager" {
  container_id = null
  node_name    = var.proxmox_node_1
  vm_id        = 103
}

# __generated__ by OpenTofu from "vm/proxmox/102"
resource "proxmox_virtual_environment_firewall_rules" "homeassistant" {
  container_id = null
  node_name    = var.proxmox_node_1
  vm_id        = 102
}

# __generated__ by OpenTofu from "container/proxmox/104"
resource "proxmox_virtual_environment_firewall_rules" "homepage" {
  container_id = 104
  node_name    = var.proxmox_node_1
  vm_id        = null
}

# __generated__ by OpenTofu from "cluster"
resource "proxmox_virtual_environment_firewall_rules" "cluster" {
  container_id = null
  node_name    = null
  vm_id        = null
}

# __generated__ by OpenTofu from "container/proxmox/101"
resource "proxmox_virtual_environment_firewall_rules" "pihole" {
  container_id = 101
  node_name    = var.proxmox_node_1
  vm_id        = null
}

# __generated__ by OpenTofu from "vm/proxmox/105"
resource "proxmox_virtual_environment_firewall_rules" "gitlab" {
  container_id = null
  node_name    = var.proxmox_node_1
  vm_id        = 105
}

# __generated__ by OpenTofu from "proxmox"
resource "proxmox_virtual_environment_time" "node_1" {
  node_name = var.proxmox_node_1
  time_zone = "America/Chicago"
}
