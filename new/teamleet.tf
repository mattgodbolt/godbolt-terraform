# Route 53 hosted zone for teamleet.org
resource "aws_route53_zone" "teamleet" {
  name    = "teamleet.org"
  comment = "teamleet.org domain"
}

resource "aws_route53domains_registered_domain" "teamleet" {
  domain_name = "teamleet.org"

  dynamic "name_server" {
    for_each = toset(aws_route53_zone.teamleet.name_servers)
    content {
      name = name_server.value
    }
  }
}
