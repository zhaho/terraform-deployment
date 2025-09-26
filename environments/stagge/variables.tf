# Environment: stagge
# Generated on: Fri Sep 26 06:39:28 AM UTC 2025

# Proxmox provider variables
variable "pm_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "pm_api_token_id" {
  description = "Proxmox API token ID"
  type        = string
}

variable "pm_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "target_node" {
  description = "Proxmox node to deploy VMs on"
  type        = string
  default     = "proxmox"
}

variable "host_user" {
  description = "The SSH user for connecting to the remote host"
  type        = string
  default     = "zhaho"  # Change this if needed
}

variable "vm_network_bridge" {
  description = "Network bridge for VMs"
  type        = string
  default     = "vmbr0"
}

# Environment-specific IPAM override (null = use global setting)
variable "enable_ipam" {
  description = "Enable IPAM integration for this environment (overrides global setting)"
  type        = bool
  default     = null
}

# VM definitions
variable "vms" {
  description = "List of VMs to create"
  type = list(object({
    name      = string
    cores     = number
    memory    = number
    disk_size = number
    static_ip = string
    gateway   = string
    subnet_id = string  # IPAM subnet ID for this VM's network
  }))
  
  default = [
    {
      name      = "stagge01"
      cores     = 2
      memory    = 4096
      disk_size = 20
      static_ip = "10.4.5.2/24"
      gateway   = "10.4.5.1"
      subnet_id = "7"
    }
  ]
}
