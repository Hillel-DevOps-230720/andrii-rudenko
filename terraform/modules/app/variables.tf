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

variable "instance_count" {
  type    = number
  default = 1
}

variable "ami_id" {
  type    = string
  default = null
}

variable "subnets_ids" {
  type    = list(string)
  default = []
}

variable "groups_ids" {
  type    = list(string)
  default = []
}

# variable "depencies" {
#   type    = list(string)
#   default = []
# }
