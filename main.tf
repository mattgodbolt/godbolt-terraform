provider "aws" {
  region = "us-east-1"
}

terraform {
  required_version = "~> 1.1"
  backend "s3" {
    bucket = "terraform.godbolt.org"
    key    = "godbolt.tfstate"
    region = "us-east-1"
  }
  required_providers {
    aws = {
      version = "~> 2.15"
    }
  }
}
