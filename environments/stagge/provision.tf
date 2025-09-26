resource "null_resource" "remote_provision" {
  for_each = { for vm in var.vms : vm.name => vm }

  depends_on = [module.vms]

  connection {
    type        = "ssh"
    user        = var.host_user
    host        = split("/", each.value.static_ip)[0]
    private_key = file("~/.ssh/id_rsa")
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",  
      "ansible-pull -U https://github.com/zhaho/ansible-deployment.git -e host_user=zhaho zsh.yml -vvv"
    ]
  }
}
