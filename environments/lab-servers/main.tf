module "lab_vm" {
  source = "../../modules/proxmox-vm"

  target_node       = var.target_node
  vm_name           = var.vm_name
  vm_cores          = var.vm_cores
  vm_memory         = var.vm_memory
  vm_disk_size      = var.vm_disk_size
  vm_network_bridge = var.vm_network_bridge
  vm_static_ip      = var.vm_static_ip
  vm_gateway        = var.vm_gateway
  vm_datastore      = "local-lvm"
  template_id       = 9000  # ID of the template VM
}
