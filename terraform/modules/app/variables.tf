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

variable "replicas" 
  type        = number
  default     = 2
}
