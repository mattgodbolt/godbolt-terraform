module "spectrum" {
  source = "./website"
  bucket = "spectrum.xania.org"
  aliases = [
    "spectrum.xania.org"
  ]
  deploy_user = "deploy-spectrum"
  tags = {
    Site = "spectrum"
  }
  certificate = aws_acm_certificate.xania-org.arn
}

output "deploy_spectrum_id" {
  value = module.spectrum.deploy_id
}

output "deploy_spectrum_secret" {
  value     = module.spectrum.deploy_secret
  sensitive = true
}

resource "aws_route53_record" "spectrum" {
  for_each = {
    a    = "A"
    aaaa = "AAAA"
  }
  zone_id = aws_route53_zone.xania.zone_id
  name    = "spectrum.xania.org"
  type    = each.value
  alias {
    name                   = module.spectrum.domain_name
    zone_id                = module.spectrum.hosted_zone_id
    evaluate_target_health = false
  }
}
