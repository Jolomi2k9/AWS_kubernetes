# --- networking/output.tf ---

output "vpc_id" {
  value = aws_vpc.production_vpc.id
}

output "public_subnets" {
  value = aws_subnet.public_subnet.*.id
}

output "private_subnets" {
  value = aws_subnet.private_subnet.*.id
}

output "public_sg" {
  value = aws_security_group.sg["public"].id
}

# output "rds_sg" {
#   value = aws_security_group.sg["rds"].id
# }

output "alb_sg" {
  value = aws_security_group.sg["loadbalancer"].id
}

output "db_subnet_group_name" {
  value = aws_db_subnet_group.rds_subnetgroup.*.name
}

output "db_security_group" {
  value = aws_security_group.sg["rds"].id
}


