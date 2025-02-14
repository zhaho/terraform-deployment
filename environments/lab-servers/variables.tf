variable "target_node" { default = "proxmox" }
variable "vm_name" { default = "lab-vm" }
variable "vm_cores" { default = 2 }
variable "vm_memory" { default = 4096 }
variable "vm_disk_size" { default = 20 }
variable "vm_network_bridge" { default = "vmbr0" }
variable "vm_static_ip" { default = "10.4.5.30/24" }
variable "vm_gateway" { default = "10.4.5.1" }


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
