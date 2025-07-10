# Cleanup resource to handle pre-destroy operations
resource "null_resource" "pre_destroy_cleanup" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  # This resource will be destroyed before the EKS cluster
  triggers = {
    cluster_name = aws_eks_cluster.main.name
    region       = var.region
  }

  # Cleanup script that runs before destroy
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "🧹 执行销毁前清理..."
      
      # 尝试删除 Helm release
      helm uninstall aws-load-balancer-controller -n kube-system --ignore-not-found || echo "ALB Controller 已删除"
      
      # 等待清理完成
      sleep 10
      
      echo "✅ 清理完成"
    EOT
    
    # 设置环境变量
    environment = {
      KUBECONFIG = "~/.kube/config"
    }
  }

  depends_on = [
    helm_release.aws_load_balancer_controller,
    kubernetes_service_account.aws_load_balancer_controller
  ]
}

# 确保清理资源在 Helm release 之前被销毁
resource "null_resource" "helm_dependency" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  depends_on = [
    null_resource.pre_destroy_cleanup
  ]

  lifecycle {
    create_before_destroy = true
  }
}
