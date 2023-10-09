data "amazon-parameterstore" "db_name" { name = "/hillel/db/name" }
data "amazon-parameterstore" "db_user" { name = "/hillel/db/user" }
data "amazon-parameterstore" "db_password" { name = "/hillel/db/password" }
data "amazon-parameterstore" "db_ip_local" { name = "/hillel/db/ip/local" }
data "amazon-parameterstore" "app_key" { name = "/hillel/app/key" }
data "amazon-parameterstore" "app_port" { name = "/hillel/app/port" }
data "amazon-parameterstore" "app_url" { name = "/hillel/app/url" }
data "amazon-parameterstore" "s3_name" { name = "/hillel/s3/name" }

locals {
  db_name     = data.amazon-parameterstore.db_name.value
  db_user     = data.amazon-parameterstore.db_user.value
  db_password = data.amazon-parameterstore.db_password.value
  db_ip_local = data.amazon-parameterstore.db_ip_local.value
  app_key     = data.amazon-parameterstore.app_key.value
  app_port    = data.amazon-parameterstore.app_port.value
  app_url     = data.amazon-parameterstore.app_url.value
  s3_name     = data.amazon-parameterstore.s3_name.value
}

variable "project" {
  type    = string
  default = "hillel"
}

variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "type" {
  type    = string
  default = "t2.micro"
}

variable "user" {
  type    = string
  default = "ubuntu"
}

variable "timeout" {
  type    = string
  default = "10m"
}

variable "profile" {
  type    = string
  default = "awscli-full-access"
}
