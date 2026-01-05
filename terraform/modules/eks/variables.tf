variable "cluster_name" { type = string }
variable "eks_version" { type = string, default = "1.29" }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "node_instance_type" { type = string, default = "t3.medium" }
variable "node_desired_size" { type = number, default = 2 }
variable "node_min_size" { type = number, default = 2 }
variable "node_max_size" { type = number, default = 5 }
variable "region" { type = string, default = "us-east-1" }
variable "alb_iam_policy_file" { type = string, default = "alb_iam_policy.json" }
