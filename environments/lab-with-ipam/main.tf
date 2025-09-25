# IPAM configuration is loaded from the symlinked ipam-config.tf file
# All IPAM settings are defined in the root ipam-config.tf (symlinked here)

locals {
  # Use environment override or global setting  
  enable_ipam = var.enable_ipam != null ? var.enable_ipam : var.global_enable_ipam
}

module "vms" {
  source = "../../modules/proxmox-vm"

  for_each = { for vm in var.vms : vm.name => vm }

  # Proxmox VM configuration
  target_node       = var.target_node
  vm_name           = each.value.name
  vm_cores          = each.value.cores
  vm_memory         = each.value.memory
  vm_disk_size      = each.value.disk_size
  vm_network_bridge = var.vm_network_bridge
  vm_static_ip      = each.value.static_ip
  vm_gateway        = each.value.gateway
  vm_datastore      = "local-lvm"
  template_id       = 9200  # ID of the template VM

  # IPAM configuration - ALL FROM CENTRALIZED CONFIG (via symlinked file)
  enable_ipam      = local.enable_ipam
  ipam_url         = local.ipam_config.url
  ipam_app_id      = local.ipam_config.app_id
  ipam_username    = local.ipam_config.username
  ipam_password    = local.ipam_config.password
  ipam_subnet_id   = each.value.subnet_id
  ipam_description = "Lab VM ${each.value.name} - deployed by Terraform"
}
