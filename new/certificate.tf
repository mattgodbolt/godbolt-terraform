resource "aws_acm_certificate" "xania-org" {
  domain_name       = "xania.org"
  validation_method = "DNS"

  subject_alternative_names = [
    "*.xania.org"
  ]

  lifecycle {
    create_before_destroy = true
  }
  provider = aws.virginia # Certificates have to be in us-east-1 for cloudfront
}