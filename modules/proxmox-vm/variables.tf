variable "target_node" {}
variable "vm_name" {}
variable "vm_cores" { default = 2 }
variable "vm_memory" { default = 4096 }
variable "vm_disk_size" { default = 20 }
variable "vm_network_bridge" { default = "vmbr0" }
variable "vm_static_ip" {}
variable "vm_gateway" {}
variable "vm_datastore" { default = "local-lvm" }
variable "template_id" {}
