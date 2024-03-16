resource "aws_s3_bucket" "beebide-xania-org" {
  bucket = "beebide.xania.org"

  tags = {
    Site = "beebide"
  }
}

locals {
  beebide_origin_id = "S3-beebide.xania.org"
}

resource "aws_cloudfront_distribution" "beebide-xania-org" {
  origin {
    domain_name              = aws_s3_bucket.beebide-xania-org.bucket_domain_name
    origin_id                = local.beebide_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.beebide-xania-org.id
  }

  enabled          = true
  is_ipv6_enabled  = true
  retain_on_delete = true
  aliases = [
    "beebide.xania.org"
  ]
  default_root_object = "index.html"

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.xania-org.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

  http_version = "http2"

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
    target_origin_id       = local.beebide_origin_id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  tags = {
    Site = "beebide"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

// https://github.com/hashicorp/terraform-provider-aws/issues/30105#issuecomment-1474431141
resource "aws_cloudfront_origin_access_control" "beebide-xania-org" {
  name                              = "beebide.xania.org"
  description                       = "S3 access to cloudfront"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_iam_policy_document" "beebide-xania-org" {
  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = [format("arn:aws:s3:::%s/*", aws_s3_bucket.beebide-xania-org.bucket)]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values = [
        format(
          "arn:aws:cloudfront::%s:distribution/%s",
          data.aws_caller_identity.this.account_id,
          aws_cloudfront_distribution.beebide-xania-org.id
        )
      ]
    }
  }
}
resource "aws_s3_bucket_policy" "beebide-xania-org" {
  bucket = aws_s3_bucket.beebide-xania-org.bucket
  policy = data.aws_iam_policy_document.beebide-xania-org.json
}
