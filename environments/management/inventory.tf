resource "local_file" "ansible_inventory" {
  content  = local.inventory_content
  filename = "${path.module}/inventory"
}
