locals {
  enabled = var.enable_load_testing ? 4 : 0
}

resource "aws_instance" "web" {
  count         = local.enabled
  ami           = "ami-04122be15033aa7ec"
  instance_type = "t2.micro"

  tags = {
    Name = "load_testing_instance"
  }

  provisioner "file" {
    source      = "${path.module}/api_load_test.yml"
    destination = "/etc/api_load_test.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "yum install node",
      "export TARGET_URL=${var.api_url}",
      "export API_KEY=${var.api_key}",
      "npm i -g artillery",
      "artillery run /etc/api_load_test.yml"
    ]
  }
}
