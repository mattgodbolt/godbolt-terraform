resource "aws_s3_bucket" "beebide-godbolt-org" {
  bucket = "beebide.godbolt.org"
  acl    = "public-read"

  tags = {
    Site = "beebide"
  }

  website {
    index_document = "index.html"
  }
}

locals {
  beebide_origin_id = "S3-beebide.godbolt.org"
}

resource "aws_cloudfront_distribution" "beebide-godbolt-org" {
  origin {
    domain_name = aws_s3_bucket.beebide-godbolt-org.bucket_domain_name
    origin_id   = local.beebide_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  retain_on_delete    = true
  aliases             = [
    "beebide.godbolt.org"
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
