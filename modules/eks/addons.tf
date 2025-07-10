# EKS Pod Identity Add-on
resource "aws_eks_addon" "pod_identity" {
  count = var.enable_pod_identity ? 1 : 0

  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "eks-pod-identity-agent"
  addon_version               = data.aws_eks_addon_version.pod_identity[0].version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  preserve                    = false
  configuration_values        = jsonencode({})

  depends_on = [
    aws_eks_node_group.main
  ]

  tags = {
    Name = "${var.name_prefix}-pod-identity"
  }
}

# EBS CSI Driver Add-on
resource "aws_eks_addon" "ebs_csi_driver" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = data.aws_eks_addon_version.ebs_csi[0].version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  preserve                    = false
  service_account_role_arn    = var.enable_ebs_csi_driver ? aws_iam_role.ebs_csi_driver[0].arn : null

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.ebs_csi_driver
  ]

  tags = {
    Name = "${var.name_prefix}-ebs-csi-driver"
  }
}

# CoreDNS Add-on
resource "aws_eks_addon" "coredns" {
  count = var.enable_coredns ? 1 : 0

  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "coredns"
  addon_version               = data.aws_eks_addon_version.coredns[0].version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  preserve                    = false
  configuration_values        = jsonencode({})

  depends_on = [
    aws_eks_node_group.main
  ]

  tags = {
    Name = "${var.name_prefix}-coredns"
  }
}

# Kube-proxy Add-on
resource "aws_eks_addon" "kube_proxy" {
  count = var.enable_kube_proxy ? 1 : 0

  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "kube-proxy"
  addon_version               = data.aws_eks_addon_version.kube_proxy[0].version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  preserve                    = false
  configuration_values        = jsonencode({})

  depends_on = [
    aws_eks_node_group.main
  ]

  tags = {
    Name = "${var.name_prefix}-kube-proxy"
  }
}

# VPC CNI Add-on
resource "aws_eks_addon" "vpc_cni" {
  count = var.enable_vpc_cni ? 1 : 0

  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "vpc-cni"
  addon_version               = data.aws_eks_addon_version.vpc_cni[0].version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  preserve                    = false
  service_account_role_arn    = var.enable_vpc_cni ? aws_iam_role.vpc_cni[0].arn : null
  
  # Configuration for VPC CNI
  configuration_values = var.enable_vpc_cni_prefix_delegation ? jsonencode({
    env = {
      ENABLE_PREFIX_DELEGATION = "true"
      WARM_PREFIX_TARGET       = "1"
      WARM_IP_TARGET           = "5"
      MINIMUM_IP_TARGET        = "3"
    }
  }) : jsonencode({})

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.vpc_cni
  ]

  tags = {
    Name = "${var.name_prefix}-vpc-cni"
  }
}

# Data sources for latest add-on versions
data "aws_eks_addon_version" "pod_identity" {
  count = var.enable_pod_identity ? 1 : 0

  addon_name         = "eks-pod-identity-agent"
  kubernetes_version = aws_eks_cluster.main.version
  most_recent        = true
}

data "aws_eks_addon_version" "ebs_csi" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = aws_eks_cluster.main.version
  most_recent        = true
}

data "aws_eks_addon_version" "coredns" {
  count = var.enable_coredns ? 1 : 0

  addon_name         = "coredns"
  kubernetes_version = aws_eks_cluster.main.version
  most_recent        = true
}

data "aws_eks_addon_version" "kube_proxy" {
  count = var.enable_kube_proxy ? 1 : 0

  addon_name         = "kube-proxy"
  kubernetes_version = aws_eks_cluster.main.version
  most_recent        = true
}

data "aws_eks_addon_version" "vpc_cni" {
  count = var.enable_vpc_cni ? 1 : 0

  addon_name         = "vpc-cni"
  kubernetes_version = aws_eks_cluster.main.version
  most_recent        = true
}

# IAM Role for EBS CSI Driver
resource "aws_iam_role" "ebs_csi_driver" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  name = "${var.name_prefix}-ebs-csi-driver"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.name_prefix}-ebs-csi-driver"
  }
}

# Attach AWS managed policy for EBS CSI Driver
resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver[0].name
}

# IAM Role for VPC CNI
resource "aws_iam_role" "vpc_cni" {
  count = var.enable_vpc_cni ? 1 : 0

  name = "${var.name_prefix}-vpc-cni"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-node"
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.name_prefix}-vpc-cni"
  }
}

# Attach AWS managed policy for VPC CNI
resource "aws_iam_role_policy_attachment" "vpc_cni" {
  count = var.enable_vpc_cni ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.vpc_cni[0].name
}
