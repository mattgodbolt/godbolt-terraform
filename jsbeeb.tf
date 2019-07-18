resource "aws_s3_bucket" "bbc-godbolt-org" {
  bucket = "bbc.godbolt.org"
  acl    = "public"

  tags = {
    Site = "jsbeeb"
  }

  cors_rule {
    allowed_headers = ["Authorization"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }

  website {
    index_document = "index.html"
  }
}

locals {
  prod_origin_id = "S3-bbc.godbolt.org"
  beta_origin_id = "S3-bbc.godbolt.org/beta"
}

resource "aws_cloudfront_distribution" "bbc-godbolt-org" {
  origin {
    domain_name = aws_s3_bucket.bbc-godbolt-org.bucket_domain_name
    origin_id   = local.prod_origin_id
  }
  origin {
    domain_name = aws_s3_bucket.bbc-godbolt-org.bucket_domain_name
    origin_id   = local.beta_origin_id
    origin_path = "/beta"
  }

  enabled             = true
  is_ipv6_enabled     = true
  retain_on_delete    = true
  aliases             = [
    "bbc.godbolt.org",
    "master.godbolt.org"
  ]
  default_root_object = "index.html"

  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.godbolt-org.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

  http_version = "http2"


  # Beta site
  ordered_cache_behavior {
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
    path_pattern           = "/beta*"
    target_origin_id       = local.beta_origin_id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

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
    target_origin_id       = local.prod_origin_id
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

// TODO: try removing?
resource "aws_s3_bucket_policy" "bbc-godbolt-org" {
  bucket = aws_s3_bucket.bbc-godbolt-org.bucket
  policy = jsonencode(
  {
    Statement = [
      {
        Action    = "s3:GetObject"
        Effect    = "Allow"
        Principal = "*"
        Resource  = "arn:aws:s3:::bbc.godbolt.org/*"
        Sid       = "PublicReadGetObject"
      },
    ]
    Version   = "2012-10-17"
  })
}