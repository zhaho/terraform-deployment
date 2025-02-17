resource "null_resource" "remote_provision" {
  for_each = { for vm in var.vms : vm.name => vm }

  depends_on = [module.vms]

  connection {
    type        = "ssh"
    user        = "zhaho"
    private_key = file("~/.ssh/id_rsa")
    host        = trimsuffix(each.value.static_ip, "/24")
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'SSH connection successful on $(hostname)'",
      "sudo apt update && sudo apt install -y python3 software-properties-common",
      "sudo add-apt-repository --yes --update ppa:ansible/ansible",
      "sudo apt install ansible -y",
      "ansible-pull -U https://github.com/zhaho/ansible-deployment.git management.yml"
    ]
  }
}
