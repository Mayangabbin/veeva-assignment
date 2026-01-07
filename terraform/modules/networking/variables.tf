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

variable "availability_zones_config" {
  description = "Map of AZs to CIDR blocks"
  type = map(object({
    public_cidr      = string
    private_app_cidr = string
    private_db_cidr  = string
  }))
}

variable "tags" {
  type    = map(string)
  default = {}
}
