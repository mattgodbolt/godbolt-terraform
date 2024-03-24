module "blog" {
  source = "./website"
  bucket = "web.xania.org"
  aliases = [
    "*.xania.org",
    "xania.org"
  ]
  deploy_user = "deploy-blog"
  tags = {
    Site = "xania"
  }
  certificate = aws_acm_certificate.xania-org.arn
}

output "deploy_blog_id" {
  value = module.blog.deploy_id
}

output "deploy_blog_secret" {
  value     = module.blog.deploy_secret
  sensitive = true
}

resource "aws_route53_record" "address" {
  for_each = {
    a    = "A"
    aaaa = "AAAA"
  }
  zone_id = aws_route53_zone.xania.zone_id
  name    = "xania.org"
  type    = each.value
  alias {
    name                   = module.blog.domain_name
    zone_id                = module.blog.hosted_zone_id
    evaluate_target_health = false
  }
}


resource "aws_route53_record" "wildcard" {
  zone_id = aws_route53_zone.xania.zone_id
  name    = "*"
  type    = "CNAME"
  records = [aws_route53_record.address["a"].fqdn]
  ttl     = 360
}
