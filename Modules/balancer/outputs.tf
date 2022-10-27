# --- balancer/outputs.tf


output "targetARN" {
  value = aws_lb_target_group.projectTARGETgroup.arn
}

output "albarn" {
  value = aws_lb.projectLB.arn
}