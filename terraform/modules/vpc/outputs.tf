output "id" {
  value = try(aws_vpc.this[0].id, null)
}

output "cidr" {
  value = try(aws_vpc.this[0].cidr_block, null)
}

output "public_ids" {
  value = aws_subnet.public[*].id
}

output "public_blocks" {
  value = compact(aws_subnet.public[*].cidr_block)
}

output "private_id" {
  value = aws_subnet.private.id
}

output "private_block" {
  value = aws_subnet.private.cidr_block
}
