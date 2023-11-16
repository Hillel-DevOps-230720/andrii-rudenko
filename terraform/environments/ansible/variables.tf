variable "aws_profile" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "aws_key" {
  type    = string
  default = "awscli-key"
}

variable "aws_iam_profile" {
  type    = string
  default = "awscli-full-access"
}

variable "project" {
  type = string
}

variable "environment" {
  type = string
}
