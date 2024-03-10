resource "aws_s3_bucket" "www-xania-org" {
  bucket = "web.xania.org" # TODO can rename if I ever want to, clashed with OG
  # acl    = "public-read"

  tags = {
    Site = "xania"
  }

  website {
    index_document = "index.html"
  }
}

resource "aws_cloudfront_distribution" "www-xania-org" {
  origin {
    domain_name = aws_s3_bucket.www-xania-org.bucket_domain_name
    origin_id   = "S3-${aws_s3_bucket.www-xania-org.id}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  retain_on_delete    = true
  aliases             = [
    "test.xania.org"  # TODO
    # "*.xania.org",
    # "xania.org"
  ]
  default_root_object = "index.html"

  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.xania-org.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

  http_version = "http2"

  default_cache_behavior {
    allowed_methods        = [
      "HEAD",
      "GET",
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
    target_origin_id       =  "S3-${aws_s3_bucket.www-xania-org.id}"
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

# // I tried, we need this...
# resource "aws_s3_bucket_policy" "www-xania-org" {
#   bucket = aws_s3_bucket.www-xania-org.bucket
#   policy = jsonencode(
#   {
#     Statement = [
#       {
#         Action    = "s3:GetObject"
#         Effect    = "Allow"
#         Principal = "*"
#         Resource  = "arn:aws:s3:::www.xania.org/*"
#         Sid       = "PublicReadGetObject"
#       },
#     ]
#     Version   = "2012-10-17"
#   })
# }
