variable "cidr_block" {
  type = string
}

variable "public_subnets" {
  type = map(string)
}

variable "private_app_subnets" {
  type = map(string)
}

variable "private_db_subnets" {
  type = map(string)
}

variable "cluster_name" {
  type = string
}

variable "prefix" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
