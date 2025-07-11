# Data source for latest EKS version
data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.main.name
}

data "aws_caller_identity" "current" {}

# EKS Cluster Service Role
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.name_prefix}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.name_prefix}-eks-cluster-role"
  }
}

# Attach required policies to cluster role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# EKS Node Group Service Role
resource "aws_iam_role" "eks_node_group_role" {
  name = "${var.name_prefix}-eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.name_prefix}-eks-node-group-role"
  }
}

# Attach required policies to node group role
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}

# Security Group for EKS Cluster
resource "aws_security_group" "eks_cluster_sg" {
  name_prefix = "${var.name_prefix}-eks-cluster-sg"
  vpc_id      = var.vpc_id
  description = "Security group for EKS cluster"

  # Allow HTTPS traffic from nodes
  ingress {
    description = "HTTPS from nodes"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    self        = true
  }

  # Allow HTTPS traffic from bastion host (if provided)
  dynamic "ingress" {
    for_each = var.bastion_security_group_id != null ? [1] : []
    content {
      description     = "HTTPS from bastion host"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      security_groups = [var.bastion_security_group_id]
    }
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-eks-cluster-sg"
  }
}

# Security Group for EKS Nodes
resource "aws_security_group" "eks_nodes_sg" {
  name_prefix = "${var.name_prefix}-eks-nodes-sg"
  vpc_id      = var.vpc_id
  description = "Security group for EKS nodes"

  # Allow nodes to communicate with each other
  ingress {
    description = "Node to node communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  # Allow pods to communicate with the cluster API Server
  ingress {
    description     = "Allow pods to communicate with the cluster API Server"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster_sg.id]
  }

  # Allow access from bastion host for kubectl proxy and port-forward (if provided)
  dynamic "ingress" {
    for_each = var.bastion_security_group_id != null ? [1] : []
    content {
      description     = "Access from bastion host"
      from_port       = 1024
      to_port         = 65535
      protocol        = "tcp"
      security_groups = [var.bastion_security_group_id]
    }
  }

  # Allow NodePort services access from bastion host (if provided)
  dynamic "ingress" {
    for_each = var.bastion_security_group_id != null ? [1] : []
    content {
      description     = "NodePort services from bastion host"
      from_port       = 30000
      to_port         = 32767
      protocol        = "tcp"
      security_groups = [var.bastion_security_group_id]
    }
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-eks-nodes-sg"
  }
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "${var.name_prefix}-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.kubernetes_version

  # Set authentication mode to API_AND_CONFIG_MAP
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  vpc_config {
    subnet_ids              = concat(var.public_subnet_ids, var.private_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.eks_cluster_sg.id]
  }

  # Enable logging
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
  ]

  tags = {
    Name = "${var.name_prefix}-eks-cluster"
  }
}

# Data source to get the latest EKS optimized AMI (Amazon Linux 2023)
data "aws_ssm_parameter" "eks_ami_release_version" {
  name = "/aws/service/eks/optimized-ami/${aws_eks_cluster.main.version}/amazon-linux-2023/x86_64/standard/recommended/image_id"
}

# Launch Template for EKS Node Group with custom instance naming
resource "aws_launch_template" "eks_nodes" {
  name_prefix   = "${var.name_prefix}-eks-node-template-"
  description   = "Launch template for EKS worker nodes with custom naming"
  image_id      = data.aws_ssm_parameter.eks_ami_release_version.value
  instance_type = var.node_instance_type

  # Security groups - use EKS cluster security group for proper communication
  vpc_security_group_ids = [aws_eks_cluster.main.vpc_config[0].cluster_security_group_id]

  # Custom tags for EC2 instances
  tag_specifications {
    resource_type = "instance"
    tags = merge(
      {
        Name = var.node_instance_name_prefix != "" ? "${var.node_instance_name_prefix}-eks-worker" : "${var.name_prefix}-eks-worker"
        "kubernetes.io/cluster/${aws_eks_cluster.main.name}" = "owned"
      },
      var.additional_tags
    )
  }

  # Custom tags for EBS volumes
  tag_specifications {
    resource_type = "volume"
    tags = merge(
      {
        Name = var.node_instance_name_prefix != "" ? "${var.node_instance_name_prefix}-eks-worker-volume" : "${var.name_prefix}-eks-worker-volume"
        "kubernetes.io/cluster/${aws_eks_cluster.main.name}" = "owned"
      },
      var.additional_tags
    )
  }

  # User data for AL2023 EKS nodes using nodeadm with proper MIME format
  user_data = base64encode(<<-EOF
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="BOUNDARY"

--BOUNDARY
Content-Type: application/node.eks.aws

apiVersion: node.eks.aws/v1alpha1
kind: NodeConfig
spec:
  cluster:
    name: ${aws_eks_cluster.main.name}
    apiServerEndpoint: ${aws_eks_cluster.main.endpoint}
    certificateAuthority: ${aws_eks_cluster.main.certificate_authority[0].data}
    cidr: ${aws_eks_cluster.main.kubernetes_network_config[0].service_ipv4_cidr}
  kubelet:
    flags:
      - --node-labels=role=worker

--BOUNDARY--
EOF
  )

  # Ensure instances are terminated when the launch template is updated
  update_default_version = true

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.name_prefix}-eks-node-launch-template"
  }
}

# EKS Node Group using Launch Template
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.name_prefix}-eks-nodes"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = var.private_subnet_ids

  capacity_type = "ON_DEMAND"

  # Use Launch Template instead of instance_types
  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = aws_launch_template.eks_nodes.latest_version
  }

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
    aws_launch_template.eks_nodes,
  ]

  # Node group level tags
  tags = {
    Name = "${var.name_prefix}-eks-node-group"
  }
}

