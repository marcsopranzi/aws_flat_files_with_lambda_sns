resource "aws_s3_bucket" "bucket-data-raw" {
  bucket        = var.bucket-data-raw
  force_destroy = true
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "raw-access" })
  )
}

resource "aws_s3_bucket" "bucket-data-discovery" {
  bucket        = var.bucket-data-discovery
  force_destroy = true
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "discovery-access" })
  )
}

resource "aws_s3_object" "folders-raw" {
  bucket   = aws_s3_bucket.bucket-data-raw.id
  for_each = toset(["csv/", "csv_errors/"])
  key      = each.key
}

resource "aws_s3_object" "folders-discovery" {
  bucket   = aws_s3_bucket.bucket-data-discovery.id
  for_each = toset(["csv-ingestion/"])
  key      = each.key
}
