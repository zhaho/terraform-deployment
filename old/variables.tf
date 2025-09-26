#Global Variables

# Proxmox
variable "pm_api_url" {}
variable "pm_api_token_id" {}
variable "pm_api_token_secret" {}
variable "target_node" { default = "proxmox" }

# Proxmox VM Settings
variable "vm_network_bridge" { default = "vmbr0" } 