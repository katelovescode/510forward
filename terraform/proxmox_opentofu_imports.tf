# import {
#   for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

#   to = module.proxmox_opentofu.proxmox_virtual_environment_acl.home_assistant_vm_power_acl
#   id = "/?HomeAssistant?HomeAssistant.VMPowerMgmt"
# }

# import {
#   for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

#   to = module.proxmox_opentofu.proxmox_virtual_environment_acl.home_assistant_node_power_acl
#   id = "/?HomeAssistant?HomeAssistant.NodePowerMgmt"
# }

# import {
#   for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

#   to = module.proxmox_opentofu.proxmox_virtual_environment_acl.home_assistant_audit_acl
#   id = "/?HomeAssistant?HomeAssistant.Audit"
# }

# import {
#   for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

#   to = module.proxmox_opentofu.proxmox_virtual_environment_acl.home_assistant_update_acl
#   id = "/?HomeAssistant?HomeAssistant.Update"
# }

# import {
#   for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

#   to = module.proxmox_opentofu.proxmox_virtual_environment_acl.homepage_power_acl
#   id = "/?Homepage?Homepage.PowerMgmt"
# }

# import {
#   for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

#   to = module.proxmox_opentofu.proxmox_virtual_environment_acl.homepage_audit_acl
#   id = "/?Homepage?Homepage.Audit"
# }

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_container.pihole
  id = join("", [var.proxmox_node_1, "/101"])
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_container.homepage
  id = join("", [var.proxmox_node_1, "/104"])
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_group.home_assistant_group
  id = "HomeAssistant"
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_group.homepage_group
  id = "Homepage"
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_hosts.proxmox_hosts
  id = var.proxmox_node_1
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_dns.proxmox_dns
  id = var.proxmox_node_1
}

import {
  # for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []
  # linux bridge should always be imported; new proxmox instances already have it configured

  to = module.proxmox_opentofu.proxmox_virtual_environment_network_linux_bridge.vmbr0
  id = join("", [var.proxmox_node_1, ":", "vmbr0"])
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_time.proxmox_time
  id = var.proxmox_node_1
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_apt_repository.no_subscription_repo
  id = join("", [var.proxmox_node_1, ",", "/etc/apt/sources.list.d/proxmox.sources", ",", 0])
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_apt_repository.ceph_squid_repo
  id = join("", [var.proxmox_node_1, ",", "/etc/apt/sources.list.d/ceph.sources", ",", 0])
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_apt_repository.enterprise_repo
  id = join("", [var.proxmox_node_1, ",", "/etc/apt/sources.list.d/pve-enterprise.sources", ",", 0])
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_role.home_assistant_audit_role
  id = "HomeAssistant.Audit"
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_role.home_assistant_node_power_management_role
  id = "HomeAssistant.NodePowerMgmt"
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_role.home_assistant_update_role
  id = "HomeAssistant.Update"
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_role.home_assistant_vm_power_management_role
  id = "HomeAssistant.VMPowerMgmt"
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_role.homepage_audit_role
  id = "Homepage.Audit"
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_role.homepage_power_management_role
  id = "Homepage.PowerMgmt"
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_user_token.home_assistant_user_token
  id = "homeassistant@pve!homeassistant"
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_user_token.homepage_user_token
  id = "homepage@pve!homepage"
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_user.home_assistant_user
  id = "homeassistant@pve"
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_user.homepage_user
  id = "homepage@pve"
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_user.kate_user
  id = "kate@pam"
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_vm.bookstack
  id = join("", [var.proxmox_node_1, "/100"])
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_vm.homeassistant
  id = join("", [var.proxmox_node_1, "/102"])
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_vm.nginx_proxy_manager
  id = join("", [var.proxmox_node_1, "/103"])
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_vm.gitlab
  id = join("", [var.proxmox_node_1, "/105"])
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_vm.ubuntu_server_2024_template
  id = join("", [var.proxmox_node_1, "/999"])
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_cluster_firewall.default
  id = "default"
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_cluster_options.default
  id = "Datacenter"
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_dns.default
  id = var.proxmox_node_1
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_firewall_options.pihole
  id = join("", ["container/", var.proxmox_node_1, "/101"])
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_firewall_options.homepage
  id = join("", ["container/", var.proxmox_node_1, "/104"])
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_firewall_options.bookstack
  id = join("", ["vm/", var.proxmox_node_1, "/101"])
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_firewall_options.homeassistant
  id = join("", ["vm/", var.proxmox_node_1, "/102"])
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_firewall_options.nginx_proxy_manager
  id = join("", ["vm/", var.proxmox_node_1, "/103"])
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_firewall_options.gitlab
  id = join("", ["vm/", var.proxmox_node_1, "/105"])
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_firewall_options.ubuntu_server_2024_template
  id = join("", ["vm/", var.proxmox_node_1, "/999"])
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_firewall_rules.cluster
  id = "cluster"
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_firewall_rules.node_1
  id = join("", ["node/", var.proxmox_node_1])
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_firewall_rules.pihole
  id = join("", ["container/", var.proxmox_node_1, "/101"])
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_firewall_rules.homepage
  id = join("", ["container/", var.proxmox_node_1, "/104"])
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_firewall_rules.bookstack
  id = join("", ["vm/", var.proxmox_node_1, "/101"])
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_firewall_rules.homeassistant
  id = join("", ["vm/", var.proxmox_node_1, "/102"])
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_firewall_rules.nginx_proxy_manager
  id = join("", ["vm/", var.proxmox_node_1, "/103"])
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_firewall_rules.gitlab
  id = join("", ["vm/", var.proxmox_node_1, "/105"])
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_firewall_rules.ubuntu_server_2024_template
  id = join("", ["vm/", var.proxmox_node_1, "/999"])
}

import {
  for_each = var.proxmox_import_enabled ? toset(["enabled"]) : []

  to = module.proxmox_opentofu.proxmox_virtual_environment_time.node_1
  id = var.proxmox_node_1
}