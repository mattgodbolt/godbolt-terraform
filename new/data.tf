data "aws_acm_certificate" "xania-org" {
  domain      = "xania.org"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
  provider    = aws.virginia # Certificates have to be in us-east-1 for cloudfront
}
