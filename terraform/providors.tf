# AWS Provider
provider "aws" {
  region = "eu-west-1"
}
# Provider for EKS cluster
provider "kubernetes" {
  host                   = module.eks.kubeconfig.host
  cluster_ca_certificate = base64decode(module.eks.kubeconfig.cluster_ca_certificate)
  token                  = module.eks.kubeconfig.token
}
