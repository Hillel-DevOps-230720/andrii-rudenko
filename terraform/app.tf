data "aws_ami" "app" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "tag:target"
    values = ["app"]
  }

}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.app.id
  key_name               = var.key
  instance_type          = var.type
  subnet_id              = aws_subnet.public.id
  iam_instance_profile   = var.profile
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.public.id]
  tags = {
    Name    = "app"
    project = var.project
  }
  depends_on = [aws_instance.db]
}
