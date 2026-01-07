locals {
  cluster_name = "${var.prefix}-${var.environment}-eks"
  tags = {
    Environment = var.environment
  }
}

### NETWORKING MODULE ###
# Creates VPC, 2 Public subnets, 4 Private subnets.
module "networking" {
  source              = "../../modules/networking"
  cidr_block          = var.vpc_cidr
  prefix              = var.prefix
  cluster_name        = local.cluster_name
  public_subnets      = var.public_subnets
  private_app_subnets = var.private_app_subnets
  private_db_subnets  = var.private_db_subnets
  tags = local.tags
}

### EKS MODULE ###
# Creates EKS cluster with ALB controller
module "eks" {
  source                 = "../../modules/eks"
  vpc_id                 = module.networking.vpc_id
  public_subnet_ids      = module.networking.public_subnet_ids
  private_app_subnet_ids = module.networking.private_app_subnet_ids
  cluster_name           = local.cluster_name
  prefix                 = var.prefix
  environment            = var.environment
  node_instance_type     = var.node_instance_type
  node_desired_size      = var.node_desired_size
  node_min_size          = var.node_min_size
  node_max_size          = var.node_max_size
  tags = local.tags
}

### APP MODULE ###
# Creates 3 deployments with services and ALB ingress for frontend
module "app" {
  source                = "../../modules/app"
  namespace             = var.namespace
  apps                  = var.apps
  min_replicas          = var.min_replicas
  max_replicas          = var.max_replicas
  cpu_target_precentage = var.cpu_target_precentage 
  ingress_name = var.ingress_name
}

### RDS MODULE ###
# Creates multi AZ rds instance with SG allowing ingress
# from EKS nodes
module "rds" {
  source            = "../../modules/rds"
  vpc_id            = module.networking.vpc_id
  db_name           = "${var.prefix}-${var.environment}-db"
  db_username       = var.db_username
  db_instance_class = var.db_instance_class
  engine            = var.db_engine
  allocated_storage = var.db_allocated_storage
  node_sg_ids       = [module.eks.eks_node_group_sg_id]
  subnet_ids        = module.networking.private_db_subnet_ids
  tags = local.tags

}

### WAF MODULE ###
# Creates WAF ACL for CloudFront
module "waf" {
  source = "../../modules/waf"
  prefix = var.prefix
  tags   = local.tags
}

### CLOUDFRONT MODULE ###
# Creates a CloudFront Distribution for serving traffic to ALB
module "cloudfront" {
  source       = "../../modules/cloudfront"
  cf_waf_arn   = module.waf.cf_waf_arn
  ingress_name = var.ingress_name
  tags = local.tags
}


