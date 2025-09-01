# KMS key for EKS cluster encryption
resource "aws_kms_key" "eks" {
  description             = "KMS key for EKS cluster encryption"
  deletion_window_in_days = 7

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-kms-key"
  })
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.cluster_name}-kms-key"
  target_key_id = aws_kms_key.eks.key_id
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  vpc_id                                   = var.vpc_id
  subnet_ids                               = var.subnet_ids
  endpoint_public_access                   = var.endpoint_public_access
  endpoint_private_access                  = var.endpoint_private_access
  endpoint_public_access_cidrs             = var.public_access_cidrs
  enable_cluster_creator_admin_permissions = true

  # Enable cluster logging
  enabled_log_types                      = var.cluster_log_types
  cloudwatch_log_group_retention_in_days = var.cluster_log_retention_days

  # Cluster encryption
  encryption_config = {
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }

  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    main = {
      name = "main-nodes"

      instance_types = var.instance_types
      ami_type       = var.ami_type
      capacity_type  = var.capacity_type
      disk_size      = var.disk_size

      min_size     = var.min_size
      max_size     = var.max_size
      desired_size = var.desired_size

      update_config = {
        max_unavailable = var.max_unavailable
      }

      # Use the private subnets for node groups
      subnet_ids = var.subnet_ids
    }
  }

  tags = var.common_tags
}