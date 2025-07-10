variable "name_prefix" {
  description = "Name prefix for all resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EKS cluster will be deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.33"
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS nodes"
  type        = string
  default     = "t3.micro"
}

variable "node_desired_size" {
  description = "Desired number of nodes in the EKS node group"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of nodes in the EKS node group"
  type        = number
  default     = 4
}

variable "node_min_size" {
  description = "Minimum number of nodes in the EKS node group"
  type        = number
  default     = 1
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "bastion_security_group_id" {
  description = "Security group ID of the bastion host (optional)"
  type        = string
  default     = null
}

# EKS Add-ons configuration
variable "enable_pod_identity" {
  description = "Enable EKS Pod Identity add-on"
  type        = bool
  default     = true
}

variable "enable_ebs_csi_driver" {
  description = "Enable EBS CSI driver add-on"
  type        = bool
  default     = true
}

variable "enable_coredns" {
  description = "Enable CoreDNS add-on"
  type        = bool
  default     = true
}

variable "enable_kube_proxy" {
  description = "Enable kube-proxy add-on"
  type        = bool
  default     = true
}

variable "enable_vpc_cni" {
  description = "Enable VPC CNI add-on"
  type        = bool
  default     = true
}

variable "enable_vpc_cni_prefix_delegation" {
  description = "Enable VPC CNI prefix delegation for increased pod density"
  type        = bool
  default     = false
}

variable "enable_aws_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller"
  type        = bool
  default     = true
}

# EC2 instance naming configuration
variable "node_instance_name_prefix" {
  description = "Prefix for EC2 instance names in the node group"
  type        = string
  default     = ""
}

# EKS Access configuration
variable "enable_cluster_creator_admin_permissions" {
  description = "Enable cluster admin permissions for the identity that creates the cluster"
  type        = bool
  default     = true
}

variable "additional_admin_users" {
  description = "List of additional IAM user ARNs to grant cluster admin permissions"
  type        = list(string)
  default     = []
}

variable "additional_admin_roles" {
  description = "List of additional IAM role ARNs to grant cluster admin permissions"
  type        = list(string)
  default     = []
}
