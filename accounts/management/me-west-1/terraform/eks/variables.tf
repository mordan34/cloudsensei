variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "cloudsensei-mgmt-eks"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "me-west-1"
}

variable "remote_state_bucket" {
  description = "S3 bucket for remote state"
  type        = string
}

variable "network_state_key" {
  description = "State key for network module"
  type        = string
  default     = "accounts/management/terraform/me-west-1/network"
}

# Cluster Configuration
variable "endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_log_types" {
  description = "List of control plane logging to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cluster_log_retention_days" {
  description = "Retention period for cluster logs"
  type        = number
  default     = 30
}

# Node Group Configuration
variable "instance_types" {
  description = "List of instance types for the node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "ami_type" {
  description = "Type of Amazon Machine Image (AMI) associated with the EKS Node Group"
  type        = string
  default     = "AL2_x86_64"
}

variable "ami_id" {
  description = "AMI ID for the launch template. If not provided, will use the default EKS optimized AMI"
  type        = string
  default     = null
}

variable "capacity_type" {
  description = "Type of capacity associated with the EKS Node Group. Valid values: ON_DEMAND, SPOT"
  type        = string
  default     = "ON_DEMAND"
}

variable "disk_size" {
  description = "Disk size in GiB for worker nodes"
  type        = number
  default     = 50
}

# Scaling Configuration
variable "desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "max_unavailable" {
  description = "Maximum number of nodes unavailable at once during a version update"
  type        = number
  default     = 1
}

# Tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "cloudsensei"
    Environment = "management"
    Region      = "me-west-1"
    ManagedBy   = "terraform"
  }
}