
resource "aws_ec2" "load_test_machine_thing" {
  provisioner "file" {
    source      = data.template_file.api_gateway_template.filename
    destination = "/tmp/apiGateway.yml"
  }

  provisioner "remote-exec" {
    inline      = ["artillery run -o thing.json /tmp/apiGateway.yml", "cat thing.json"]
  }
}

data "template_file" "api_gateway_template" {
  template = file("${path.module}/apiGateway.yml.tpl")
  vars = {
    target_url = var.api_url
    api_key = var.api_key
  }
}

variable "api_key" {
  type = string
}

variable "api_url" {
  type = string
}

variable "prefix" {
  type = string
}
