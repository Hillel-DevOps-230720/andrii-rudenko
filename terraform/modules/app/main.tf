locals {
  count = var.instance_count > length(var.subnets_ids) ? length(var.subnets_ids) : var.instance_count
  # depencies = var.depencies
}

resource "aws_instance" "this" {
  count                       = local.count
  ami                         = var.ami_id
  key_name                    = var.aws_key
  instance_type               = var.type
  subnet_id                   = var.subnets_ids[count.index]
  iam_instance_profile        = var.aws_iam_profile
  associate_public_ip_address = true
  vpc_security_group_ids      = var.groups_ids
  tags = {
    Name = format("${var.name}-app-%s", count.index + 1)
  }
}
