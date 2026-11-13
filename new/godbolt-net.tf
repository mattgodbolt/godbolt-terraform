# godbolt.net: registered at Route53 Domains in this account, DNS hosted at Cloudflare (zone 53d9c6d9ba780e0093a99df9958e8389).
# Rename to godbolt-net.tf ONLY after the registration has been transferred here from the CE account
# (aws route53domains transfer-domain-to-another-aws-account, then accept it with --profile xania); until then the
# import below fails and so does every plan in this directory.

import {
  to = aws_route53domains_registered_domain.godbolt-net
  id = "godbolt.net"
}

resource "aws_route53domains_registered_domain" "godbolt-net" {
  domain_name = "godbolt.net"

  # Cloudflare assigned these when the zone was added. Changing them is what moves DNS off Route53.
  name_server {
    name = "ed.ns.cloudflare.com"
  }
  name_server {
    name = "kay.ns.cloudflare.com"
  }
}
