resource "aws_s3_bucket" "bbc-xania-org" {
  bucket = "bbc.xania.org"

  tags = {
    Site = "jsbeeb"
  }

  cors_rule {
    allowed_headers = ["Authorization"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}

locals {
  jsbeeb_prod_origin_id = "S3-bbc.xania.org"
  jsbeeb_beta_origin_id = "S3-bbc.xania.org/beta"
}

resource "aws_cloudfront_distribution" "bbc-xania-org" {
  origin {
    domain_name              = aws_s3_bucket.bbc-xania-org.bucket_domain_name
    origin_id                = local.jsbeeb_prod_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.bbc-xania-org.id
  }
  origin {
    domain_name              = aws_s3_bucket.bbc-xania-org.bucket_domain_name
    origin_id                = local.jsbeeb_beta_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.bbc-xania-org.id
    origin_path              = "/beta"
  }

  enabled          = true
  is_ipv6_enabled  = true
  retain_on_delete = true
  aliases = [
    "bbc.xania.org",
    "master.xania.org"
  ]
  default_root_object = "index.html"

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.xania-org.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

  http_version = "http2"


  # Beta site
  ordered_cache_behavior {
    allowed_methods = [
      "HEAD",
      "DELETE",
      "POST",
      "GET",
      "OPTIONS",
      "PUT",
      "PATCH"
    ]
    cached_methods = [
      "HEAD",
      "GET"
    ]
    forwarded_values {
      cookies {
        forward = "none"
      }
      query_string = false
    }
    path_pattern           = "/beta*"
    target_origin_id       = local.jsbeeb_beta_origin_id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  # Main site
  default_cache_behavior {
    allowed_methods = [
      "HEAD",
      "DELETE",
      "POST",
      "GET",
      "OPTIONS",
      "PUT",
      "PATCH"
    ]
    cached_methods = [
      "HEAD",
      "GET"
    ]
    forwarded_values {
      cookies {
        forward = "none"
      }
      query_string = false
    }
    target_origin_id       = local.jsbeeb_prod_origin_id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  tags = {
    Site = "jsbeeb"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}


// https://github.com/hashicorp/terraform-provider-aws/issues/30105#issuecomment-1474431141
resource "aws_cloudfront_origin_access_control" "bbc-xania-org" {
  name                              = "bbc.xania.org"
  description                       = "S3 access to cloudfront"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_iam_policy_document" "bbc-xania-org" {
  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = [format("arn:aws:s3:::%s/*", aws_s3_bucket.bbc-xania-org.bucket)]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values = [
        format(
          "arn:aws:cloudfront::%s:distribution/%s",
          data.aws_caller_identity.this.account_id,
          aws_cloudfront_distribution.bbc-xania-org.id
        )
      ]
    }
  }
}
resource "aws_s3_bucket_policy" "bbc-xania-org" {
  bucket = aws_s3_bucket.bbc-xania-org.bucket
  policy = data.aws_iam_policy_document.bbc-xania-org.json
}


resource "aws_iam_user" "deploy-jsbeeb" {
  name = "deploy-jsbeeb"
}

data "aws_iam_policy_document" "bbc-xania-org-rw" {
  statement {
    sid     = "S3AccessSid"
    actions = ["s3:*"]
    resources = [
      "${aws_s3_bucket.bbc-xania-org.arn}/*",
      aws_s3_bucket.bbc-xania-org.arn
    ]
  }
}

resource "aws_iam_policy" "deploy-jsbeeb" {
  name        = "deploy-jsbeeb"
  description = "Can create resource in bbc.xania.org bucket"
  policy      = data.aws_iam_policy_document.bbc-xania-org-rw.json
}

resource "aws_iam_user_policy_attachment" "deploy-jsbeeb" {
  user       = aws_iam_user.deploy-jsbeeb.name
  policy_arn = aws_iam_policy.deploy-jsbeeb.arn
}

resource "aws_iam_access_key" "deploy-jsbeeb" {
  user = aws_iam_user.deploy-jsbeeb.name
}

output "deploy_jsbeeb_id" {
  value = aws_iam_access_key.deploy-jsbeeb.id
}

output "deploy_jsbeeb_secret" {
  value     = aws_iam_access_key.deploy-jsbeeb.secret
  sensitive = true
}