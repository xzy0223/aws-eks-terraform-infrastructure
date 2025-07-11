output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = aws_eks_cluster.main.version
}

output "cluster_platform_version" {
  description = "EKS cluster platform version"
  value       = aws_eks_cluster.main.platform_version
}

output "cluster_status" {
  description = "EKS cluster status"
  value       = aws_eks_cluster.main.status
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.eks_cluster_sg.id
}

output "node_groups" {
  description = "EKS node groups"
  value       = aws_eks_node_group.main
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = aws_security_group.eks_nodes_sg.id
}

output "launch_template_id" {
  description = "ID of the Launch Template used by EKS node group"
  value       = aws_launch_template.eks_nodes.id
}

output "launch_template_name" {
  description = "Name of the Launch Template used by EKS node group"
  value       = aws_launch_template.eks_nodes.name
}

output "launch_template_latest_version" {
  description = "Latest version of the Launch Template"
  value       = aws_launch_template.eks_nodes.latest_version
}

output "oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "cluster_iam_role_name" {
  description = "IAM role name associated with EKS cluster"
  value       = aws_iam_role.eks_cluster_role.name
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN associated with EKS cluster"
  value       = aws_iam_role.eks_cluster_role.arn
}

output "node_group_iam_role_name" {
  description = "IAM role name associated with EKS node group"
  value       = aws_iam_role.eks_node_group_role.name
}

output "node_group_iam_role_arn" {
  description = "IAM role ARN associated with EKS node group"
  value       = aws_iam_role.eks_node_group_role.arn
}

output "aws_load_balancer_controller_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller"
  value       = var.enable_aws_load_balancer_controller ? aws_iam_role.aws_load_balancer_controller[0].arn : null
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_auth_token" {
  description = "Token to use to authenticate with the cluster"
  value       = data.aws_eks_cluster_auth.cluster.token
  sensitive   = true
}

output "kubeconfig_command" {
  description = "Command to update kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.main.name}"
}

# EKS Add-ons outputs
output "eks_addons" {
  description = "EKS add-ons information"
  value = {
    pod_identity = var.enable_pod_identity ? {
      name    = aws_eks_addon.pod_identity[0].addon_name
      version = aws_eks_addon.pod_identity[0].addon_version
    } : null

    ebs_csi_driver = var.enable_ebs_csi_driver ? {
      name    = aws_eks_addon.ebs_csi_driver[0].addon_name
      version = aws_eks_addon.ebs_csi_driver[0].addon_version
    } : null

    coredns = var.enable_coredns ? {
      name    = aws_eks_addon.coredns[0].addon_name
      version = aws_eks_addon.coredns[0].addon_version
    } : null

    kube_proxy = var.enable_kube_proxy ? {
      name    = aws_eks_addon.kube_proxy[0].addon_name
      version = aws_eks_addon.kube_proxy[0].addon_version
    } : null

    vpc_cni = var.enable_vpc_cni ? {
      name    = aws_eks_addon.vpc_cni[0].addon_name
      version = aws_eks_addon.vpc_cni[0].addon_version
    } : null
  }
}

output "ebs_csi_driver_role_arn" {
  description = "IAM role ARN for EBS CSI Driver"
  value       = var.enable_ebs_csi_driver ? aws_iam_role.ebs_csi_driver[0].arn : null
}

output "vpc_cni_role_arn" {
  description = "IAM role ARN for VPC CNI"
  value       = var.enable_vpc_cni ? aws_iam_role.vpc_cni[0].arn : null
}

# EKS Access Configuration outputs
output "cluster_creator_access_entry" {
  description = "EKS access entry for cluster creator"
  value = var.enable_cluster_creator_admin_permissions ? {
    principal_arn = aws_eks_access_entry.cluster_creator[0].principal_arn
    type          = aws_eks_access_entry.cluster_creator[0].type
  } : null
}

output "cluster_access_entries" {
  description = "All EKS access entries created"
  value = {
    cluster_creator = var.enable_cluster_creator_admin_permissions ? data.aws_caller_identity.current.arn : null
    admin_users     = var.additional_admin_users
    admin_roles     = var.additional_admin_roles
  }
}

output "current_caller_identity" {
  description = "Current AWS caller identity"
  value = {
    account_id = data.aws_caller_identity.current.account_id
    arn        = data.aws_caller_identity.current.arn
    user_id    = data.aws_caller_identity.current.user_id
  }
}
