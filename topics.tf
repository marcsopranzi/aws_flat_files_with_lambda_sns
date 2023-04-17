resource "aws_sns_topic" "slack-topic" {
  name = var.sns-slack-topic
    tags = merge(
    local.common_tags,
    tomap({ "Name" = "Slack Topic Ingestions" })
  )
}

resource "aws_sns_topic_subscription" "topic-lambda" {
  topic_arn = aws_sns_topic.slack-topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.convert-csv-as-parquet.arn
}

