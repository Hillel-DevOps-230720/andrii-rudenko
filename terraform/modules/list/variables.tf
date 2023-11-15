variable "name" {
  type        = string
  default     = ""
}

variable "entries" {
  type = list(string)
  default = []
}
