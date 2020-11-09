data "aws_acm_certificate" "godbolt-org" {
  domain      = "godbolt.org"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}
