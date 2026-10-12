// beeb-meta-data (github.com/mattgodbolt/beeb-meta-data) publishes symbol sets,
// and later title records, under bbc.xania.org/meta/. It shares jsbeeb's bucket
// and distribution, but its deploy user can only list and write meta/: it never
// deletes, and nothing else in the bucket is its business.
resource "aws_iam_user" "deploy_beeb_meta_data" {
  name = "deploy-beeb-meta-data"
}

data "aws_iam_policy_document" "deploy_beeb_meta_data" {
  // aws s3 sync lists the destination to decide what to upload.
  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::bbc.xania.org"]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["meta/*"]
    }
  }
  statement {
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::bbc.xania.org/meta/*"]
  }
}

resource "aws_iam_user_policy" "deploy_beeb_meta_data" {
  name   = "deploy-beeb-meta-data"
  user   = aws_iam_user.deploy_beeb_meta_data.name
  policy = data.aws_iam_policy_document.deploy_beeb_meta_data.json
}

resource "aws_iam_access_key" "deploy_beeb_meta_data" {
  user = aws_iam_user.deploy_beeb_meta_data.name
}

output "deploy_beeb_meta_data_id" {
  value = aws_iam_access_key.deploy_beeb_meta_data.id
}

output "deploy_beeb_meta_data_secret" {
  value     = aws_iam_access_key.deploy_beeb_meta_data.secret
  sensitive = true
}
