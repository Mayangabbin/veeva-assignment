variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "nodes_sg_ids" {
  type = list(string)
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "engine" {
  type    = string
}

variable "engine_version" {
  type    = string
}

variable "db_instance_class" {
  type    = string
}

variable "allocated_storage" {
  type    = number
}

variable "tags" {
  type    = map(string)
  default = {}
}
