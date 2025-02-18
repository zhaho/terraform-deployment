resource "null_resource" "remote_provision" {
  for_each = { for vm in var.vms : vm.name => vm }

  depends_on = [module.vms]

  connection {
    type        = "ssh"
    user        = var.host_user
    private_key = file("~/.ssh/id_rsa")
    host        = trimsuffix(each.value.static_ip, "/24")
  }

  provisioner "remote-exec" {
    inline = [
      # Setup ZSH
      "ansible-galaxy install viasite-ansible.zsh --force",
      "ansible-pull -U https://github.com/zhaho/ansible-deployment.git -e host_user=${var.host_user} zsh.yml"
    ]
  }
}
