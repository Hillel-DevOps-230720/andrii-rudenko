output "public_id" {
  value = aws_security_group.public.id
}

output "private_id" {
  value = aws_security_group.private.id
}
