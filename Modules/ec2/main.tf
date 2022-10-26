data "aws_ami_ids" "linux" {
  owners = ["137112412989"]

  filter {
    name   = "name"
    values = ["amazon/amzn2-ami-kernel-5.10-hvm-2.0.20221004.0-x86_64-gp2"]
  }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami_ids.linux.id
  instance_type               = var.instance_type
  associate_public_ip_address = true
  key_name                    = var.key_name
  security_groups             = [var.pubsg_id]
}

resource "aws_launch_template" "project_launch" {
  name = "project_launch"

  image_id = data.aws_ami_ids.linux.id

  instance_type = var.instance_type

  key_name = var.key_name

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = true
  }

  vpc_security_group_ids = [var.sg_id]

  tag_specifications {

    tags = {
      Name = var.tag
    }
  }

  user_data = <<EOF
  #!/bin/bash
  sudo yum update -y
  sudo yum upgrade -y
  sudo yum install httpd -y
  sudo systemctl enable httpd
  sudo systemctl start httpd
  EOF
}

resource "aws_placement_group" "projectplacement" {
  name     = "project"
  strategy = "cluster"
}

resource "aws_autoscaling_group" "project_ASG" {
  name                      = "project_ASG"
  max_size                  = 5
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  force_delete              = true
  placement_group           = aws_placement_group.projectplacement.id
  availability_zones        = [var.listedAZs]
  launch_template {
    name = aws_launch_template.project_launch.name
  }
}

# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "asg_project_attachment" {
  autoscaling_group_name = aws_autoscaling_group.project_ASG.name
  lb_target_group_arn    = var.targetARN
}

resource "aws_autoscaling_policy" "scalepolicy" {
  name                   = "scalepolicy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.project_ASG.name
  policy_type            = "PredictiveScaling"
  predictive_scaling_configuration {
    metric_specification {
      target_value = 50
      predefined_load_metric_specification {
        predefined_metric_type = "ASGTotalCPUUtilization"
        resource_label         = "project"
      }
    }
  }
}  