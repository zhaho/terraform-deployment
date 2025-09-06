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
      name      = "ipam"
      cores     = 2
      memory    = 4096
      disk_size = 40
      static_ip = "10.4.5.66/24"
      gateway   = "10.4.5.1"
    }
  ]
}

variable "host_user" {
  description = "The SSH user for connecting to the remote host"
  type        = string
  default     = "zhaho"  # Change this if needed
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

