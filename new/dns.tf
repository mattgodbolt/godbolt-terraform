# resource "aws_route53_zone" "xania" {
#   name    = "xania"
#   comment = "xania.org domain"
# }

# # well, poo, RIP dyndns
# # resource "aws_route53_record" "home" {
# #       name    = "home"
# #   zone_id = aws_route53_zone.xania.zone_id
# #   type    = "A"
# #   ttl = 60
# #   records = ["168.91.230.10"]
# # }

# # TODO: xania.org alias

# resource "aws_route53_record" "beebide" {
#   for_each = {
#     a    = "A"
#     aaaa = "AAAA"
#   }
#   zone_id = aws_route53_zone.xania.zone_id
#   name    = "beebide.xania.org"
#   type    = each.value
#   alias {
#     name                   = aws_cloudfront_distribution.beebide-xania-org.domain_name
#     zone_id                = aws_cloudfront_distribution.beebide-xania-org.hosted_zone_id
#     evaluate_target_health = false
#   }
# }


# resource "aws_route53_record" "www" {
#   for_each = {
#     a    = "A"
#     aaaa = "AAAA"
#   }
#   zone_id = aws_route53_zone.xania.zone_id
#   name    = "www.xania.org"
#   type    = each.value
#   alias {
#     name                   = aws_cloudfront_distribution.www-xania-org.domain_name
#     zone_id                = aws_cloudfront_distribution.www-xania-org.hosted_zone_id
#     evaluate_target_health = false
#   }
# }

# TODO emails etc