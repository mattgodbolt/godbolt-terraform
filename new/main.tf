provider "aws" {
  region = "us-east-2"
  profile = "personal"
}

terraform {
  required_version = "~> 1.1"
  backend "s3" {
    bucket = "terraform.xania.org"
    key    = "godbolt.tfstate"
    region = "us-east-2"
    profile = "personal"
  }
  required_providers {
    aws = {
      version = "~> 2.15"
    }
  }
}
