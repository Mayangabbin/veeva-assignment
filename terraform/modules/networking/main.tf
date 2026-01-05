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

  tags = {
    Name = "${var.prefix}-igw"
  }
}

# Public subnets
resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.prefix}-public-${each.key}"
    kubernetes.io/role/elb = 1
    kubernetes.io/cluster/${var.cluster_name} = shared

  }
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.prefix}-public-rt"
  }
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

  tags = {
    Name = "${var.prefix}-nat-eip-${each.key}"
  }
}

# NAT Gateway in public subnets
resource "aws_nat_gateway" "nat" {
  for_each = var.public_subnets

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = {
    Name = "${var.prefix}-nat-gateway-${each.key}"
  }
}

# Private app subnets
resource "aws_subnet" "private_app" {
  for_each = var.private_app

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = {
    Name = "${var.prefix}-private-app-${each.key}"
    Tier = "application"
    kubernetes.io/role/internal-elb = 1
    kubernetes.io/cluster/${var.cluster_name}- = "shared"
  }
}

# App private route tables
resource "aws_route_table" "private_app" {
  for_each = var.private_app
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-private-app-rt-${each.key}"
  }
}

# Routes to NAT Gateways
resource "aws_route" "private_nat" {
  for_each = var.private_app

  route_table_id         = aws_route_table.private_app[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[each.key].id
}

# Associate app private subnets with app private route tables
resource "aws_route_table_association" "private_app" {
  for_each = var.private_app

  subnet_id      = aws_subnet.private_app[each.key].id
  route_table_id = aws_route_table.private_app[each.key].id
}

# Private DB subnets
resource "aws_subnet" "private_db" {
  for_each = var.private_db

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = {
    Name = "${var.prefix}-private-db-${each.key}"
    Tier = "database"
  }
}

# DB private route table
resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-private-db-route-table"
  }
}

resource "aws_route_table_association" "private_db" {
  for_each = var.private_db

  subnet_id      = aws_subnet.private_db[each.key].id
  route_table_id = aws_route_table.private_db.id
}

