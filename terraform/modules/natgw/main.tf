resource "aws_eip" "nat" {
  vpc = true

  tags = merge(
    var.tags,
    {
      Name = "nat-eip"
    }
  )
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = var.public_subnet_id

  tags = merge(
    var.tags,
    {
      Name = "ai-platformnat-gateway"
    }
  )
}

# create a default route in each private route table that points to the NAT gateway
resource "aws_route" "private_internet" {
  for_each = toset(var.private_route_table_ids)

  route_table_id         = each.key
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}
