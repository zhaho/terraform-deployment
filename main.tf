resource "proxmox_virtual_environment_vm" "sample-server" {
  node_name   = "proxmox"
  name        = "sample-server-hostname"
  description = "Sample Server.  Managed by Terraform."
  tags        = ["sample"]
  started     = true
  on_boot     = true

  agent {
    enabled = true
  }

  clone {
    node_name = "proxmox"
    vm_id = 9000
  }

  operating_system {
    type = "l26"
  }

  cpu {
    cores = 2
  }
  memory {
    dedicated = 4096
  }

  disk {
    datastore_id = "local-lvm"
    discard      = "on"
    interface    = "scsi0"
    size         = 30  # disk size in gigabytes (GB)
  }

  vga {
    type = "serial0"
  }

  network_device {
    bridge        = "vmbr0"
    enabled       = "true"
    # mac_address   = ""  # Set this following first creation of VM.
  }

  initialization {
    datastore_id = "local-lvm"

    ip_config {
      ipv4 {
        address = "10.4.5.30/24"
        gateway = "10.4.5.1"
      }
    }

    dns {
      servers = ["4.4.4.4", "8.8.8.8"]
    }

    
  }

}