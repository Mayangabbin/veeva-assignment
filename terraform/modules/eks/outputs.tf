output "eks_cluster_id" {value = aws_eks_cluster.main.id}

output "eks_cluster_name" {value = aws_eks_cluster.main.name}

output "eks_node_role_arn" {value = aws_iam_role.eks_node_role.arn}

output "eks_cluster_role_arn" {value = aws_iam_role.eks_cluster_role.arn}
