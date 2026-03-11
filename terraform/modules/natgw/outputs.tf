output "nat_gateway_id" {
  description = "ID of the NAT gateway"
  value       = aws_nat_gateway.this.id
}

output "eip_allocation_id" {
  description = "Allocation ID of the EIP attached to the NAT gateway"
  value       = aws_eip.nat.id
}