output "public_ip" {
  value = aws_instance.this[*].public_ip
}

output "hosts" {
  value = aws_instance.this[*].tags["Name"]
}
