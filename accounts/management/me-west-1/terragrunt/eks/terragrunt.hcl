# Terragrunt configuration for EKS Cluster
terraform {
  source = "../../../terraform/me-west-1/eks"
}

# Include all settings from the root terragrunt.hcl file
include "root" {
  path = find_in_parent_folders()
}

# Dependencies - EKS depends on VPC/network
dependency "network" {
  config_path = "../network"
  
  mock_outputs = {
    vpc_id             = "vpc-fake-id"
    vpc_cidr_block     = "10.0.0.0/16"
    private_subnet_ids = ["subnet-fake-private-1", "subnet-fake-private-2"]
    public_subnet_ids  = ["subnet-fake-public-1", "subnet-fake-public-2"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# Generate provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "me-west-1"
  
  default_tags {
    tags = {
      Project     = "cloudsensei"
      Environment = "management"
      Region      = "me-west-1"
      ManagedBy   = "terragrunt"
    }
  }
}

provider "tls" {
  # Configuration options
}
EOF
}

# Configure remote state
remote_state {
  backend = "s3"
  config = {
    bucket  = "cloudsensei-terraform-state-${get_aws_account_id()}"
    key     = "${path_relative_to_include()}/terraform.tfstate"
    region  = "me-west-1"
    encrypt = true
    
    dynamodb_table = "cloudsensei-terraform-locks"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
}

# Input variables
inputs = {
  cluster_name       = "cloudsensei-mgmt-eks"
  kubernetes_version = "1.28"
  aws_region         = "me-west-1"
  
  # Remote state configuration
  remote_state_bucket = "cloudsensei-terraform-state-${get_aws_account_id()}"
  network_state_key   = "accounts/management/terragrunt/me-west-1/network"
  
  # Cluster endpoint configuration
  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs     = ["0.0.0.0/0"]
  
  # Logging configuration
  cluster_log_types           = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cluster_log_retention_days  = 30
  
  # Node group configuration
  instance_types = ["t3.medium"]
  ami_type      = "AL2_x86_64"
  capacity_type = "ON_DEMAND"
  disk_size     = 50
  
  # Scaling configuration
  desired_size     = 2
  max_size        = 4
  min_size        = 1
  max_unavailable = 1
  
  # Tags
  common_tags = {
    Project     = "cloudsensei"
    Environment = "management"
    Region      = "me-west-1"
    ManagedBy   = "terragrunt"
    Component   = "eks"
  }
}