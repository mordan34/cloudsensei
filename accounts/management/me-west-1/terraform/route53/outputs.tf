output "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "hosted_zone_arn" {
  description = "Route53 hosted zone ARN"
  value       = aws_route53_zone.main.arn
}

output "name_servers" {
  description = "A list of name servers in associated (or default) delegation set"
  value       = aws_route53_zone.main.name_servers
}

output "domain_name" {
  description = "The domain name of the hosted zone"
  value       = aws_route53_zone.main.name
}

output "hosted_zone_comment" {
  description = "The comment of the hosted zone"
  value       = aws_route53_zone.main.comment
}

output "health_check_id" {
  description = "The health check ID (if enabled)"
  value       = var.enable_health_check ? aws_route53_health_check.main[0].id : null
}

output "health_check_arn" {
  description = "The health check ARN (if enabled)"
  value       = var.enable_health_check ? aws_route53_health_check.main[0].arn : null
}

output "default_a_record_name" {
  description = "The name of the default A record (if created)"
  value       = var.create_default_a_record ? aws_route53_record.default_a[0].name : null
}

output "www_cname_record_name" {
  description = "The name of the www CNAME record (if created)"
  value       = var.create_www_cname ? aws_route53_record.www_cname[0].name : null
}

output "zone_tags" {
  description = "Tags applied to the hosted zone"
  value       = aws_route53_zone.main.tags
}