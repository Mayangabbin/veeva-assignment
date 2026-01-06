variable "cf_waf_arn" {
  type        = string
  default     = ""
}
variable "ingress_name" {
  type        = string
}
variable "cluster_name" {
  type        = string
}
variable "tags" {
  type    = map(string)
}
