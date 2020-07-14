locals {
  enabled          = var.enable_load_testing ? 4 : 0
  artillery_config = file("${path.module}/api_load_test.yml")
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_instance" "web" {
  count                  = local.enabled
  ami                    = "ami-04122be15033aa7ec"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.example.id]

  tags = {
    Name = "load_testing_instance"
  }

  user_data = <<EOF
#!/bin/bash
curl --silent --location https://rpm.nodesource.com/setup_12.x | bash -
yum -y install nodejs
echo ==============
export TARGET_URL=${var.api_url}
export API_KEY=${var.api_key}
echo $TARGET_URL
echo $API_KEY
npm install -g artillery --allow-root --unsafe-perm=true
touch /etc/api_load_test.yml | echo ${local.artillery_config} >> /etc/api_load_test.yml
artillery run /etc/api_load_test.yml
EOF
}

resource "aws_security_group" "example" {
  name = "${var.prefix}-load-test-security-group"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    # To keep this example simple, we allow incoming SSH requests from any IP. In real-world usage, you should only
    # allow SSH requests from trusted servers, such as a bastion host or VPN server.
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${aws_default_vpc.default.id}"
}
