data "aws_caller_identity" "this" {}

data "aws_cloudfront_cache_policy" "disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer_except_host" {
  name = "Managed-AllViewerExceptHostHeader"
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket
  tags   = var.tags
}


resource "aws_s3_bucket_cors_configuration" "cors" {
  bucket = aws_s3_bucket.bucket.id
  cors_rule {
    allowed_headers = ["Authorization"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}

resource "aws_cloudfront_response_headers_policy" "cors_policy" {
  name = "CORSPolicy-${replace(var.bucket, ".", "-")}"

  cors_config {
    access_control_allow_credentials = false
    access_control_allow_origins {
      items = ["*"]
    }
    access_control_allow_methods {
      items = ["GET", "HEAD", "OPTIONS"]
    }
    access_control_allow_headers {
      items = ["*"]
    }
    origin_override            = true
    access_control_max_age_sec = 3000
  }
}

resource "aws_cloudfront_distribution" "distribution" {
  origin {
    domain_name              = aws_s3_bucket.bucket.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.bucket.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  dynamic "origin" {
    for_each = var.api_origins
    content {
      domain_name = origin.value.domain_name
      origin_id   = "api-${origin.value.path_pattern}"
      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  // A Lambda function URL rejects a Host header that isn't its own, hence
  // AllViewerExceptHostHeader.
  dynamic "ordered_cache_behavior" {
    for_each = var.api_origins
    content {
      path_pattern             = ordered_cache_behavior.value.path_pattern
      target_origin_id         = "api-${ordered_cache_behavior.value.path_pattern}"
      allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods           = ["GET", "HEAD"]
      cache_policy_id          = data.aws_cloudfront_cache_policy.disabled.id
      origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host.id
      viewer_protocol_policy   = "https-only"
      compress                 = true
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  retain_on_delete    = false
  aliases             = var.aliases
  default_root_object = "index.html"

  viewer_certificate {
    acm_certificate_arn      = var.certificate
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

  http_version = "http2"

  default_cache_behavior {
    allowed_methods = [
      "HEAD",
      "GET",
      "OPTIONS"
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
    target_origin_id           = "S3-${aws_s3_bucket.bucket.id}"
    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true
    response_headers_policy_id = aws_cloudfront_response_headers_policy.cors_policy.id
  }

  tags = var.tags


  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

// https://github.com/hashicorp/terraform-provider-aws/issues/30105#issuecomment-1474431141
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = var.bucket
  description                       = "S3 access to cloudfront"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_iam_policy_document" "policy" {
  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = [format("arn:aws:s3:::%s/*", aws_s3_bucket.bucket.bucket)]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values = [
        format(
          "arn:aws:cloudfront::%s:distribution/%s",
          data.aws_caller_identity.this.account_id,
          aws_cloudfront_distribution.distribution.id
        )
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.bucket.bucket
  policy = data.aws_iam_policy_document.policy.json
}


resource "aws_iam_user" "deploy" {
  name = var.deploy_user
}

data "aws_iam_policy_document" "policy-rw" {
  statement {
    sid     = "S3AccessSid"
    actions = ["s3:*"]
    resources = [
      "${aws_s3_bucket.bucket.arn}/*",
      aws_s3_bucket.bucket.arn
    ]
  }
  statement {
    sid     = "AllowInvalidation"
    actions = ["cloudfront:CreateInvalidation"]
    resources = [
      format(
        "arn:aws:cloudfront::%s:distribution/%s",
        data.aws_caller_identity.this.account_id,
        aws_cloudfront_distribution.distribution.id
    )]
  }

  // An explicit Deny beats the s3:* Allow above, so the deploy user keeps full
  // write access to these prefixes — it can still overwrite and add objects —
  // but cannot delete from them. Guards content that isn't rebuilt from the
  // repo against an `aws s3 sync --delete` aimed at the wrong destination.
  dynamic "statement" {
    for_each = length(var.protected_prefixes) > 0 ? [1] : []
    content {
      sid       = "ProtectPrefixesFromDeletion"
      effect    = "Deny"
      actions   = ["s3:DeleteObject", "s3:DeleteObjectVersion"]
      resources = [for prefix in var.protected_prefixes : "${aws_s3_bucket.bucket.arn}/${prefix}"]
    }
  }
}

resource "aws_iam_policy" "deploy" {
  name        = var.deploy_user
  description = format("Can create resources in %s bucket and invalidate distribution %s", var.bucket, aws_cloudfront_distribution.distribution.id)
  policy      = data.aws_iam_policy_document.policy-rw.json
}

resource "aws_iam_user_policy_attachment" "deploy" {
  user       = aws_iam_user.deploy.name
  policy_arn = aws_iam_policy.deploy.arn
}

resource "aws_iam_access_key" "deploy" {
  user = aws_iam_user.deploy.name
}
