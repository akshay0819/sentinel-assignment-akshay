output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  value = try(aws_subnet.public[*].id, [])
}

output "vpc_cidr_block" {
  value = aws_vpc.vpc.cidr_block
}

output "private_route_table_ids" {
  value = [aws_route_table.private_rt.id]
}

output "nat_gateway_id" {
  value = try(aws_nat_gateway.nat[0].id, null)
}

output "nat_eip" {
  value = try(aws_eip.nat[0].public_ip, null)
}