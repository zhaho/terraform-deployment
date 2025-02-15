variable "target_node" { default = "proxmox" }
variable "vm_network_bridge" { default = "vmbr0" }

variable "vms" {
  description = "List of VM configurations"
  type = list(object({
    name           = string
    cores          = number
    memory         = number
    disk_size      = number
    static_ip      = string
    gateway        = string
  }))
  default = [
    {
      name      = "lab-vm-1"
      cores     = 2
      memory    = 4096
      disk_size = 20
      static_ip = "10.4.5.31/24"
      gateway   = "10.4.5.1"
    },
    {
      name      = "lab-vm-2"
      cores     = 2
      memory    = 4096
      disk_size = 20
      static_ip = "10.4.5.32/24"
      gateway   = "10.4.5.1"
    },
    {
      name      = "lab-vm-3"
      cores     = 2
      memory    = 4096
      disk_size = 20
      static_ip = "10.4.5.33/24"
      gateway   = "10.4.5.1"
    }
  ]
}


variable "pm_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "pm_api_token_id" {
  description = "Proxmox API Token ID"
  type        = string
}

variable "pm_api_token_secret" {
  description = "Proxmox API Token Secret"
  type        = string
  sensitive   = true
}

