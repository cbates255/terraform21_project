# --- network/outputs.tf


output "pubsg_name" {
  value = aws_security_group.public_SG.name
}

output "privsubid" {
  value = aws_subnet.privsub[*].id
}

output "vpc_id" {
  value = aws_vpc.projectVPC.id
}

output "listedAZs" {
  value = var.azs
}

output "privSG_id" {
  value = aws_security_group.private_SG.id
}