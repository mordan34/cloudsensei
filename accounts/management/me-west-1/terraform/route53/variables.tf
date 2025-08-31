variable "name_prefix" {
  description = "Name prefix for all resources"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "The domain name for the hosted zone"
  type        = string
  default     = ""
}

variable "hosted_zone_comment" {
  description = "A comment for the hosted zone"
  type        = string
  default     = "Public hosted zone"
}

variable "force_destroy" {
  description = "Whether to destroy the hosted zone even if it contains records"
  type        = bool
  default     = true
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-central-1"
}

variable "enable_health_check" {
  description = "Whether to create a health check for the domain"
  type        = bool
  default     = false
}

variable "health_check_port" {
  description = "Port for health check"
  type        = number
  default     = 80
}

variable "health_check_type" {
  description = "Type of health check (HTTP, HTTPS, HTTP_STR_MATCH, HTTPS_STR_MATCH, TCP)"
  type        = string
  default     = "HTTP"
}

variable "health_check_path" {
  description = "Path for HTTP(S) health check"
  type        = string
  default     = "/"
}

variable "health_check_failure_threshold" {
  description = "Number of consecutive health check failures before considering unhealthy"
  type        = number
  default     = 3
}

variable "health_check_request_interval" {
  description = "Interval between health checks (30 or 10)"
  type        = number
  default     = 30
}

variable "create_default_a_record" {
  description = "Whether to create a default A record for the domain"
  type        = bool
  default     = false
}

variable "default_a_record_ips" {
  description = "List of IP addresses for the default A record"
  type        = list(string)
  default     = []
}

variable "create_www_cname" {
  description = "Whether to create a www CNAME record pointing to the domain"
  type        = bool
  default     = false
}

variable "default_record_ttl" {
  description = "TTL for default records"
  type        = number
  default     = 300
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "cloudsensei"
    Environment = "management"
    Region      = "eu-central-1"
    ManagedBy   = "terraform"
  }
}