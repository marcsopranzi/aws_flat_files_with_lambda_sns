variable "prefix" {
  type        = string
  default     = "flat_file_ingestion"
  description = "description"
}

variable "project" {
  default = "AWS Lambda"
}

variable "region" {
  default = "us-east-1"
}

variable "bucket-data-raw" {
  type    = string
  default = "data-feeds-raw-5"
}

variable "bucket-data-discovery" {
  type    = string
  default = "data-feeds-discovery-5"
}

# The lambda function name must match the python file name
variable "lambda-function" {
  type    = string
  default = "convert_csv_to_parquet"
}

variable "sns-slack-topic" {
  type    = string
  default = "slack-topic"
}

variable "contact" {
  default = "marcsopranzi@gmail.com"
}
