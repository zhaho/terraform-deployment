module "vms" {
  source = "../../modules/proxmox-vm"

  for_each = { for vm in var.vms : vm.name => vm }

  target_node       = var.target_node
  vm_name           = each.value.name
  vm_cores          = each.value.cores
  vm_memory         = each.value.memory
  vm_disk_size      = each.value.disk_size
  vm_network_bridge = var.vm_network_bridge
  vm_static_ip      = each.value.static_ip
  vm_gateway        = each.value.gateway
  vm_datastore      = "local-lvm"
  template_id       = 9000  # ID of the template VM
}