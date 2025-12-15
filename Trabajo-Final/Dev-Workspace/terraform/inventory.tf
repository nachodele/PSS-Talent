data "template_file" "ansible_inventory" {
  template = file("${path.module}/templates/inventory.tpl")

  vars = {
    instance_public_ip = aws_instance.pr_instance.public_ip
  }
}

resource "local_file" "ansible_inventory" {
  content  = data.template_file.ansible_inventory.rendered
  filename = "${path.module}/../ansible/inventory"
}
