data "aws_acm_certificate" "godbolt-org" {
  domain      = "*.godbolt.org"
  most_recent = true
}
