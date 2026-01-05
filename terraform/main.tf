### NETWORKING MODULE ###
# Creates VPC, 2 Public subnets, 4 Private subnets.
f
module "networking" {
  source = "./modules/networking"

  cidr_block           = "10.0.0.0/16"
  prefix               = "prod"
  cluster_name         = "veeva-cluster"
  public_subnets       = {
    "eu-central-1a" = "10.0.1.0/24"
    "eu-central-1b" = "10.0.2.0/24"
  }
  private_app_subnets  = {
    "eu-central-1a" = "10.0.10.0/24"
    "eu-central-1b" = "10.0.11.0/24"
  }
  private_db_subnets   = {
    "eu-central-1a" = "10.0.20.0/24"
    "eu-central-1b" = "10.0.21.0/24"
  }
}

### EKS MODULE ###
# Creates EKS cluster with ALB controller

module "eks" {
  source = "./modules/eks"
  vpc_id = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  private_app_subnet_ids = module.networking.private_app_subnet_ids
  cluster_name       = "my-eks-cluster"
  prefix             = "prod"
  environment        = "prod"

}

### APP MODULE ###
# Creates 3 deployments with services and ALB ingress for frontend

module "app" {
  source    = "./modules/app"
  
  apps = {
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

### RDS MODULE ###
# Creates multi AZ rds instance with SG allowing ingress
# from EKS nodes

module "rds" {
  source = "./modules/rds"

  vpc_id = module.networking.vpc_id
  db_name               = "veeva-db"
  db_username           = "admin"
  db_instance_class     = "db.t3.medium"
  node_sg_ids = [module.eks.eks_node_group_sg_id]
  subnet_ids            = module.networking.private_app_subnet_ids
}
