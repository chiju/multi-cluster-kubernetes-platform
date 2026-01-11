# Data sources
data "aws_caller_identity" "current" {}

# KMS Key Policy for EKS encryption
resource "aws_kms_key_policy" "eks" {
  key_id = aws_kms_key.eks.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow EKS Service"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

# EKS Cluster Service Role
resource "aws_iam_role" "cluster" {
  name = "${var.name}-eks-cluster-role"

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

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# Node Group IAM Role
resource "aws_iam_role" "node_group" {
  name = "${var.name}-eks-node-group-role"

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

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "node_group_worker_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_ssm_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node_group.name
}

# OIDC Identity Provider for IRSA
data "tls_certificate" "cluster" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-eks-irsa"
    }
  )
}
# EBS CSI Driver IAM Role
resource "aws_iam_role" "ebs_csi_driver" {
  name = "${var.name}-ebs-csi-driver-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.cluster.arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-ebs-csi-driver-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}

# Crossplane IAM Role for Pod Identity
resource "aws_iam_role" "crossplane" {
  count = var.enable_crossplane_pod_identity ? 1 : 0
  name  = "${var.name}-crossplane-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-crossplane-role"
    }
  )
}

# Attach PowerUserAccess policy to Crossplane role
resource "aws_iam_role_policy_attachment" "crossplane_power_user" {
  count      = var.enable_crossplane_pod_identity ? 1 : 0
  role       = aws_iam_role.crossplane[0].name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# Add specific EKS permissions for cross-cluster access
resource "aws_iam_role_policy" "crossplane_eks_access" {
  count = var.enable_crossplane_pod_identity ? 1 : 0
  name  = "${var.name}-crossplane-eks-access"
  role  = aws_iam_role.crossplane[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups"
        ]
        Resource = "*"
      }
    ]
  })
}
# Cross-cluster GitOps IAM Role (only for management cluster)
resource "aws_iam_role" "flux_cross_cluster" {
  count = var.enable_cross_cluster_access ? 1 : 0
  name  = "${var.name}-flux-cross-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.name}-flux-cross-cluster-role"
  })
}

resource "aws_iam_role_policy" "flux_cross_cluster" {
  count = var.enable_cross_cluster_access ? 1 : 0
  name  = "${var.name}-flux-cross-cluster-policy"
  role  = aws_iam_role.flux_cross_cluster[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:*:*:secret:*-kubeconfig-*"
      }
    ]
  })
}

# Generate kubeconfig for workload clusters and store in Secrets Manager
# This only works for management cluster creating secrets for its workload clusters
resource "aws_secretsmanager_secret" "workload_kubeconfig" {
  count = var.enable_cross_cluster_access && var.name != "management-cluster" ? 0 : length(var.workload_cluster_names)
  
  name = "${var.workload_cluster_names[count.index]}-kubeconfig"
  
  tags = merge(var.tags, {
    Name = "${var.workload_cluster_names[count.index]}-kubeconfig"
  })
}

# For now, create placeholder - will be updated by a separate process
resource "aws_secretsmanager_secret_version" "workload_kubeconfig" {
  count = var.enable_cross_cluster_access && var.name != "management-cluster" ? 0 : length(var.workload_cluster_names)
  
  secret_id = aws_secretsmanager_secret.workload_kubeconfig[count.index].id
  secret_string = templatefile("${path.module}/kubeconfig.tpl", {
    cluster_name     = var.workload_cluster_names[count.index]
    cluster_endpoint = "https://placeholder-will-be-updated.eks.amazonaws.com"
    cluster_ca       = "placeholder-ca-cert"
    region          = data.aws_region.current.name
  })
  
  lifecycle {
    ignore_changes = [secret_string]
  }
}
