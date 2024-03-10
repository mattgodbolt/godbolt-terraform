data "aws_acm_certificate" "godbolt-org" {
  domain      = "godbolt.org"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}
data "aws_acm_certificate" "xania-org" {
  domain      = "xania.org"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}
