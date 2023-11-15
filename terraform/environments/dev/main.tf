provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

data "aws_ami" "app" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "tag:target"
    values = ["app"]
  }
}

data "aws_ami" "db" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "tag:target"
    values = ["db"]
  }
}

locals {
  name = "${var.project}-${var.environment}"
}

module "vpc" {
  source         = "../../modules/vpc"
  name           = local.name
  cidr           = "10.0.0.0/16"
  public_subnets = ["10.0.1.0/24"]
  private_subnet = "10.0.2.0/24"
}

module "list" {
  source  = "../../modules/list"
  name    = "${local.name}-trusted"
  entries = ["45.84.92.138/32", "46.150.23.139/32"]
}

module "groups" {
  source  = "../../modules/groups"
  name    = local.name
  vpc_id  = module.vpc.id
  trusted = module.list.id
}

module "db" {
  source          = "../../modules/db"
  name            = local.name
  aws_key         = var.aws_key
  type            = "t2.micro"
  aws_iam_profile = var.aws_iam_profile
  ami_id          = data.aws_ami.db.id
  subnet_id       = module.vpc.private_id
  groups_ids      = [module.groups.private_id]
}

module "app" {
  source          = "../../modules/app"
  name            = local.name
  aws_key         = var.aws_key
  type            = "t2.micro"
  aws_iam_profile = var.aws_iam_profile
  ami_id          = data.aws_ami.app.id
  subnets_ids     = module.vpc.public_ids
  groups_ids      = [module.groups.public_id]
  depends_on      = [module.db.instance]
}

resource "local_file" "ansible" {
  content = templatefile("../../files/template.tpl", {
    app_public_ip = module.app.public_ip,
    app_hosts     = module.app.hosts,
    db_private_ip = module.db.private_ip
    db_host       = module.db.host,
  })
  filename = "./dev.hosts"
  # lifecycle {
  #   prevent_destroy = true
  # }
}
