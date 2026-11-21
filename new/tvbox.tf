# tvbox (lounge NUC, A record in dns.tf) gets a Let's Encrypt cert for
# tvbox.xania.org via certbot's Route 53 DNS-01 plugin, so its phone remote can
# be served over HTTPS and installed as an app. The address is private, so
# HTTP-01 can't work.
#
# This user may only touch the _acme-challenge TXT record for tvbox. Its
# access key is created out of band (aws iam create-access-key) and lives only
# on tvbox, so it never lands in terraform state.
resource "aws_iam_user" "tvbox_certbot" {
  name = "tvbox-certbot"
}

data "aws_iam_policy_document" "tvbox_certbot" {
  statement {
    actions   = ["route53:ChangeResourceRecordSets"]
    resources = [aws_route53_zone.xania.arn]
    condition {
      test     = "ForAllValues:StringEquals"
      variable = "route53:ChangeResourceRecordSetsNormalizedRecordNames"
      values   = ["_acme-challenge.tvbox.xania.org"]
    }
    condition {
      test     = "ForAllValues:StringEquals"
      variable = "route53:ChangeResourceRecordSetsRecordTypes"
      values   = ["TXT"]
    }
  }
  statement {
    actions   = ["route53:GetChange"]
    resources = ["arn:aws:route53:::change/*"]
  }
  statement {
    # certbot-dns-route53 finds the zone by listing them.
    actions   = ["route53:ListHostedZones"]
    resources = ["*"]
  }
}

resource "aws_iam_user_policy" "tvbox_certbot" {
  name   = "tvbox-certbot-acme-dns"
  user   = aws_iam_user.tvbox_certbot.name
  policy = data.aws_iam_policy_document.tvbox_certbot.json
}
