provider "aws" {}

terraform {
  backend "s3" {
    bucket = "cf-templates-5r11wlvvdn8u-eu-central-1"
    key    = "terraform/tmp_terraform.tfstate"
    region = "eu-central-1"
  }
}


resource "aws_lambda_function" "func" {
  filename      = "lambda.zip"
  function_name = "zip_files_in_s3"
  role          = "${aws_iam_role.iam_for_lambda.arn}"
  handler       = "lambda.handler"
  runtime          = "python3.6"
  source_code_hash = "${data.archive_file.zipped_lambda.output_base64sha256}"
}

data "archive_file" "zipped_lambda" {
  type        = "zip"
  source_file = "./lambda/lambda.py"
  output_path = "lambda.zip"
}


resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.func.arn}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${aws_s3_bucket.bucket.arn}"
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_s3_bucket" "bucket" {
  bucket = "zip-keeper-aui-project"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = "${aws_s3_bucket.bucket.id}"

  lambda_function {
    lambda_function_arn = "${aws_lambda_function.func.arn}"
    events              = ["s3:ObjectCreated:Put"]
  }
}


resource "aws_iam_policy" "lambda_logging" {
  name = "lambda_logging"
  path = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}


resource "aws_iam_policy" "lambda_s3" {
  name = "lambda_s3"
  path = "/"
  description = "IAM policy for everything on s3 certain bucket"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "s3:*"
      ],
      "Resource": [
          "arn:aws:s3:::zip-keeper-aui-project",
          "arn:aws:s3:::zip-keeper-aui-project/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "${aws_iam_policy.lambda_logging.arn}"
}

resource "aws_iam_role_policy_attachment" "lambda_s3" {
  role = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "${aws_iam_policy.lambda_s3.arn}"
}