# IAM Role for AWS Load Balancer Controller
resource "aws_iam_role" "aws_load_balancer_controller" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  name = "${var.name_prefix}-aws-load-balancer-controller"

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
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.name_prefix}-aws-load-balancer-controller"
  }
}

# IAM Policy for AWS Load Balancer Controller
resource "aws_iam_policy" "aws_load_balancer_controller" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  name        = "${var.name_prefix}-AWSLoadBalancerControllerIAMPolicy"
  description = "IAM policy for AWS Load Balancer Controller"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreateServiceLinkedRole"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = "elasticloadbalancing.amazonaws.com"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeVpcPeeringConnections",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:GetCoipPoolUsage",
          "ec2:DescribeCoipPools",
          "ec2:GetSecurityGroupsForVpc",
          "ec2:DescribeIpamPools",
          "ec2:DescribeRouteTables",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTags",
          "elasticloadbalancing:DescribeTrustStores",
          "elasticloadbalancing:DescribeListenerAttributes",
          "elasticloadbalancing:DescribeCapacityReservation"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:DescribeUserPoolClient",
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "iam:ListServerCertificates",
          "iam:GetServerCertificate",
          "waf-regional:GetWebACL",
          "waf-regional:GetWebACLForResource",
          "waf-regional:AssociateWebACL",
          "waf-regional:DisassociateWebACL",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL",
          "shield:GetSubscriptionState",
          "shield:DescribeProtection",
          "shield:CreateProtection",
          "shield:DeleteProtection"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSecurityGroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags"
        ]
        Resource = "arn:aws:ec2:*:*:security-group/*"
        Condition = {
          StringEquals = {
            "ec2:CreateAction" = "CreateSecurityGroup"
          }
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]
        Resource = "arn:aws:ec2:*:*:security-group/*"
        Condition = {
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "true"
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DeleteSecurityGroup"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateTargetGroup"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:DeleteRule"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ]
        Resource = [
          "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
        ]
        Condition = {
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "true"
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ]
        Resource = [
          "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:ModifyListenerAttributes",
          "elasticloadbalancing:ModifyCapacityReservation",
          "elasticloadbalancing:ModifyIpPools"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:AddTags"
        ]
        Resource = [
          "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
        ]
        Condition = {
          StringEquals = {
            "elasticloadbalancing:CreateAction" = [
              "CreateTargetGroup",
              "CreateLoadBalancer"
            ]
          }
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets"
        ]
        Resource = "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:SetWebAcl",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:AddListenerCertificates",
          "elasticloadbalancing:RemoveListenerCertificates",
          "elasticloadbalancing:ModifyRule",
          "elasticloadbalancing:SetRulePriorities"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${var.name_prefix}-AWSLoadBalancerControllerIAMPolicy"
  }
}

# Attach policy to Load Balancer Controller role
resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  policy_arn = aws_iam_policy.aws_load_balancer_controller[0].arn
  role       = aws_iam_role.aws_load_balancer_controller[0].name
}

# OIDC Identity Provider for EKS
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = {
    Name = "${var.name_prefix}-eks-irsa"
  }
}

# EKS Access Configuration
# Create access entry for the current caller (cluster creator)
resource "aws_eks_access_entry" "cluster_creator" {
  count = var.enable_cluster_creator_admin_permissions ? 1 : 0

  cluster_name      = aws_eks_cluster.main.name
  principal_arn     = data.aws_caller_identity.current.arn
  type              = "STANDARD"
  kubernetes_groups = []

  depends_on = [aws_eks_cluster.main]

  tags = {
    Name = "${var.name_prefix}-cluster-creator-access"
  }
}

# Associate cluster admin policy with cluster creator
resource "aws_eks_access_policy_association" "cluster_creator_admin" {
  count = var.enable_cluster_creator_admin_permissions ? 1 : 0

  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = data.aws_caller_identity.current.arn

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.cluster_creator]
}

# Create access entries for additional admin users
resource "aws_eks_access_entry" "additional_admin_users" {
  for_each = toset(var.additional_admin_users)

  cluster_name      = aws_eks_cluster.main.name
  principal_arn     = each.value
  type              = "STANDARD"
  kubernetes_groups = []

  depends_on = [aws_eks_cluster.main]

  tags = {
    Name = "${var.name_prefix}-admin-user-access-${replace(each.value, "/[^a-zA-Z0-9-]/", "-")}"
  }
}

# Associate cluster admin policy with additional admin users
resource "aws_eks_access_policy_association" "additional_admin_users" {
  for_each = toset(var.additional_admin_users)

  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = each.value

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.additional_admin_users]
}

# Create access entries for additional admin roles
resource "aws_eks_access_entry" "additional_admin_roles" {
  for_each = toset(var.additional_admin_roles)

  cluster_name      = aws_eks_cluster.main.name
  principal_arn     = each.value
  type              = "STANDARD"
  kubernetes_groups = []

  depends_on = [aws_eks_cluster.main]

  tags = {
    Name = "${var.name_prefix}-admin-role-access-${replace(each.value, "/[^a-zA-Z0-9-]/", "-")}"
  }
}

# Associate cluster admin policy with additional admin roles
resource "aws_eks_access_policy_association" "additional_admin_roles" {
  for_each = toset(var.additional_admin_roles)

  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = each.value

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.additional_admin_roles]
}
