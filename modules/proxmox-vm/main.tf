terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.71.0"
    }
  }
}


resource "proxmox_virtual_environment_vm" "vm" {
  node_name   = var.target_node
  name        = var.vm_name
  description = "Managed by Terraform."
  tags        = ["terraform"]

  started     = true
  on_boot     = true

  agent {
    enabled = true
  }

  clone {
    node_name = var.target_node
    vm_id = var.template_id
  }

  operating_system {
    type = "l26"
  }

  cpu {
    cores = var.vm_cores
  }

  memory {
    dedicated = var.vm_memory
  }

  disk {
    datastore_id = var.vm_datastore
    discard      = "on"
    interface    = "scsi0"
    size         = var.vm_disk_size
  }

  vga {
    type = "serial0"
  }

  network_device {
    bridge = var.vm_network_bridge
    enabled = "true"
  }

  initialization {
    datastore_id = var.vm_datastore

    ip_config {
      ipv4 {
        address = var.vm_static_ip
        gateway = var.vm_gateway
      }
    }

    dns {
      servers = ["4.4.4.4", "8.8.8.8"]
    }
  }
}

