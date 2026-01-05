variable "apps" {
  type = map(object({
    image = string
    port  = number
  }))
}

variable "namespace" {
  type        = string
  default     = "veeva"
}

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

