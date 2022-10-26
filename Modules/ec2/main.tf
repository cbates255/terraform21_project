# resource "aws_instance" "bastion" {
#   ami                         = var.ami_id
#   instance_type               = var.instance_type
#   associate_public_ip_address = true
#   key_name                    = var.key_name
#   security_groups             = [var.pubsg_name]
# }

# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "asg_project_attachment" {
  autoscaling_group_name = aws_autoscaling_group.projectASGgroup.name
  lb_target_group_arn    = var.targetARN
}

resource "aws_launch_template" "project" {
  name_prefix   = "project"
  image_id      = var.ami_id
  instance_type = var.instance_type
  user_data = <<EOF
    !/bin/bash
    sudo yum update -y
    sudo yum upgrade -y
    sudo yum install httpd -y
    sudo systemctl enable httpd
    sudo systemctl start httpd
  EOF
}

resource "aws_autoscaling_group" "projectASGgroup" {
  availability_zones = var.listedAZs
  desired_capacity   = 2
  max_size           = 5
  min_size           = 2

  launch_template {
    id      = aws_launch_template.project.id
    version = "$Latest"
  }
}