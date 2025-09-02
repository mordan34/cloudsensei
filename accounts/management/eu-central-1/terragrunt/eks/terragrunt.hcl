# Terragrunt configuration for EKS Cluster
terraform {
  source                      = "../../terraform/eks"
}

# Include all settings from the root terragrunt.hcl file
include "root" {
  path                        = find_in_parent_folders()
}

# Dependencies - EKS depends on VPC/network and Route53
dependency "network" {
  config_path                 = "../network"

  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
  mock_outputs                = {
    vpc_id                    = "vpc-mock123456"
    private_subnet_ids        = ["subnet-mock123", "subnet-mock456"]
  }
}

dependency "route53" {
  config_path                 = "../route53"

  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
  mock_outputs                = {
    domain_name               = "cloud-sensei.com"
    hosted_zone_id           = "Z123456789"
  }
}

# Input variables
inputs = {
  cluster_name                = "cloudsensei-mgmt-eks"
  kubernetes_version          = "1.32"
  aws_region                  = "eu-central-1"
  
  # Remote state configuration
  remote_state_bucket         = "cloudsensei-terraform-state-${get_aws_account_id()}"
  network_state_key           = "accounts/management/terragrunt/eu-central-1/network"
  
  # Cluster endpoint configuration
  endpoint_private_access     = true
  endpoint_public_access      = true
  public_access_cidrs         = ["0.0.0.0/0"]

  # network
  vpc_id                      = dependency.network.outputs.vpc_id
  subnet_ids                  = dependency.network.outputs.private_subnet_ids

  # route53
  domain_name                 = dependency.route53.outputs.domain_name

  # Logging configuration
  cluster_log_types           = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cluster_log_retention_days  = 30
  
  # Node group configuration
  instance_types              = ["t3.medium"]
  # ami_type                    = "AL2023_x86_64"
  capacity_type               = "ON_DEMAND"
  disk_size                   = 50
  
  # Scaling configuration
  desired_size                = 2
  max_size                    = 2
  min_size                    = 1
  max_unavailable             = 1
  
  # Tags
  common_tags                 = {
    Project                   = "cloudsensei"
    Environment               = "management"
    Region                    = "eu-central-1"
    ManagedBy                 = "terragrunt"
    Component                 = "eks"
  }
}