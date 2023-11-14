data "aws_ami" "db" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "tag:target"
    values = ["db"]
  }
}

resource "aws_instance" "db" {
  ami                    = data.aws_ami.db.id
  key_name               = var.key
  instance_type          = var.type
  subnet_id              = aws_subnet.private.id
  iam_instance_profile   = var.profile
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.private.id]
  tags = {
    Name    = "db"
    project = var.project
  }
}
