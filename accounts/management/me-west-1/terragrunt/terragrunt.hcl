# Root terragrunt configuration for the management account

# Configure Terragrunt to automatically store tfstate files in an S3 bucket
remote_state {
  backend = "s3"
  config = {
    encrypt        = true
    bucket         = "cloudsensei-terraform-state-${get_aws_account_id()}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "me-west-1"
    dynamodb_table = "cloudsensei-terraform-locks"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
}

# Configure retry settings
retryable_errors = [
  "(?s).*Error.*RequestError: send request failed.*",
  "(?s).*Error.*connection reset by peer.*",
  "(?s).*Error.*TLS handshake timeout.*",
]

retry_max_attempts       = 3
retry_sleep_interval_sec = 5

# Generate the AWS provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0"
}

provider "aws" {
  region = "me-west-1"
  
  default_tags {
    tags = {
      Project     = "cloudsensei"
      Environment = "management"
      ManagedBy   = "terragrunt"
    }
  }
}
EOF
}

# Global inputs that will be merged with the child terragrunt.hcl inputs
inputs = {
  aws_region = "me-west-1"
  
  common_tags = {
    Project     = "cloudsensei"
    Environment = "management"
    Region      = "me-west-1"
    ManagedBy   = "terragrunt"
  }
}