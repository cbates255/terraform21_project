data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amazon/amzn2-ami-kernel-5.10-hvm-2.0.20221004.0-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"]
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  associate_public_ip_address = true
  key_name                    = var.key_name
  security_groups             = var.pubsg_id
}

resource "aws_instance" "app_server" {
  ami                         = var.image_ami
  instance_type               = var.instance_type
  associate_public_ip_address = true
  key_name                    = var.key_name
  security_groups             = [var.sg_id]
  iam_instance_profile        = var.profile
  user_data                   = <<EOF
  #!/bin/bash
  sudo yum update -y
  sudo yum upgrade -y
  sudo yum install httpd -y
  sudo systemctl enable httpd
  sudo systemctl start httpd
  EOF
  tags = {
    Name = var.tags
  }
}

resource "aws_launch_template" "project_launch" {
  name = "project_launch"

  image_id = data.aws_ami.amazon_linux.id

  instance_type = var.instance_type

  key_name = var.key_name

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = true
  }

  placement {
    availability_zone = var.listedAZs
  }

  ram_disk_id = "test"

  vpc_security_group_ids = ["sg-12345678"]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "test"
    }
  }

  user_data = filebase64("${path.module}/example.sh")
}

