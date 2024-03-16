resource "aws_s3_bucket" "www-xania-org" {
  bucket = "web.xania.org"
  tags = {
    Site = "xania"
  }
}

resource "aws_cloudfront_distribution" "www-xania-org" {
  origin {
    domain_name              = aws_s3_bucket.www-xania-org.bucket_domain_name
    origin_id                = "S3-${aws_s3_bucket.www-xania-org.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.www-xania-org.id
  }

  enabled          = true
  is_ipv6_enabled  = true
  retain_on_delete = true
  aliases = [
    "*.xania.org",
    "xania.org"
  ]
  default_root_object = "index.html"

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.xania-org.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

  http_version = "http2"

  default_cache_behavior {
    allowed_methods = [
      "HEAD",
      "GET",
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
    target_origin_id       = "S3-${aws_s3_bucket.www-xania-org.id}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  tags = {
    Site = "xania"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

// https://github.com/hashicorp/terraform-provider-aws/issues/30105#issuecomment-1474431141
resource "aws_cloudfront_origin_access_control" "www-xania-org" {
  name                              = "www.xania.org"
  description                       = "S3 access to cloudfront"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_iam_policy_document" "www-xania-org" {
  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = [format("arn:aws:s3:::%s/*", aws_s3_bucket.www-xania-org.bucket)]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values = [
        format(
          "arn:aws:cloudfront::%s:distribution/%s",
          data.aws_caller_identity.this.account_id,
          aws_cloudfront_distribution.www-xania-org.id
        )
      ]
    }
  }
}
resource "aws_s3_bucket_policy" "www-xania-org" {
  bucket = aws_s3_bucket.www-xania-org.bucket
  policy = data.aws_iam_policy_document.www-xania-org.json
}
