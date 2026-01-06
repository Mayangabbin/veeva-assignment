# VPC
resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support = true

  tags ={
    Name = "${var.prefix}-vpc" 
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name = "${var.prefix}-vpc"
    },
    var.tags
  )
}

# Public subnets
resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name = "${var.prefix}-public-${each.key}"
      "kubernetes.io/role/elb" = 1
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    },
    var.tags
  )
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    {
      Name = "${var.prefix}-public-rt"
    },
    var.tags
  )
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public_assoc" {
  for_each = var.public_subnets

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

# Elastic IP for NAT Gateways
resource "aws_eip" "nat" {
  for_each = var.public_subnets
  vpc = true

  tags = merge(
    {
      Name = "${var.prefix}-nat-eip-${each.key}"
    },
    var.tags
  )
}

# NAT Gateway in public subnets
resource "aws_nat_gateway" "nat" {
  for_each = var.public_subnets

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = merge(
    {
      Name = "${var.prefix}-nat-gateway-${each.key}"
    },
    var.tags
  )
}

# Private app subnets
resource "aws_subnet" "private_app" {
  for_each = var.private_app_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = merge(
    {
      Name = "${var.prefix}-private-app-${each.key}"
      Tier = "application"
      "kubernetes.io/role/internal-elb" = 1
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    },
    var.tags
  )
}

# App private route tables
resource "aws_route_table" "private_app" {
  for_each = var.private_app_subnets
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name = "${var.prefix}-private-app-rt-${each.key}"
    },
    var.tags
  )
}

# Routes to NAT Gateways
resource "aws_route" "private_nat" {
  for_each = var.private_app_subnets

  route_table_id         = aws_route_table.private_app[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[each.key].id
}

# Associate app private subnets with app private route tables
resource "aws_route_table_association" "private_app" {
  for_each = var.private_app_subnets

  subnet_id      = aws_subnet.private_app[each.key].id
  route_table_id = aws_route_table.private_app[each.key].id
}

# Private DB subnets
resource "aws_subnet" "private_db" {
  for_each = var.private_db_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = merge(
    {
      Name = "${var.prefix}-private-db-${each.key}"
      Tier = "database"
    },
    var.tags
  )
}

# DB private route table
resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name = "${var.prefix}-private-db-route-table"
    },
    var.tags
  )
}

resource "aws_route_table_association" "private_db" {
  for_each = var.private_db_subnets

  subnet_id      = aws_subnet.private_db[each.key].id
  route_table_id = aws_route_table.private_db.id
}

