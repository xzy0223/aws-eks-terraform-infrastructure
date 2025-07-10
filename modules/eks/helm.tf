# Create service account for AWS Load Balancer Controller
resource "kubernetes_service_account" "aws_load_balancer_controller" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.aws_load_balancer_controller[0].arn
    }
  }

  depends_on = [aws_eks_node_group.main]
}

# Install AWS Load Balancer Controller using Helm
resource "helm_release" "aws_load_balancer_controller" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.13.3"

  # 添加清理和错误处理配置
  cleanup_on_fail    = true
  force_update       = true
  wait               = true
  wait_for_jobs      = false
  timeout            = 600
  disable_webhooks   = false
  
  # 不跳过 CRDs，AWS Load Balancer Controller 需要安装 CRDs
  skip_crds          = false
  
  # 添加 CRD 管理配置
  create_namespace   = false  # kube-system 已存在
  replace           = false   # 避免强制替换导致的问题
  
  # 添加重试配置
  max_history       = 3

  set {
    name  = "clusterName"
    value = aws_eks_cluster.main.name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.aws_load_balancer_controller[0].metadata[0].name
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  # 添加优雅关闭配置
  set {
    name  = "terminationGracePeriodSeconds"
    value = "10"
  }

  depends_on = [
    kubernetes_service_account.aws_load_balancer_controller,
    aws_eks_node_group.main
  ]
}
