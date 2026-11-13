# Home services published as <name>.godbolt.net: one tunnel to phoenix, one wildcard DNS record, and one wildcard
# Access application so anything new is behind the Google login by default. phoenix's nginx routes by Host header.
# Exceptions (e.g. a PWA manifest or a service-token client) are more specific Access applications.

resource "cloudflare_zero_trust_tunnel_cloudflared" "phoenix" {
  account_id = local.cloudflare_account_id
  name       = "phoenix"
  config_src = "cloudflare"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "phoenix" {
  account_id = local.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.phoenix.id
  config = {
    ingress = [
      # nudge listens on loopback only, so go straight to it: no LAN-reachable hop where headers could be forged.
      { hostname = "nudge.godbolt.net", service = "http://localhost:4517" },
      { hostname = "*.godbolt.net", service = "http://localhost:80" },
      { service = "http_status:404" },
    ]
  }
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "phoenix" {
  account_id = local.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.phoenix.id
}

output "phoenix_tunnel_token" {
  value     = data.cloudflare_zero_trust_tunnel_cloudflared_token.phoenix.token
  sensitive = true
}

resource "cloudflare_dns_record" "wildcard" {
  zone_id = cloudflare_zone.godbolt-net.id
  name    = "*"
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.phoenix.id}.cfargotunnel.com"
  proxied = true
  ttl     = 1
}

# OAuth client from the Google Cloud console (internal consent screen, so only godbolt.org accounts can sign in).
# Authorized redirect URI: https://godbolt-family.cloudflareaccess.com/cdn-cgi/access/callback
# The id and secret live in a chmod 600 file outside the repo: the JSON exactly as downloaded from Google
# ({"web": {"client_id": ..., "client_secret": ...}}) or a flat {"client_id": ..., "client_secret": ...}.
locals {
  google_oauth_file = jsondecode(file(pathexpand("~/.config/cloudflare/google-oauth.json")))
  google_oauth      = try(local.google_oauth_file.web, local.google_oauth_file)
}

resource "cloudflare_zero_trust_access_identity_provider" "google" {
  account_id = local.cloudflare_account_id
  name       = "Google (godbolt.org)"
  type       = "google"
  config = {
    client_id     = local.google_oauth.client_id
    client_secret = local.google_oauth.client_secret
  }
}

resource "cloudflare_zero_trust_access_policy" "godbolt_org" {
  account_id = local.cloudflare_account_id
  name       = "Anyone with a godbolt.org account"
  decision   = "allow"
  include = [
    { email_domain = { domain = "godbolt.org" } },
  ]
}

resource "cloudflare_zero_trust_access_application" "wildcard" {
  account_id                = local.cloudflare_account_id
  name                      = "All godbolt.net services"
  domain                    = "*.godbolt.net"
  type                      = "self_hosted"
  session_duration          = "168h"
  allowed_idps              = [cloudflare_zero_trust_access_identity_provider.google.id]
  auto_redirect_to_identity = true
  policies = [
    { id = cloudflare_zero_trust_access_policy.godbolt_org.id, precedence = 1 },
  ]
}

# nudge is for Matt only: a more specific application than the wildcard, so its policy replaces the org-wide one.
resource "cloudflare_zero_trust_access_policy" "matt_only" {
  account_id = local.cloudflare_account_id
  name       = "Matt only"
  decision   = "allow"
  include = [
    { email = { email = "matt@godbolt.org" } },
  ]
}

resource "cloudflare_zero_trust_access_application" "nudge" {
  account_id                = local.cloudflare_account_id
  name                      = "nudge"
  domain                    = "nudge.godbolt.net"
  type                      = "self_hosted"
  session_duration          = "720h"
  allowed_idps              = [cloudflare_zero_trust_access_identity_provider.google.id]
  auto_redirect_to_identity = true
  policies = [
    { id = cloudflare_zero_trust_access_policy.matt_only.id, precedence = 1 },
  ]
}

# The JWT audience for nudge's server-side verification of Cf-Access-Jwt-Assertion.
output "nudge_access_aud" {
  value = cloudflare_zero_trust_access_application.nudge.aud
}

# A browser fetches the PWA manifest, service worker and icons without credentials, so Access would redirect them to
# the login page and break "install". These exact paths bypass Access; nudge itself serves only these (GET/HEAD) to
# the Access host without a verified token (ACCESS_PUBLIC_PATHS in nudge's server/security.ts) and rejects the rest.
locals {
  nudge_public_paths = [
    "/manifest.webmanifest",
    "/sw.js",
    "/favicon.svg",
    "/icon-192.png",
    "/icon-512.png",
    "/icon-maskable-512.png",
    "/badge-96.png",
    "/logo-120.png",
  ]
}

resource "cloudflare_zero_trust_access_policy" "public_bypass" {
  account_id = local.cloudflare_account_id
  name       = "Public static files"
  decision   = "bypass"
  include = [
    { everyone = {} },
  ]
}

resource "cloudflare_zero_trust_access_application" "nudge_public" {
  account_id = local.cloudflare_account_id
  name       = "nudge static files"
  type       = "self_hosted"
  destinations = [
    for p in local.nudge_public_paths : { type = "public", uri = "nudge.godbolt.net${p}" }
  ]
  policies = [
    { id = cloudflare_zero_trust_access_policy.public_bypass.id, precedence = 1 },
  ]
}
