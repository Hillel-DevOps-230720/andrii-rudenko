resource "aws_vpc" "main" {
  cidr_block = local.cidr["main"]
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = local.cidr["public"]
  tags = {
    Name = "public"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = local.cidr["private"]
  tags = {
    Name = "private"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main"
  }
}

resource "aws_default_route_table" "main" {
  default_route_table_id = aws_vpc.main.default_route_table_id
  route {
    cidr_block = local.cidr["all"]
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "main"
  }
}

resource "aws_ec2_managed_prefix_list" "trusted" {
  name           = "trusted"
  address_family = "IPv4"
  max_entries    = 2
}

resource "aws_ec2_managed_prefix_list_entry" "entry" {
  for_each       = toset(var.trusted)
  cidr           = each.key
  # description    = each.value
  prefix_list_id = aws_ec2_managed_prefix_list.trusted.id
}

resource "aws_security_group" "public" {
  name        = "public"
  description = "ssh trusted, http trusted, private all"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port    = 0
    to_port      = 0
    protocol     = "-1"
     cidr_blocks = [local.cidr["all"]]
  }
}

resource "aws_security_group_rule" "ingress" {
  type              = "ingress"
  for_each          = var.ports
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  prefix_list_ids   = [aws_ec2_managed_prefix_list.trusted.id]
  security_group_id = aws_security_group.public.id
}


resource "aws_security_group" "private" {
  name        = "private"
  description = "public all"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port    = 0
    to_port      = 0
    protocol     = "-1"
     cidr_blocks = [local.cidr["all"]]
  }
}

resource "aws_security_group_rule" "public_alllow_private" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.public.id
  source_security_group_id = aws_security_group.private.id
}

resource "aws_security_group_rule" "private_allow_public" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.private.id
  source_security_group_id = aws_security_group.public.id
}
