# AWS region
variable "region" {
  type    = string
}

# Availability Zones
variable "azs" {
  type    = list(string)
}

# Prefix for naming
variable "prefix" {
  type    = string
}

# Environment name
variable "environment" {
  type    = string
}

# VPC CIDR
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

# Subnet CIDRs per AZ
variable "public_subnets" {
  type = map(string)
}

variable "private_app_subnets" {
  type = map(string)
}

variable "private_db_subnets" {
  type = map(string)
}

# Apps to deploy
variable "apps" {
  type = map(object({
    image           = string
    port            = number
    cpu_request     = string
    cpu_limit       = string
    memory_request  = string
    memory_limit    = string
  }))
  default = {
    frontend = {
      image = "veeva/frontend:latest"
      port  = 80
      cpu_request = "250m"
      cpu_limit   = "500m"
      memory_request = "256Mi"
      memory_limit   = "512Mi"
    }
    backend = {
      image = "veeva/backend:latest"
      port  = 8080
      cpu_request = "500m"
      cpu_limit   = "1000m"
      memory_request = "512Mi"
      memory_limit   = "1024Mi"
    }
    datastream = {
      image = "veeva/datastream:latest"
      port  = 9090
      cpu_request = "200m"
      cpu_limit   = "400m"
      memory_request = "256Mi"
      memory_limit   = "512Mi"
    }
  }
}

variable "node_instance_type" {
  type    = string
  default = t3.medium
}

variable "ingress_name" {
  type = string
  default = "frontend-ingress"
}

# DB
variable "db_username" {
  type    = string
  default = "admin"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "db_engine" {
  type    = string
}

variable "db_engine_version" {
  type    = string
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

## EKS nodes
variable "node_desired_size" {
  type        = number
  default     = 2
}

variable "node_min_size" {
  type        = number
  default     = 2
}

variable "node_max_size" {
  type        = number
  default     = 5
}

## HPA
variable "min_replicas" {
  type    = number
  default = 2
}

variable "max_replicas" {
  type    = number
  default = 10
}

variable "cpu_target_percentage" {
  type    = number
  default = 70
}
