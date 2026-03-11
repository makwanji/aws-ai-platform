output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_compute_subnet_ids" {
  description = "List of private compute subnet IDs"
  value       = aws_subnet.private_compute[*].id
}

output "private_control_subnet_ids" {
  description = "List of private control subnet IDs"
  value       = aws_subnet.private_control[*].id
}

output "storage_subnet_ids" {
  description = "List of storage subnet IDs"
  value       = aws_subnet.storage[*].id
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.this.id
}

output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = aws_route_table.private[*].id
}
