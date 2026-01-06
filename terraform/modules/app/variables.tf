variable "apps" {
  type = map(object({
    image = string
    port  = number
  }))
}

variable "namespace" {
  type        = string
}

variable "min_replicas" {
  type    = number
}

variable "max_replicas" {
  type    = number
}

variable "cpu_target_percentage" {
  type    = number
}

variable "ingress_name" {
  type = string
}


