resource "aws_route53_zone" "xania" {
  name    = "xania.org"
  comment = "xania.org domain"
}

resource "aws_route53domains_registered_domain" "xania" {
  domain_name = "xania.org"

  dynamic "name_server" {
    for_each = toset(aws_route53_zone.xania.name_servers)
    content {
      name = name_server.value
    }
  }
}

resource "aws_route53_record" "acm" {
  for_each = {
    for dvo in aws_acm_certificate.xania-org.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  zone_id         = aws_route53_zone.xania.zone_id
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
}

# # well, poo, RIP dyndns
# # resource "aws_route53_record" "home" {
# #       name    = "home"
# #   zone_id = aws_route53_zone.xania.zone_id
# #   type    = "A"
# #   ttl = 60
# #   records = ["168.91.230.10"]
# # }

resource "aws_route53_record" "phoenix" {
  name    = "phoenix"
  zone_id = aws_route53_zone.xania.zone_id
  type    = "A"
  ttl     = 3600
  records = ["192.168.7.240"]
}

resource "aws_route53_record" "beebide" {
  for_each = {
    a    = "A"
    aaaa = "AAAA"
  }
  zone_id = aws_route53_zone.xania.zone_id
  name    = "beebide.xania.org"
  type    = each.value
  alias {
    name                   = aws_cloudfront_distribution.beebide-xania-org.domain_name
    zone_id                = aws_cloudfront_distribution.beebide-xania-org.hosted_zone_id
    evaluate_target_health = false
  }
}


resource "aws_route53_record" "spf" {
  zone_id = aws_route53_zone.xania.zone_id
  name    = ""
  type    = "TXT"
  ttl     = 3600
  records = [
    "v=spf1 include:_spf.google.com ~all",
    "v=DMARC1;p=none;sp=quarantine;rua=mailto:matt+dmarc@xania.org",
    "google-site-verification=uCqzvXJNW3IV25ZPjOmXyrTBA_dwzpo57znHNWU11s0",
    "google-site-verification=tU6ILlM2LbgGe0MLMVVGSe5IOVo8kPBbms10x1uXnZs"
  ]
}

resource "aws_route53_record" "mail" {
  name    = ""
  type    = "MX"
  ttl     = 3600
  zone_id = aws_route53_zone.xania.zone_id
  records = [
    "1 aspmx.l.google.com",
    "5 alt1.aspmx.l.google.com",
    "5 alt2.aspmx.l.google.com",
    "10 alt3.aspmx.l.google.com",
    "10 alt4.aspmx.l.google.com",
  ]
}
