# Configure the AWS Provider
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Route53 Hosted Zone
resource "aws_route53_zone" "main" {
  name          = var.domain_name
  comment       = var.hosted_zone_comment
  force_destroy = var.force_destroy

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-${replace(var.domain_name, ".", "-")}-zone"
    Type = "Public"
  })
}

# Health Check (optional)
resource "aws_route53_health_check" "main" {
  count = var.enable_health_check ? 1 : 0

  fqdn                            = var.domain_name
  port                           = var.health_check_port
  type                           = var.health_check_type
  resource_path                  = var.health_check_path
  failure_threshold              = var.health_check_failure_threshold
  request_interval               = var.health_check_request_interval
  cloudwatch_alarm_region        = var.aws_region
  cloudwatch_alarm_name          = "${var.name_prefix}-${replace(var.domain_name, ".", "-")}-health-check"
  insufficient_data_health_status = "Failure"

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-${replace(var.domain_name, ".", "-")}-health-check"
  })
}

# Default A record (optional)
resource "aws_route53_record" "default_a" {
  count = var.create_default_a_record ? 1 : 0

  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = var.default_record_ttl
  records = var.default_a_record_ips

  depends_on = [aws_route53_zone.main]
}

# WWW CNAME record (optional)
resource "aws_route53_record" "www_cname" {
  count = var.create_www_cname ? 1 : 0

  zone_id = aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "CNAME"
  ttl     = var.default_record_ttl
  records = [var.domain_name]

  depends_on = [aws_route53_zone.main]
}