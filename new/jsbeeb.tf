module "jsbeeb" {
  source = "./website"
  bucket = "bbc.xania.org"
  aliases = [
    "bbc.xania.org",
    "master.xania.org",
    "atom.xania.org"
  ]
  deploy_user = "deploy-jsbeeb"
  tags = {
    Site = "jsbeeb"
  }
  certificate = aws_acm_certificate.xania-org.arn
  // archive/ holds the mirrored Stairway to Hell software archive, which is
  // scraped from a third-party site rather than built from the repo. The deploy
  // may refresh it, but must never delete from it. See jsbeeb's
  // tools/README-sth-mirror.md.
  protected_prefixes = ["archive/*"]
}

output "deploy_jsbeeb_id" {
  value = module.jsbeeb.deploy_id
}

output "deploy_jsbeeb_secret" {
  value     = module.jsbeeb.deploy_secret
  sensitive = true
}

resource "aws_route53_record" "jsbeeb" {
  for_each = {
    a    = "A"
    aaaa = "AAAA"
  }
  zone_id = aws_route53_zone.xania.zone_id
  name    = "bbc.xania.org"
  type    = each.value
  alias {
    name                   = module.jsbeeb.domain_name
    zone_id                = module.jsbeeb.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "jsbeeb-master" {
  zone_id = aws_route53_zone.xania.zone_id
  name    = "master"
  type    = "CNAME"
  records = ["bbc.xania.org"]
  ttl     = 360
}

resource "aws_route53_record" "jsbeeb-atom" {
  zone_id = aws_route53_zone.xania.zone_id
  name    = "atom"
  type    = "CNAME"
  records = ["bbc.xania.org"]
  ttl     = 360
}
