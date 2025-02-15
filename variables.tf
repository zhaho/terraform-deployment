#Global Variables

# Proxmox
variable "pm_api_url" {}
variable "pm_api_token_id" {}
variable "pm_api_token_secret" {}
variable "target_node" { default = "proxmox" }

# Proxmox VM Settings
variable "cloud_init_image" { default = "ubuntu-2404-ci-template" } # Cloud Init Image
variable "vm_network_bridge" { default = "vmbr0" } 