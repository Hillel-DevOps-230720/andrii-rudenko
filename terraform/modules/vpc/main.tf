locals {
  len_public_subnets = length(var.public_subnets)
}

resource "aws_vpc" "this" {
  count                = var.create_vpc ? 1 : 0
  cidr_block           = var.cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
  tags = {
    Name = var.name
  }
}

locals {
  create_public_subnets = var.create_vpc && local.len_public_subnets > 0
}

resource "aws_subnet" "public" {
  count      = local.create_public_subnets ? local.len_public_subnets : 0
  vpc_id     = aws_vpc.this[0].id
  cidr_block = element(concat(var.public_subnets, [""]), count.index)
  tags = {
    Name = format("${var.name}-public-%s", count.index + 1)
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.this[0].id
  cidr_block = var.private_subnet
  tags = {
    Name = "${var.name}-private"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this[0].id
  tags = {
    Name = var.name
  }
}

resource "aws_default_route_table" "this" {
  default_route_table_id = aws_vpc.this[0].default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = {
    Name = var.name
  }
}
