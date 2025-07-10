variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name of the project (used as prefix for resource names)"
  type        = string
  default     = "my-project"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zone_count" {
  description = "Number of Availability Zones to use"
  type        = number
  default     = 3
}

variable "public_subnet_newbits" {
  description = "Number of additional bits for public subnet CIDR (e.g., 8 for /24 subnets from /16 VPC)"
  type        = number
  default     = 8
}

variable "private_subnet_newbits" {
  description = "Number of additional bits for private subnet CIDR (e.g., 8 for /24 subnets from /16 VPC)"
  type        = number
  default     = 8
}

variable "custom_public_subnet_cidrs" {
  description = "Custom CIDR blocks for public subnets (optional)"
  type        = list(string)
  default     = []
}

variable "custom_private_subnet_cidrs" {
  description = "Custom CIDR blocks for private subnets (optional)"
  type        = list(string)
  default     = []
}

# Bastion Host Variables
variable "enable_bastion" {
  description = "Enable bastion host deployment"
  type        = bool
  default     = false
}

variable "bastion_key_name" {
  description = "EC2 Key Pair name for bastion host SSH access"
  type        = string
  default     = ""
}

variable "bastion_instance_type" {
  description = "EC2 instance type for bastion host"
  type        = string
  default     = "t2.micro"
}

variable "bastion_subnet_cidr" {
  description = "CIDR block for bastion subnet"
  type        = string
  default     = "10.0.100.0/24"
}

variable "bastion_allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed to SSH to bastion host"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "bastion_root_volume_size" {
  description = "Size of bastion host root volume in GB"
  type        = number
  default     = 20
}

# EKS Cluster Variables
variable "enable_eks" {
  description = "Enable EKS cluster deployment"
  type        = bool
  default     = false
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.33"
}

variable "eks_node_instance_type" {
  description = "EC2 instance type for EKS nodes"
  type        = string
  default     = "t3.micro"
}

variable "eks_node_desired_size" {
  description = "Desired number of nodes in the EKS node group"
  type        = number
  default     = 2
}

variable "eks_node_max_size" {
  description = "Maximum number of nodes in the EKS node group"
  type        = number
  default     = 4
}

variable "eks_node_min_size" {
  description = "Minimum number of nodes in the EKS node group"
  type        = number
  default     = 1
}

# EKS Add-ons Configuration
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
  description = "Prefix for EC2 instance names in the EKS node group"
  type        = string
  default     = ""
}

# EKS Access Configuration
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
