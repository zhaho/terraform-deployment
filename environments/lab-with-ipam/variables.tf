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
    subnet_id      = string  # IPAM subnet ID for this VM
  }))
  default = [
    {
      name      = "lab-ipam01"
      cores     = 2
      memory    = 4096
      disk_size = 20
      static_ip = "10.4.5.177/24"
      gateway   = "10.4.5.1"
      subnet_id = "7"  # 10.4.5.x network subnet ID
    }
  ]
}

variable "host_user" {
  description = "The SSH user for connecting to the remote host"
  type        = string
  default     = "zhaho"  # Change this if needed
}

# Proxmox API variables
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

# IPAM configuration is centralized in root ipam-config.tf
# No IPAM variables needed here - everything comes from root module

variable "enable_ipam" {
  description = "Enable IPAM integration for this environment (overrides global setting)"
  type        = bool
  default     = null  # null means use global setting from root
}
