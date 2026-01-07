variable "prefix" {
  type = string
}

variable "enironment"{
  type = string
}
variable "tags" {
  type    = map(string)
  default = {}
}
