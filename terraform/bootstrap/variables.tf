variable "aws_profile" {
  type    = string
  default = "terraform"
}

variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "project" {
  type    = string
  default = "hillel"
}

variable "environment" {
  type    = string
  default = "bootstrap"
}
