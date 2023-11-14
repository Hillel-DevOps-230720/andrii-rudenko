# data "aws_ssm_parameter" "main" { name = "/hillel/cidr/main" }
# data "aws_ssm_parameter" "public" { name = "/hillel/cidr/public" }
# data "aws_ssm_parameter" "private" { name = "/hillel/cidr/public/private" }
# data "aws_ssm_parameter" "ssh" { name = "/hillel/ssh/port" }
# data "aws_ssm_parameter" "http" { name = "/hillel/app/port" }
# data "aws_ssm_parameter" "primary" { name = "/hillel/trusted/primary/name" }
# data "aws_ssm_parameter" "primary_ip" { name = "/hillel/trusted/primary/ip" }
# data "aws_ssm_parameter" "secondary" { name = "/hillel/trusted/secondary/name" }
# data "aws_ssm_parameter" "secondary_ip" { name = "/hillel/trusted/secondary/ip"}

variable "create_vpc" {
  type        = bool
  default     = true
}

variable "name" {
  type        = string
  default     = ""
}

variable "cidr" {
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_dns_hostnames" {
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  type        = bool
  default     = true
}

variable "public_subnets" {
  type        = list(string)
  default     = []
}

variable "private_subnet" {
  type        = string
  default     = ""
}
