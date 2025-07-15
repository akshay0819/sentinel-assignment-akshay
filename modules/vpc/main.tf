resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${var.name}-vpc"
  })
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(var.tags, {
    Name = "${var.name}-private-subnet-${count.index + 1}"
  })
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name}-public-subnet-${count.index + 1}"
  })
}

resource "aws_internet_gateway" "igw" {
  count  = length(var.public_subnet_cidrs) > 0 ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  tags = merge(var.tags, {
    Name = "${var.name}-igw"
  })
}

resource "aws_route_table" "public_rt" {
  count  = length(var.public_subnet_cidrs) > 0 ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[0].id
  }

  tags = merge(var.tags, {
    Name = "${var.name}-public-rt"
  })
}

resource "aws_route_table_association" "public_association" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt[0].id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(var.tags, {
    Name = "${var.name}-private-rt"
  })
}

resource "aws_route_table_association" "private_association" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_rt.id
}