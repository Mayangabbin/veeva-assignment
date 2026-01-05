output "eks_cluster_id" {value = aws_eks_cluster.main.id}

output "eks_cluster_name" {value = aws_eks_cluster.main.name}

output "eks_node_role_arn" {value = aws_iam_role.eks_node_role.arn}

output "eks_cluster_role_arn" {value = aws_iam_role.eks_cluster_role.arn}

output "kubeconfig" {
  value = {
    host                   = aws_eks_cluster.main.endpoint
    cluster_ca_certificate = aws_eks_cluster.main.certificate_authority[0].data
    token                  = data.aws_eks_cluster_auth.main.token
  }
}

output "eks_node_group_sg_id" {value = aws_eks_node_group.private_app_nodes.resources[0].security_groups[0]}
