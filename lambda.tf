# POLICIES
resource "aws_iam_policy" "lambda-execution-policy" {
  name        = "lambda-execution-cloudwatch"
  path        = "/"
  description = ""
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource" : "*"
        }
      ]
    }
  )
}

resource "aws_iam_policy" "lambda-S3-raw-policy" {
  name        = "lambda-S3-read-raw"
  path        = "/"
  description = ""
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "VisualEditor0",
          "Effect" : "Allow",
          "Action" : [
            "s3:ListBucket",
            "s3-object-lambda:*"
          ],
          "Resource" : [
            "arn:aws:s3:::${var.bucket-data-raw}",
            "arn:aws:s3:::*/*"
          ]
        }
      ]
    }
  )
}

resource "aws_iam_policy" "lambda-S3-discovery-policy" {
  name        = "lambda-S3-read-discovery"
  path        = "/"
  description = ""
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "VisualEditor0",
          "Effect" : "Allow",
          "Action" : [
            "s3:PutObject",
            "s3:GetObject",
            "s3:ListBucket",
            "s3-object-lambda:*"
          ],
          "Resource" : [
            "arn:aws:s3:::${var.bucket-data-discovery}",
            "arn:aws:s3:::*/*"
          ]
        }
      ]
    }
  )
}

resource "aws_iam_policy" "lambda-access-sms" {
  name        = "lambda-access-notifications"
  description = ""
  policy = jsonencode(

    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "VisualEditor0",
          "Effect" : "Allow",
          "Action" : "secretsmanager:GetSecretValue",
          "Resource" : "*"
        }
      ]
    }
  )
}

# ROLES
resource "aws_iam_role" "lambda-execution-role" {
  name        = "lambda-execution-role"
  description = ""
  assume_role_policy = jsonencode(

    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "sts:AssumeRole"
          ],
          "Principal" : {
            "Service" : [
              "lambda.amazonaws.com"
            ]
          }
        }
      ]
    }
  )
}

# ROLE ATTACHMENT
resource "aws_iam_role_policy_attachment" "lambda-execution" {
  role       = aws_iam_role.lambda-execution-role.name
  policy_arn = aws_iam_policy.lambda-execution-policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda-execution-s3-raw" {
  role       = aws_iam_role.lambda-execution-role.name
  policy_arn = aws_iam_policy.lambda-S3-raw-policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda-execution-s3-discovery" {
  role       = aws_iam_role.lambda-execution-role.name
  policy_arn = aws_iam_policy.lambda-S3-discovery-policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_execution_sms" {
  role       = aws_iam_role.lambda-execution-role.name
  policy_arn = aws_iam_policy.lambda-access-sms.arn
}

data "archive_file" "zip_the_python_code" {
  type        = "zip"
  source_dir  = "${path.module}/src/"
  output_path = "${path.module}/src/${var.lambda-function}.zip"
}

# LAMBDA EXECUTION
resource "aws_lambda_function" "convert-csv-as-parquet" {
  filename      = "${path.module}/src/${var.lambda-function}.zip"
  function_name = var.lambda-function
  role          = aws_iam_role.lambda-execution-role.arn
  handler       = "${var.lambda-function}.lambda_handler"
  runtime       = "python3.9"
  layers        = ["arn:aws:lambda:${var.region}:336392948345:layer:AWSSDKPandas-Python39:5"]
  timeout       = 60
  depends_on    = [aws_iam_role_policy_attachment.lambda-execution]
  tags = merge(
  local.common_tags,
  tomap({ "Name" = "Lambda consumes csv and produces parquet file" })
  )
}


resource "aws_lambda_permission" "lambda-s3-access" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.convert-csv-as-parquet.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket-data-raw.arn
}

resource "aws_s3_bucket_notification" "lambda-s3-access-notification" {
  bucket = aws_s3_bucket.bucket-data-raw.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.convert-csv-as-parquet.arn
    events              = ["s3:ObjectCreated:Put", "s3:ObjectCreated:Post"]
    filter_prefix       = "csv/"
    filter_suffix       = ".csv"
  }

  depends_on = [aws_lambda_permission.lambda-s3-access]
}

resource "aws_lambda_permission" "lambda-sns-notification" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.convert-csv-as-parquet.arn
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.slack-topic.arn
}