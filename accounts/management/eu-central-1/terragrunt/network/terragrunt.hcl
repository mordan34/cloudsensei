# Terragrunt configuration for VPC/Network
terraform {
  source = "../../terraform/network"
}

# Include all settings from the root terragrunt.hcl file
include "root" {
  path = find_in_parent_folders()
}

# Input variables
inputs = {
  name_prefix              = "cloudsensei-mgmt"
  
  vpc_cidr                 = "10.0.0.0/16"
  
  public_subnet_count      = 2
  private_subnet_count     = 2
  
  public_subnet_cidrs      = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  
  enable_nat_gateway = true
  nat_gateway_count  = 2
  
  common_tags = {
    Project     = "cloudsensei"
    Environment = "management"
    Region      = "eu-central-1"
    ManagedBy   = "terragrunt"
    Component   = "network"
  }
}