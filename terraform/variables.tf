data "aws_ssm_parameter" "main" { name = "/hillel/cidr/main" }
data "aws_ssm_parameter" "public" { name = "/hillel/cidr/public" }
data "aws_ssm_parameter" "private" { name = "/hillel/cidr/public/private" }
data "aws_ssm_parameter" "ssh" { name = "/hillel/ssh/port" }
data "aws_ssm_parameter" "http" { name = "/hillel/app/port" }
data "aws_ssm_parameter" "primary" { name = "/hillel/trusted/primary/name" }
data "aws_ssm_parameter" "primary_ip" { name = "/hillel/trusted/primary/ip" }
data "aws_ssm_parameter" "secondary" { name = "/hillel/trusted/secondary/name" }
data "aws_ssm_parameter" "secondary_ip" { name = "/hillel/trusted/secondary/ip"}

locals {
  cidr = {
    all     = "0.0.0.0/0"
    main    = data.aws_ssm_parameter.main.value
    public  = data.aws_ssm_parameter.public.value
    private = data.aws_ssm_parameter.private.value
  }
}

variable "cidr" {
  type = map(any)
  default = {
    "all"     = "0.0.0.0/0"
    "main"    = "10.0.0.0/16"
    "public"  = "10.0.1.0/24"
    "private" = "10.0.2.0/24"
  }
}

variable "ports" {
  type = map(any)
  default = {
    "ssh"  = "22"
    "http" = "8000"
  }
}

variable "trusted" {
  type = list(string)
  default = [
    "45.84.92.138/32",
    "46.150.23.139/32"
  ]
}

variable "project" {
  type    = string
  default = "hillel"
}

variable "type" {
  type    = string
  default = "t2.micro"
}

variable "key" {
  type    = string
  default = "awscli-key"
}

variable "profile" {
  type    = string
  default = "awscli-full-access"
}
