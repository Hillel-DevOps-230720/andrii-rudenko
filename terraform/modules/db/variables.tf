variable "name" {
  type    = string
  default = ""
}

variable "aws_key" {
  type    = string
  default = ""
}

variable "type" {
  type    = string
  default = ""
}

variable "aws_iam_profile" {
  type    = string
  default = ""
}

variable "ami_id" {
  type    = string
  default = null
}

variable "subnet_id" {
  type    = string
  default = null
}

variable "groups_ids" {
  type    = list(string)
  default = []
}
