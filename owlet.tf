data "aws_iam_policy_document" "owlet-bucket-policy" {
  statement {
    principals {
      identifiers = ["*"]
      type        = "*"
    }
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]

    resources = [
      "arn:aws:s3:::owlet.godbolt.org/*",
    ]
  }
}

resource "aws_s3_bucket" "owlet-godbolt-org" {
  bucket = "owlet.godbolt.org"
  acl    = "private"

  tags = {
    Site = "owlet"
  }

  policy = data.aws_iam_policy_document.owlet-bucket-policy.json

  website {
    index_document = "index.html"
  }
}

locals {
  owlet_origin_id = "S3-owlet.godbolt.org"
}

resource "aws_cloudfront_distribution" "owlet-godbolt-org" {
  origin {
    domain_name = aws_s3_bucket.owlet-godbolt-org.bucket_domain_name
    origin_id   = local.owlet_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  retain_on_delete    = true
  aliases             = [
    "owlet.godbolt.org"
  ]
  default_root_object = "index.html"

  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.godbolt-org.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

  http_version = "http2"

  # Main site
  default_cache_behavior {
    allowed_methods        = [
      "HEAD",
      "DELETE",
      "POST",
      "GET",
      "OPTIONS",
      "PUT",
      "PATCH"
    ]
    cached_methods         = [
      "HEAD",
      "GET"
    ]
    forwarded_values {
      cookies {
        forward = "none"
      }
      query_string = false
    }
    target_origin_id       = local.owlet_origin_id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  tags = {
    Site = "owlet"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}
