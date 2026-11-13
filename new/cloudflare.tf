# Cloudflare hosts DNS for godbolt.net (the registration itself is in godbolt-net.tf) and fronts the home
# services (via Tunnel + Access) that live at <name>.godbolt.net.
locals {
  cloudflare_account_id = "c25bd569a4958f358eeae660295a0b6c"
}

import {
  to = cloudflare_zone.godbolt-net
  id = "53d9c6d9ba780e0093a99df9958e8389"
}

resource "cloudflare_zone" "godbolt-net" {
  account = {
    id = local.cloudflare_account_id
  }
  name = "godbolt.net"
  type = "full"
}
