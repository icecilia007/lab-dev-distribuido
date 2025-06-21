# -*- coding: utf-8 -*-
# File name infra/modules/dynamodb/main.tf
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

resource "aws_dynamodb_table" "this" {
  name         = "${var.TagEnv}-${var.TagProject}-${var.table_name}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = var.hash_key
  range_key    = var.sort_key != "" ? var.sort_key : null

  attribute {
    name = var.hash_key
    type = "S"
  }

  dynamic "attribute" {
    for_each = var.sort_key != "" ? [1] : []
    content {
      name = var.sort_key
      type = var.sort_key_type
    }
  }

  tags = var.tags

  stream_enabled   = var.enable_stream
  stream_view_type = var.enable_stream ? var.stream_view_type : null
}


data "aws_iam_policy_document" "lambda_dynamodb_policy" {
  count = var.enable_stream && length(var.lambda_function_names) > 0 ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetRecords",
      "dynamodb:GetShardIterator",
      "dynamodb:DescribeStream",
      "dynamodb:ListStreams"
    ]
    resources = [
      aws_dynamodb_table.this.stream_arn
    ]
  }
}


resource "aws_iam_policy" "lambda_dynamodb_policy" {
  for_each = var.enable_stream && length(var.lambda_function_names) > 0 ? toset(var.lambda_function_names) : []

  name        = "${each.key}-stream-db-policy"
  description = "Allow Lambda ${each.key} to access DynamoDB Stream for ${aws_dynamodb_table.this.name}"
  policy      = data.aws_iam_policy_document.lambda_dynamodb_policy[0].json
}


data "aws_lambda_function" "this" {
  for_each      = var.enable_stream && length(var.lambda_function_names) > 0 ? toset(var.lambda_function_names) : []
  function_name = each.key
}


resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  for_each = var.enable_stream && length(var.lambda_function_names) > 0 ? toset(var.lambda_function_names) : []

  role       = split("/", data.aws_lambda_function.this[each.key].role)[1]
  policy_arn = aws_iam_policy.lambda_dynamodb_policy[each.key].arn
}

resource "aws_lambda_event_source_mapping" "this" {
  for_each          = var.enable_stream && length(var.lambda_function_names) > 0 ? toset(var.lambda_function_names) : []
  event_source_arn  = aws_dynamodb_table.this.stream_arn
  function_name     = each.key
  starting_position = "LATEST"

  depends_on = [aws_iam_role_policy_attachment.lambda_dynamodb]
}

resource "aws_dynamodb_table_item" "example" {
  count      = length(var.example_item) > 0 ? 1 : 0
  table_name = aws_dynamodb_table.this.name
  hash_key   = var.hash_key
  range_key  = var.sort_key != "" ? var.sort_key : null
  item       = var.example_item
}
