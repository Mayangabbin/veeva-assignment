# IAM role for EKS
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.prefix}-eks-cluster-role"

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
  tags = var.tags
}

# Attach role
resource "aws_iam_role_policy_attachment" "eks_cluster_attach" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# IAM role for nodes
resource "aws_iam_role" "eks_node_role" {
  name = "${var.prefix}-eks-node-role"

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
  tags = var.tags
}

# Attach role
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
  depends_on = [aws_iam_role_policy_attachment.eks_cluster_attach]
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.eks_version

  vpc_config {
    subnet_ids = concat(var.private_app_subnet_ids, var.public_subnet_ids)
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  tags = var.tags

  
}

# EKS node group
resource "aws_eks_node_group" "private_app_nodes" {
  depends_on = [
    aws_iam_role_policy_attachment.eks_node_attach,
    aws_eks_cluster.main
  ]
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.prefix}-private-app-ng"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  instance_types = [var.node_instance_type]
  ami_type       = "AL2_x86_64"
  tags = var.tags
}

# IAM Policy & Role for AWS Load Balancer Controller
resource "aws_iam_policy" "aws_lb_controller" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  path        = "/"
  description = "IAM policy for AWS Load Balancer Controller"
  policy = file("${path.module}/${var.alb_iam_policy_file}")
}

resource "aws_iam_role" "lb_controller_role" {
  assume_role_policy = data.aws_iam_policy_document.lb_assume_role.json
  name               = "eks-lb-controller-role"
  tags = var.tags
}

data "aws_iam_policy_document" "lb_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_eks_cluster.main.identity[0].oidc.0.issuer]
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
    name      = "${var.prefix}-aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.lb_controller.arn
    }
  }
}

resource "helm_release" "aws_lb_controller" {
  depends_on = [
    kubernetes_service_account.aws_lb_controller,
    aws_iam_role.lb_controller_role,
    aws_eks_node_group.private_app_nodes
  ]
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
      region            = var.region 
      vpcId             = var.vpc_id
    })
  ]
}

### Cluster autoscaler
# IAM policy for cluster autoscaler
resource "aws_iam_policy" "cluster_autoscaler" {
  name = "${var.prefix}-cluster-autoscaler-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions"
        ]
        Resource = "*"
      }
    ]
  })
}

# Role for cluster autoscaler
resource "aws_iam_role" "cluster_autoscaler" {
  name = "${var.prefix}-cluster-autoscaler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRoleWithWebIdentity"
      Principal = {
        Federated = aws_eks_cluster.main.identity[0].oidc[0].issuer
      }
      Condition = {
        StringEquals = {
          "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub" =
          "system:serviceaccount:kube-system:cluster-autoscaler"
        }
      }
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler_attach" {
  role       = aws_iam_role.cluster_autoscaler.name
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}

# Service account for autoscaler
resource "kubernetes_service_account" "cluster_autoscaler" {
  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.cluster_autoscaler.arn
    }
  }
}

# Install autoscaler
resource "helm_release" "cluster_autoscaler" {
  depends_on = [
    kubernetes_service_account.cluster_autoscaler,
    aws_iam_role.cluster_autoscaler,
    aws_eks_node_group.private_app_nodes
  ]
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"

  values = [
    yamlencode({
      cloudProvider = "aws"
      awsRegion     = var.region

      autoDiscovery = {
        clusterName = aws_eks_cluster.main.name
      }

      rbac = {
        serviceAccount = {
          create = false
          name   = kubernetes_service_account.cluster_autoscaler.metadata[0].name
        }
      }

      extraArgs = {
        balance-similar-node-groups = "true"
        skip-nodes-with-system-pods = "false"
        skip-nodes-with-local-storage = "false"
      }
    })
  ]
}


