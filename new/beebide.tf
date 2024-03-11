resource "aws_s3_bucket" "beebide-xania-org" {
  bucket = "beebide.xania.org"

  tags = {
    Site = "beebide"
  }

  website {
    index_document = "index.html"
  }
}

locals {
  beebide_origin_id = "S3-beebide.xania.org"
}

resource "aws_cloudfront_distribution" "beebide-xania-org" {
  origin {
    domain_name = aws_s3_bucket.beebide-xania-org.bucket_domain_name
    origin_id   = local.beebide_origin_id
  }

  enabled          = true
  is_ipv6_enabled  = true
  retain_on_delete = true
  aliases = [
    "beebide.xania.org"
  ]
  default_root_object = "index.html"

  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.xania-org.arn
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

// https://stackoverflow.com/questions/76097031/aws-s3-bucket-cannot-have-acls-set-with-objectownerships-bucketownerenforced-s
resource "aws_s3_bucket_public_access_block" "beebide-xania-org" {
  bucket              = aws_s3_bucket.beebide-xania-org.bucket
  block_public_policy = false
}
resource "aws_s3_bucket_policy" "beebide-xania-org" {
  bucket = aws_s3_bucket.beebide-xania-org.bucket
  policy = jsonencode(
    {
      Statement = [
        {
          Action    = "s3:GetObject"
          Effect    = "Allow"
          Principal = "*"
          Resource  = "arn:aws:s3:::beebide.xania.org/*"
          Sid       = "PublicReadGetObject"
        },
      ]
      Version = "2012-10-17"
  })
  depends_on = [aws_s3_bucket_public_access_block.beebide-xania-org]
}
