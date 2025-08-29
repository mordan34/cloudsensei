# Terragrunt configuration for VPC/Network
terraform {
  source = "."
}

# Include all settings from the root terragrunt.hcl file
include "root" {
  path = find_in_parent_folders()
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
  name_prefix = "cloudsensei-mgmt"
  
  vpc_cidr = "10.0.0.0/16"
  
  public_subnet_count  = 2
  private_subnet_count = 2
  
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  
  enable_nat_gateway = true
  nat_gateway_count  = 2
  
  common_tags = {
    Project     = "cloudsensei"
    Environment = "management"
    Region      = "me-west-1"
    ManagedBy   = "terragrunt"
    Component   = "network"
  }
}