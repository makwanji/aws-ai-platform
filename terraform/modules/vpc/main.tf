resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name = "ai-platform-vpc"
    }
  )
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = "ai-platform-igw"
    }
  )
}

# Public subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "public-subnet-${count.index + 1}"
      Type = "Public"
    }
  )
}

# Private compute subnets
resource "aws_subnet" "private_compute" {
  count = length(var.private_compute_subnets)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_compute_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name = "private-compute-subnet-${count.index + 1}"
      Type = "Private-Compute"
    }
  )
}

# Private control subnets
resource "aws_subnet" "private_control" {
  count = length(var.private_control_subnets)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_control_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name = "private-control-subnet-${count.index + 1}"
      Type = "Private-Control"
    }
  )
}

# Storage subnets
resource "aws_subnet" "storage" {
  count = length(var.storage_subnets)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.storage_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name = "storage-subnet-${count.index + 1}"
      Type = "Storage"
    }
  )
}

# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(
    var.tags,
    {
      Name = "public-rt"
    }
  )
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private route tables (one per AZ for NAT, but since no NAT specified, just create RTs)
resource "aws_route_table" "private" {
  count = length(var.availability_zones)

  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = "private-rt-${count.index + 1}"
    }
  )
}

resource "aws_route_table_association" "private_compute" {
  count = length(aws_subnet.private_compute)

  subnet_id      = aws_subnet.private_compute[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "private_control" {
  count = length(aws_subnet.private_control)

  subnet_id      = aws_subnet.private_control[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "storage" {
  count = length(aws_subnet.storage)

  subnet_id      = aws_subnet.storage[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
