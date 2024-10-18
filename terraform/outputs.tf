# Output for the ACM Certificate ARN
output "jv_magic_certificate_arn" {
  description = "The ARN of the validated ACM Certificate for jv-magic.com"
  value       = aws_acm_certificate_validation.jv_magic_cert_validated.certificate_arn
}

# Output for the Route53 Hosted Zone ID
output "jv_magic_zone_id" {
  description = "The Route53 Hosted Zone ID for jv-magic.com"
  value       = data.aws_route53_zone.jv_magic_zone.zone_id
}
