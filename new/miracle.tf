module miracle {
  source = "./website"
  bucket = "miracle.xania.org"
  aliases = [
    "miracle.xania.org"
  ]
  deploy_user = "deploy-miracle"
  tags = {
    Site = "miracle"
  }
  certificate = aws_acm_certificate.xania-org.arn
}

output "deploy_miracle_id" {
  value = module.miracle.deploy_id
}

output "deploy_miracle_secret" {
  value     = module.miracle.deploy_secret
  sensitive = true
}

resource "aws_route53_record" "miracle" {
  for_each = {
    a    = "A"
    aaaa = "AAAA"
  }
  zone_id = aws_route53_zone.xania.zone_id
  name    = "miracle.xania.org"
  type    = each.value
  alias {
    name                   = module.miracle.domain_name
    zone_id                = module.miracle.hosted_zone_id
    evaluate_target_health = false
  }
}
