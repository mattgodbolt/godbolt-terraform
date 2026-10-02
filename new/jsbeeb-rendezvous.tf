// WebRTC signalling for jsbeeb's shared sessions: peers swap an offer and an
// answer through a room here, then talk directly. Terraform owns the function's
// shape; jsbeeb's CI deploys its code (see deploy_jsbeeb_lambda below), so the
// placeholder is only what a fresh function starts with.

resource "aws_dynamodb_table" "jsbeeb_rendezvous" {
  name         = "jsbeeb-rendezvous"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "room"
  range_key    = "entry"

  attribute {
    name = "room"
    type = "S"
  }

  attribute {
    name = "entry"
    type = "S"
  }

  ttl {
    attribute_name = "expires"
    enabled        = true
  }

  tags = {
    Site = "jsbeeb"
  }
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "jsbeeb_rendezvous" {
  name               = "jsbeeb-rendezvous"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "jsbeeb_rendezvous" {
  statement {
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:Query", "dynamodb:DeleteItem"]
    resources = [aws_dynamodb_table.jsbeeb_rendezvous.arn]
  }
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.jsbeeb_rendezvous.arn}:*"]
  }
}

resource "aws_iam_role_policy" "jsbeeb_rendezvous" {
  role   = aws_iam_role.jsbeeb_rendezvous.id
  policy = data.aws_iam_policy_document.jsbeeb_rendezvous.json
}

resource "aws_cloudwatch_log_group" "jsbeeb_rendezvous" {
  name              = "/aws/lambda/jsbeeb-rendezvous"
  retention_in_days = 14
}

data "archive_file" "jsbeeb_rendezvous_placeholder" {
  type        = "zip"
  output_path = "${path.module}/.terraform/jsbeeb-rendezvous-placeholder.zip"
  source {
    filename = "index.mjs"
    content  = "export const handler = async () => ({ statusCode: 503, body: \"not deployed yet\" });\n"
  }
}

resource "aws_lambda_function" "jsbeeb_rendezvous" {
  function_name = "jsbeeb-rendezvous"
  role          = aws_iam_role.jsbeeb_rendezvous.arn
  runtime       = "nodejs22.x"
  architectures = ["arm64"]
  handler       = "index.handler"
  memory_size   = 128
  timeout       = 5
  // A handful of rendezvous at once is plenty; this caps what a flood can spend.
  reserved_concurrent_executions = 5
  filename                       = data.archive_file.jsbeeb_rendezvous_placeholder.output_path

  environment {
    variables = {
      TABLE = aws_dynamodb_table.jsbeeb_rendezvous.name
    }
  }

  // jsbeeb's deploy replaces the code; Terraform must not put the placeholder back.
  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }

  depends_on = [aws_cloudwatch_log_group.jsbeeb_rendezvous]

  tags = {
    Site = "jsbeeb"
  }
}

resource "aws_lambda_function_url" "jsbeeb_rendezvous" {
  function_name      = aws_lambda_function.jsbeeb_rendezvous.function_name
  authorization_type = "NONE"
}

// GetFunction is enough for `aws lambda wait function-updated-v2` after a deploy.
data "aws_iam_policy_document" "deploy_jsbeeb_lambda" {
  statement {
    actions   = ["lambda:UpdateFunctionCode", "lambda:GetFunction"]
    resources = [aws_lambda_function.jsbeeb_rendezvous.arn]
  }
}

resource "aws_iam_user_policy" "deploy_jsbeeb_lambda" {
  name   = "deploy-jsbeeb-lambda"
  user   = module.jsbeeb.deploy_user
  policy = data.aws_iam_policy_document.deploy_jsbeeb_lambda.json
}

// A NONE-auth function URL still needs a resource policy letting anyone call it.
resource "aws_lambda_permission" "jsbeeb_rendezvous_url" {
  statement_id           = "FunctionURLAllowPublicAccess"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.jsbeeb_rendezvous.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

// Function URLs created since late 2025 also need lambda:InvokeFunction. This
// lets any AWS principal invoke it directly too, which exposes nothing the
// public URL doesn't; with provider >= 6.28, narrow it with
// invoked_via_function_url = true.
resource "aws_lambda_permission" "jsbeeb_rendezvous_invoke" {
  statement_id  = "FunctionURLAllowInvokeAction"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.jsbeeb_rendezvous.function_name
  principal     = "*"
}
