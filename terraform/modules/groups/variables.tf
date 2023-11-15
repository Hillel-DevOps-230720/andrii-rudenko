variable "name" {
  type        = string
  default     = ""
}

variable "vpc_id" {
  type        = string
  default     = null
}

variable "ports" {
  type = map(any)
  default = {
    "ssh"  = "22"
    "http" = "8000"
  }
}

variable "trusted" {
  type        = string
  default     = null
}
