locals {
  cluster_name = "${var.prefix}-${var.environment}-eks"
}

### NETWORKING MODULE ###
# Creates VPC, 2 Public subnets, 4 Private subnets.
module "networking" {
  source = "./modules/networking"
  cidr_block          = var.vpc_cidr
  prefix              = var.prefix
  cluster_name        = local.cluster_name
  public_subnets      = var.public_subnets
  private_app_subnets = var.private_app_subnets
  private_db_subnets  = var.private_db_subnets
}

### EKS MODULE ###
# Creates EKS cluster with ALB controller
module "eks" {
  source = "./modules/eks"
  vpc_id                 = module.networking.vpc_id
  public_subnet_ids      = [for az, cidr in module.networking.public_subnets : cidr]
  private_app_subnet_ids = [for az, cidr in module.networking.private_app_subnets : cidr]
  cluster_name           = local.cluster_name
  prefix                 = var.prefix
  environment            = var.environment
}

### APP MODULE ###
# Creates 3 deployments with services and ALB ingress for frontend
module "app" {
  source    = "./modules/app"
  apps      = var.apps
  replicas  = var.replicas
}

### RDS MODULE ###
# Creates multi AZ rds instance with SG allowing ingress
# from EKS nodes
module "rds" {
  source            = "./modules/rds"
  vpc_id            = module.networking.vpc_id
  db_name           = var.db_name
  db_username       = var.db_username
  db_instance_class = var.db_instance_class
  node_sg_ids       = [module.eks.eks_node_group_sg_id]
  subnet_ids        = [for az, cidr in module.networking.private_app_subnets : cidr]
}

