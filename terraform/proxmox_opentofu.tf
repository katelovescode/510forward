resource "proxmox_virtual_environment_time" "proxmox_time" {
  node_name = var.proxmox_node
  time_zone = "America/Chicago"
}

data "proxmox_virtual_environment_dns" "proxmox_dns" {
  node_name = var.proxmox_node
}

resource "proxmox_virtual_environment_dns" "proxmox_dns" {
  domain    = data.proxmox_virtual_environment_dns.proxmox_dns.domain
  node_name = data.proxmox_virtual_environment_dns.proxmox_dns.node_name

  servers = [
    var.proxmox_gateway
  ]
}

resource "proxmox_virtual_environment_network_linux_bridge" "vmbr0" {
  node_name = var.proxmox_node
  name      = "vmbr0"
  address   = join("", [var.proxmox_ip_address, "/", "24"])
  gateway   = var.proxmox_gateway
  ports = [
    var.proxmox_bridge_port
  ]
  vlan_aware = false
}

resource "proxmox_virtual_environment_hosts" "proxmox_hosts" {
  node_name = var.proxmox_node
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
  node   = var.proxmox_node
}

resource "proxmox_virtual_environment_apt_repository" "no_subscription_repo" {
  enabled   = true
  file_path = proxmox_virtual_environment_apt_standard_repository.no_subscription_repo.file_path
  index     = proxmox_virtual_environment_apt_standard_repository.no_subscription_repo.index
  node      = proxmox_virtual_environment_apt_standard_repository.no_subscription_repo.node
}

resource "proxmox_virtual_environment_apt_standard_repository" "ceph_squid" {
  handle = "ceph-squid-enterprise"
  node   = var.proxmox_node
}

resource "proxmox_virtual_environment_apt_repository" "ceph_squid_repo" {
  enabled   = false
  file_path = proxmox_virtual_environment_apt_standard_repository.ceph_squid.file_path
  index     = proxmox_virtual_environment_apt_standard_repository.ceph_squid.index
  node      = proxmox_virtual_environment_apt_standard_repository.ceph_squid.node
}

resource "proxmox_virtual_environment_apt_standard_repository" "enterprise" {
  handle = "enterprise"
  node   = var.proxmox_node
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

resource "proxmox_virtual_environment_user_token" "home_assistant_api_token" {
  token_name            = "homeassistant"
  user_id               = "homeassistant@pve"
  privileges_separation = false
  comment               = "Managed by OpenTofu - smart home"
}

resource "proxmox_virtual_environment_user_token" "homepage_api_token" {
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
  node_name    = var.proxmox_node
  url          = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-generic-amd64.qcow2"
}

resource "proxmox_virtual_environment_download_file" "debian_12_bookworm" {
  content_type = "vztmpl"
  datastore_id = var.proxmox_image_datastore
  file_name    = "debian-12-generic-amd64.tar.zst"
  node_name    = var.proxmox_node
  url          = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
}

resource "proxmox_virtual_environment_download_file" "ubuntu_24_04_3_live_server_amd64" {
  content_type = "iso"
  datastore_id = var.proxmox_image_datastore
  node_name    = var.proxmox_node
  url          = "https://releases.ubuntu.com/24.04.3/ubuntu-24.04.3-live-server-amd64.iso"
}

resource "proxmox_virtual_environment_download_file" "proxmox_9" {
  content_type = "iso"
  datastore_id = var.proxmox_image_datastore
  node_name    = var.proxmox_node
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
  }
  memory {
    dedicated = 2048
    swap      = 512
  }
  network_interface {
    mac_address = "BC:24:11:10:08:69"
    name        = "eth0"
    firewall    = true
  }
  node_name = var.proxmox_node
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
  }
  memory {
    dedicated = 4096
    swap      = 512
  }
  network_interface {
    mac_address = "BC:24:11:67:74:72"
    name        = "eth0"
  }
  node_name = var.proxmox_node
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
    mac_address = "BC:24:11:CF:07:24"
    firewall    = true
  }
  node_name = var.proxmox_node
  operating_system {
    type = "l26"
  }
  scsi_hardware = "virtio-scsi-single"
  vm_id         = 100
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
    mac_address  = "02:0F:DA:89:13:57"
    disconnected = false
  }
  node_name = var.proxmox_node
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
    mac_address = "BC:24:11:59:EA:69"
    firewall    = true
  }
  node_name = var.proxmox_node
  operating_system {
    type = "l26"
  }
  scsi_hardware = "virtio-scsi-single"
  vm_id         = 105
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
  node_name = var.proxmox_node
  network_device {
    mac_address = "BC:24:11:DF:F2:0B"
    firewall    = true
  }
  operating_system {
    type = "l26"
  }
  scsi_hardware = "virtio-scsi-single"
  started       = false
  vm_id         = 999
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
    mac_address = "BC:24:11:DF:4D:13"
    firewall    = true
  }
  node_name = var.proxmox_node
  operating_system {
    type = "l26"
  }
  scsi_hardware = "virtio-scsi-single"
  vm_id         = 103
}
