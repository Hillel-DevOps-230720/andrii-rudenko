resource "aws_instance" "this" {
  ami                         = var.ami_id
  key_name                    = var.aws_key
  instance_type               = var.type
  subnet_id                   = var.subnet_id
  iam_instance_profile        = var.aws_iam_profile
  associate_public_ip_address = true
  vpc_security_group_ids      = var.groups_ids
  tags = {
    Name = "${var.name}-db"
  }
}
