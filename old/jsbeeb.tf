resource "aws_s3_bucket" "bbc-godbolt-org" {
  bucket = "bbc.godbolt.org"
  acl    = "public-read"

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
  jsbeeb_prod_origin_id = "S3-bbc.godbolt.org"
  jsbeeb_beta_origin_id = "S3-bbc.godbolt.org/beta"
}

resource "aws_cloudfront_distribution" "bbc-godbolt-org" {
  origin {
    domain_name = aws_s3_bucket.bbc-godbolt-org.bucket_domain_name
    origin_id   = local.jsbeeb_prod_origin_id
  }
  origin {
    domain_name = aws_s3_bucket.bbc-godbolt-org.bucket_domain_name
    origin_id   = local.jsbeeb_beta_origin_id
    origin_path = "/beta"
  }

  enabled          = true
  is_ipv6_enabled  = true
  retain_on_delete = true
  aliases = [
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

// I tried, we need this...
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
      Version = "2012-10-17"
  })
}

resource "aws_iam_user" "deploy-jsbeeb" {
  name = "deploy-jsbeeb"
}

data "aws_iam_policy_document" "bbc-godbolt-org-rw" {
  statement {
    sid     = "S3AccessSid"
    actions = ["s3:*"]
    resources = [
      "${aws_s3_bucket.bbc-godbolt-org.arn}/*",
      aws_s3_bucket.bbc-godbolt-org.arn
    ]
  }
}

resource "aws_iam_policy" "deploy-jsbeeb" {
  name        = "deploy-jsbeeb"
  description = "Can create resource in bbc.godbolt.org bucket"
  policy      = data.aws_iam_policy_document.bbc-godbolt-org-rw.json
}

resource "aws_iam_user_policy_attachment" "deploy-jsbeeb" {
  user       = aws_iam_user.deploy-jsbeeb.name
  policy_arn = aws_iam_policy.deploy-jsbeeb.arn
}
