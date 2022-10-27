# --- ec2/outputs.tf

output "asgid" {
  value = aws_autoscaling_group.projectASGgroup.id
}