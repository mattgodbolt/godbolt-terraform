output "domain_name" {
  value = aws_cloudfront_distribution.distribution.domain_name
}

output "hosted_zone_id" {
    value = aws_cloudfront_distribution.distribution.hosted_zone_id
}

output "deploy_id" {
  value = aws_iam_access_key.deploy.id
}

output "deploy_secret" {
  value     = aws_iam_access_key.deploy.secret
  sensitive = true
}
