locals {
  entries     = var.entries
  create_list = length(var.entries) > 0
}

resource "aws_ec2_managed_prefix_list" "this" {
  count          = local.create_list ? 1 : 0
  name           = var.name
  address_family = "IPv4"
  max_entries    = length(local.entries)

  dynamic "entry" {
    for_each = local.entries
    content {
      cidr = entry.value
    }
  }
}
