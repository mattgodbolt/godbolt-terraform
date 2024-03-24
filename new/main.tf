provider "aws" {
  region  = "us-east-2"
  profile = "xania"
}
provider "aws" {
  alias   = "virginia"
  region  = "us-east-1"
  profile = "xania"
}

terraform {
  required_version = "~> 1.1"
  backend "s3" {
    bucket  = "terraform.xania.org"
    key     = "godbolt.tfstate"
    region  = "us-east-2"
    profile = "xania"
  }
  required_providers {
    aws = {
      version = "~> 5.41"
    }
  }
}

data "aws_caller_identity" "this" {}

resource "aws_s3_bucket" "music" {
  bucket = "music.xania.org"
}

resource "aws_s3_bucket_lifecycle_configuration" "music" {
  bucket = aws_s3_bucket.music.bucket
  rule {
    id     = "ensure_intelligent"
    status = "Enabled"
    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }
  }
}

resource "aws_s3_bucket" "videos" {
  bucket = "videos.xania.org"
}

resource "aws_s3_bucket_lifecycle_configuration" "videos" {
  bucket = aws_s3_bucket.videos.bucket
  rule {
    id     = "ensure_intelligent"
    status = "Enabled"
    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }
  }
}


data "aws_iam_policy_document" "videos-ro" {
  statement {
    actions = ["s3:ListBucket", "s3:GetObject*"]
    resources = [
      "${aws_s3_bucket.videos.arn}/*",
      aws_s3_bucket.videos.arn
    ]
  }
}

resource "aws_iam_policy" "videos-ro" {
  name        = "videos-ro"
  description = "Read only access to videos"
  policy      = data.aws_iam_policy_document.videos-ro.json
}

resource "aws_iam_user" "benrady" {
  name = "benrady"
}

resource "aws_iam_user_policy_attachment" "benrady" {
  user       = aws_iam_user.benrady.name
  policy_arn = aws_iam_policy.videos-ro.arn
}

resource "aws_iam_access_key" "benrady" {
  user = aws_iam_user.benrady.name
}
output "benrady_id" {
  value = aws_iam_access_key.benrady.id
}
output "benrady_secret" {
  value     = aws_iam_access_key.benrady.secret
  sensitive = true
}


resource "aws_iam_user" "lasso" {
  name = "lasso"
}

resource "aws_iam_user_policy_attachment" "lasso" {
  user       = aws_iam_user.lasso.name
  policy_arn = aws_iam_policy.videos-ro.arn
}

resource "aws_iam_access_key" "lasso" {
  user = aws_iam_user.lasso.name
}
output "lasso_id" {
  value = aws_iam_access_key.lasso.id
}
output "lasso_secret" {
  value     = aws_iam_access_key.lasso.secret
  sensitive = true
}