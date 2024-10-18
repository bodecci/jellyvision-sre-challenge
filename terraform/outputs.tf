# Output for the ACM Certificate ARN
# Output for the ACM Certificate ARN
output "jv_magic_certificate_arn" {
  description = "The ARN of the ACM Certificate for jv-magic.com"
  value       = data.aws_acm_certificate.jv_magic_cert.arn
}

# Output for the Route53 Hosted Zone ID
output "jv_magic_zone_id" {
  description = "The Route53 Hosted Zone ID for jv-magic.com"
  value       = data.aws_route53_zone.jv_magic_zone.zone_id
}
