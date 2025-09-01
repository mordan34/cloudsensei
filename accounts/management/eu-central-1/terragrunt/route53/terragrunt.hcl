# Terragrunt configuration for Route53 Hosted Zone
terraform {
  source = "../../terraform/route53"
}

# Include all settings from the root terragrunt.hcl file
include "root" {
  path = find_in_parent_folders()
}

# Input variables
inputs = {
  name_prefix = "cloudsensei-mgmt"
  
  domain_name = "cloud-sensei.com"
  hosted_zone_comment = "Public hosted zone for CloudSensei domain - Management Account"
  
  # Set to true only if you want to destroy the zone even with records
  force_destroy = false
  
  # Health check configuration (disabled by default)
  enable_health_check = false
  health_check_port = 443
  health_check_type = "HTTPS"
  health_check_path = "/"
  
  # Default records (disabled by default - add when you have infrastructure)
  create_default_a_record = false
  default_a_record_ips = []
  
  create_www_cname = false
  default_record_ttl = 300
  
  aws_region = "eu-central-1"
  
  common_tags = {
    Project     = "cloudsensei"
    Environment = "management"
    Region      = "eu-central-1"
    ManagedBy   = "terragrunt"
    Component   = "route53"
    Domain      = "cloudsensei.com"
  }
}