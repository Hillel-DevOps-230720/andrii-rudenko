output "private_ip" {
  value = aws_instance.this.private_ip
}

output "instance" {
  value = aws_instance.this
}

output "host" {
  value = aws_instance.this.tags["Name"]
}
