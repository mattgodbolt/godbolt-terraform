resource "aws_ses_domain_identity" "xania" {
  domain = "xania.org"
}

resource "aws_ses_domain_dkim" "xania" {
  domain = aws_ses_domain_identity.xania.domain
}

resource "aws_route53_record" "xania" {
  count   = 3
  zone_id = aws_route53_zone.xania.id
  name    = "${aws_ses_domain_dkim.xania.dkim_tokens[count.index]}._domainkey"
  type    = "CNAME"
  ttl     = "600"
  records = ["${aws_ses_domain_dkim.xania.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

resource "aws_iam_user" "smtp_user" {
  name = "smtp_user"
}

resource "aws_iam_access_key" "smtp_user" {
  user = aws_iam_user.smtp_user.name
}

data "aws_iam_policy_document" "ses_sender" {
  statement {
    actions   = ["ses:SendRawEmail"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ses_sender" {
  name        = "ses_sender"
  description = "Allows sending of e-mails via Simple Email Service"
  policy      = data.aws_iam_policy_document.ses_sender.json
}

resource "aws_iam_user_policy_attachment" "smtp_user" {
  user       = aws_iam_user.smtp_user.name
  policy_arn = aws_iam_policy.ses_sender.arn
}

resource "aws_ssm_parameter" "smtp_user" {
  name  = "smtp_user"
  type  = "String"
  value = aws_iam_access_key.smtp_user.id
}

resource "aws_ssm_parameter" "smtp_password" {
  name  = "smtp_password"
  type  = "String"
  value = aws_iam_access_key.smtp_user.ses_smtp_password_v4
}

resource "aws_ses_email_identity" "matt-at-godbolt-org" {
  email = "matt@godbolt.org"
}

resource "aws_ses_email_identity" "xania-server-admin" {
  email = "xania-server-admin@googlegroups.com"
}