provider "aws" {
  region  = "us-east-2"
  profile = "personal"
}
provider "aws" {
  alias   = "virginia"
  region  = "us-east-1"
  profile = "personal"
}

terraform {
  required_version = "~> 1.1"
  backend "s3" {
    bucket  = "terraform.xania.org"
    key     = "godbolt.tfstate"
    region  = "us-east-2"
    profile = "personal"
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
    id = "ensure_intelligent"
        status = "Enabled"
    transition {
      days = 0
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
    id = "ensure_intelligent"
        status = "Enabled"
    transition {
      days = 0
      storage_class = "INTELLIGENT_TIERING"
    }
  }
}
