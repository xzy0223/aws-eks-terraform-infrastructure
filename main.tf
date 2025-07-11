terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Kubernetes provider configuration with error handling
provider "kubernetes" {
  host                   = try(module.eks.cluster_endpoint, "")
  cluster_ca_certificate = try(base64decode(module.eks.cluster_certificate_authority_data), "")
  token                  = try(module.eks.cluster_auth_token, "")

  # 添加错误处理，在集群不存在时跳过
  ignore_annotations = [
    "kubectl.kubernetes.io/last-applied-configuration",
  ]
}

# Helm provider configuration with error handling
provider "helm" {
  kubernetes {
    host                   = try(module.eks.cluster_endpoint, "")
    cluster_ca_certificate = try(base64decode(module.eks.cluster_certificate_authority_data), "")
    token                  = try(module.eks.cluster_auth_token, "")
  }
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  name_prefix                   = var.project_name
  vpc_cidr                     = var.vpc_cidr
  az_count                     = var.availability_zone_count
  region                       = var.aws_region
  public_subnet_newbits        = var.public_subnet_newbits
  private_subnet_newbits       = var.private_subnet_newbits
  custom_public_subnet_cidrs   = var.custom_public_subnet_cidrs
  custom_private_subnet_cidrs  = var.custom_private_subnet_cidrs
}

# Bastion Host Module
module "bastion" {
  source = "./modules/bastion"
  
  count = var.enable_bastion ? 1 : 0

  name_prefix           = var.project_name
  vpc_id               = module.vpc.vpc_id
  bastion_subnet_cidr  = var.bastion_subnet_cidr
  availability_zone    = module.vpc.availability_zones[0]
  public_route_table_id = module.vpc.public_route_table_id
  key_name             = var.bastion_key_name
  instance_type        = var.bastion_instance_type
  allowed_ssh_cidrs    = var.bastion_allowed_ssh_cidrs
  root_volume_size     = var.bastion_root_volume_size
  region               = var.aws_region
}

# EKS Cluster Module
module "eks" {
  source = "./modules/eks"

  name_prefix               = var.project_name
  vpc_id                   = module.vpc.vpc_id
  public_subnet_ids        = module.vpc.public_subnet_ids
  private_subnet_ids       = module.vpc.private_subnet_ids
  kubernetes_version       = var.kubernetes_version
  node_instance_type       = var.eks_node_instance_type
  node_desired_size        = var.eks_node_desired_size
  node_max_size            = var.eks_node_max_size
  node_min_size            = var.eks_node_min_size
  region                   = var.aws_region
  bastion_security_group_id = var.enable_bastion ? module.bastion[0].bastion_security_group_id : null
  
  # EKS Add-ons configuration
  enable_pod_identity                  = var.enable_pod_identity
  enable_ebs_csi_driver               = var.enable_ebs_csi_driver
  enable_coredns                      = var.enable_coredns
  enable_kube_proxy                   = var.enable_kube_proxy
  enable_vpc_cni                      = var.enable_vpc_cni
  enable_vpc_cni_prefix_delegation    = var.enable_vpc_cni_prefix_delegation
  enable_aws_load_balancer_controller = var.enable_aws_load_balancer_controller
  
  # EC2 instance naming
  node_instance_name_prefix = var.node_instance_name_prefix
  
  # EKS Access configuration
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions
  additional_admin_users                   = var.additional_admin_users
  additional_admin_roles                   = var.additional_admin_roles
  
  # Additional configuration for Launch Template
  additional_tags      = var.additional_tags
  bootstrap_arguments  = var.bootstrap_arguments
}
