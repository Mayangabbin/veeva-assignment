# AWS region
variable "region" {
  type    = string
  default = "eu-central-1"
}

# Availability Zones
variable "azs" {
  type    = list(string)
  default = ["eu-central-1a", "eu-central-1b"]
}

# Prefix for naming
variable "prefix" {
  type    = string
  default = "veeva"
}

# Environment name
variable "environment" {
  type    = string
  default = "prod"
}

# VPC CIDR
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

# Subnet CIDRs per AZ
variable "public_subnets" {
  type = map(string)
  default = {
    "eu-central-1a" = "10.0.1.0/24"
    "eu-central-1b" = "10.0.2.0/24"
  }
}

variable "private_app_subnets" {
  type = map(string)
  default = {
    "eu-central-1a" = "10.0.10.0/24"
    "eu-central-1b" = "10.0.11.0/24"
  }
}

variable "private_db_subnets" {
  type = map(string)
  default = {
    "eu-central-1a" = "10.0.20.0/24"
    "eu-central-1b" = "10.0.21.0/24"
  }
}

# Apps to deploy
variable "apps" {
  type = map(object({
    image = string
    port  = number
  }))
  default = {
    frontend = {
      image = "veeva/frontend:latest"
      port  = 80
    }
    backend = {
      image = "veeva/backend:latest"
      port  = 8080
    }
    datastream = {
      image = "veeva/datastream:latest"
      port  = 9090
    }
  }
}

# Number of replicas per deployment
variable "replicas" {
  type    = number
  default = 2
}


variable "db_username" {
  type    = string
  default = "admin"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.medium"
}
