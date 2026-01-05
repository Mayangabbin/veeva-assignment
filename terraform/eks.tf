# IAM role for EKS
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

# Attach role
resource "aws_iam_role_policy_attachment" "eks_cluster_attach" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# IAM role for nodes
resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# attach role
resource "aws_iam_role_policy_attachment" "eks_node_attach" {
  for_each = {
    "AmazonEKSWorkerNodePolicy"     = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    "AmazonEKS_CNI_Policy"          = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    "AmazonEC2ContainerRegistryReadOnly" = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  }

  role       = aws_iam_role.eks_node_role.name
  policy_arn = each.value
}

# EKS cluster
resource "aws_eks_cluster" "main" {
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_attach
  ]
  name     = "my-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.29"

  vpc_config {
    subnet_ids = concat(
      [for s in aws_subnet.private_app : s.id],
      [for s in aws_subnet.public : s.id]
    )
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  tags = {
    Environment = "prod"
  }
}

# EKS node group
resource "aws_eks_node_group" "private_app_nodes" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "private-app-ng"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [for s in aws_subnet.private_app : s.id]

  scaling_config {
    desired_size = 2
    max_size     = 5
    min_size     = 2
  }

  instance_types = ["t3.medium"]
  ami_type       = "AL2_x86_64"
}

resource "aws_iam_policy" "aws_lb_controller" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  path        = "/"
  description = "IAM policy for AWS Load Balancer Controller"

  policy = file("iam_policy.json") 
}

resource "aws_iam_role" "lb_controller_role" {
  assume_role_policy = data.aws_iam_policy_document.lb_assume_role.json
  name               = "eks-lb-controller-role"
}

data "aws_iam_policy_document" "lb_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_eks_cluster.main.identity[0].oidc[0].issuer]
    }

    condition {
      test     = "StringEquals"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
      variable = "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub"
    }
  }
}
resource "kubernetes_service_account" "aws_lb_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.lb_controller.arn
    }
  }
}

resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  values = [
    yamlencode({
      clusterName       = aws_eks_cluster.main.name
      serviceAccount    = {
        create = false
        name   = kubernetes_service_account.aws_lb_controller.metadata[0].name
      }
      region            = "us-east-1" # שנה לפי האזור שלך
      vpcId             = aws_vpc.main.id
    })
  ]
}

