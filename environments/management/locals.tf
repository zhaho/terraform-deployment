locals {
  inventory_content = <<EOF
[vms]
%{ for vm in var.vms ~}
${split("/", vm.static_ip)[0]} ansible_host=${split("/", vm.static_ip)[0]} ansible_user=zhaho ansible_ssh_extra_args="-o StrictHostKeyChecking=no -o ConnectTimeout=30"
%{ endfor ~}
EOF
}
