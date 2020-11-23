resource "aws_iam_user" "deploy-owlet" {
  name = "deploy-owlet"
}

data "aws_iam_policy_document" "owlet-s3-access" {
  statement {
    sid       = "S3AccessToEditorMicRo"
    actions   = ["s3:*"]
    resources = [
      "arn:aws:s3:::bbcmic.ro/*",
      "arn:aws:s3:::bbcmic.ro"]
  }
}

resource "aws_iam_policy" "deploy-owlet" {
  name        = "deploy-owlet"
  description = "Can create resources in bbcmic.ro bucket"
  policy      = data.aws_iam_policy_document.owlet-s3-access.json
}

resource "aws_iam_user_policy_attachment" "deploy-owlet" {
  user       = aws_iam_user.deploy-owlet.name
  policy_arn = aws_iam_policy.deploy-owlet.arn
}
