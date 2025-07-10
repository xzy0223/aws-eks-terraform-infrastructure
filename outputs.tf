# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of the public subnets"
  value       = module.vpc.public_subnet_cidrs
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of the private subnets"
  value       = module.vpc.private_subnet_cidrs
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = module.vpc.nat_gateway_ids
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = module.vpc.public_route_table_id
}

output "private_route_table_ids" {
  description = "IDs of the private route tables"
  value       = module.vpc.private_route_table_ids
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = module.vpc.availability_zones
}

# Bastion Host Outputs
output "bastion_instance_id" {
  description = "ID of the bastion host instance"
  value       = var.enable_bastion ? module.bastion[0].bastion_instance_id : null
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = var.enable_bastion ? module.bastion[0].bastion_public_ip : null
}

output "bastion_private_ip" {
  description = "Private IP address of the bastion host"
  value       = var.enable_bastion ? module.bastion[0].bastion_private_ip : null
}

output "bastion_subnet_id" {
  description = "ID of the bastion subnet"
  value       = var.enable_bastion ? module.bastion[0].bastion_subnet_id : null
}

output "bastion_security_group_id" {
  description = "ID of the bastion security group"
  value       = var.enable_bastion ? module.bastion[0].bastion_security_group_id : null
}

output "bastion_iam_role_arn" {
  description = "ARN of the bastion IAM role"
  value       = var.enable_bastion ? module.bastion[0].bastion_iam_role_arn : null
}

output "bastion_ssh_command" {
  description = "SSH command to connect to bastion host"
  value       = var.enable_bastion ? module.bastion[0].ssh_command : null
}

# EKS Cluster Outputs
output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "eks_cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = module.eks.cluster_version
}

output "eks_cluster_platform_version" {
  description = "EKS cluster platform version"
  value       = module.eks.cluster_platform_version
}

output "eks_cluster_status" {
  description = "EKS cluster status"
  value       = module.eks.cluster_status
}

output "eks_cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "eks_node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = module.eks.node_security_group_id
}

output "eks_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = module.eks.oidc_issuer_url
}

output "eks_cluster_iam_role_arn" {
  description = "IAM role ARN associated with EKS cluster"
  value       = module.eks.cluster_iam_role_arn
}

output "eks_node_group_iam_role_arn" {
  description = "IAM role ARN associated with EKS node group"
  value       = module.eks.node_group_iam_role_arn
}

output "eks_aws_load_balancer_controller_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller"
  value       = module.eks.aws_load_balancer_controller_role_arn
}

output "eks_ebs_csi_driver_role_arn" {
  description = "IAM role ARN for EBS CSI Driver"
  value       = module.eks.ebs_csi_driver_role_arn
}

output "eks_vpc_cni_role_arn" {
  description = "IAM role ARN for VPC CNI"
  value       = module.eks.vpc_cni_role_arn
}

output "eks_kubeconfig_command" {
  description = "Command to update kubeconfig"
  value       = module.eks.kubeconfig_command
}

output "eks_addons" {
  description = "EKS add-ons information"
  value       = module.eks.eks_addons
}

output "eks_cluster_access_entries" {
  description = "All EKS access entries created"
  value       = module.eks.cluster_access_entries
}

output "eks_current_caller_identity" {
  description = "Current AWS caller identity"
  value       = module.eks.current_caller_identity
}

# Sensitive outputs
output "eks_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "eks_cluster_auth_token" {
  description = "Token to use to authenticate with the cluster"
  value       = module.eks.cluster_auth_token
  sensitive   = true
}
