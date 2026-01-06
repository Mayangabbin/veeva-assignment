variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "vpc_security_group_ids" {
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

variable "db_password" {
  type      = string
  sensitive = true
}

variable "engine" {
  type    = string
  default = "postgres"
}

variable "engine_version" {
  type    = string
  default = "15.3"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "tags" {
  type    = map(string)
  default = {}
}
