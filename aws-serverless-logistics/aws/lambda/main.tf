# -*- coding: utf-8 -*-
# File name infra/modules/lambda/main.tf

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.0.0"
    }
  }
}

data "aws_iam_policy_document" "assume_role_lambda" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }

}

resource "aws_iam_role" "lambda_role" {
  name               = "${var.TagEnv}-${var.TagProject}-${var.function_name}_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_logs_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_custom_policy" {
  count      = length(var.additional_policies)
  role       = aws_iam_role.lambda_role.name
  policy_arn = element(var.additional_policies, count.index)
}

data "archive_file" "lambda_package" {
  type        = "zip"
  source_file = "./${path.root}/../${var.source_file}"
  output_path = "./${path.root}/../${var.source_file}.zip"
}

resource "aws_lambda_function" "lambda_function" {
  function_name = "${var.TagEnv}-${var.TagProject}-${var.function_name}"
  role          = aws_iam_role.lambda_role.arn
  timeout       = var.timeout
  memory_size   = var.memory_size
  tags          = var.tags
  package_type  = "Zip"
  handler       = var.handler
  runtime       = var.runtime
  description   = var.description
  environment {
    variables = var.environment_variables
  }
  reserved_concurrent_executions = var.reserved_concurrent_executions
  filename                       = data.archive_file.lambda_package.output_path
  source_code_hash               = data.archive_file.lambda_package.output_base64sha256

  layers = length(var.layer_name) > 0 ? concat([aws_lambda_layer_version.custom_layer[0].arn], var.lambda_layers) : var.lambda_layers

  dynamic "vpc_config" {
    for_each = length(var.subnet_ids) > 0 ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }
}

resource "aws_s3_object" "this" {
  count  = length(trimspace(var.layer_name)) > 0 ? 1 : 0
  bucket = var.s3_art
  key    = "layers/${var.layer_name}.zip"
  source = "${path.module}/layers/${var.layer_name}.zip"
  etag   = filemd5("${path.module}/layers/${var.layer_name}.zip")
  tags   = var.tags
}

resource "aws_lambda_layer_version" "custom_layer" {
  count               = length(trimspace(var.layer_name)) > 0 ? 1 : 0
  layer_name          = "${var.TagEnv}-${var.TagProject}-${var.layer_name}"
  compatible_runtimes = [var.runtime]
  s3_bucket           = aws_s3_object.this[count.index].bucket
  s3_key              = aws_s3_object.this[count.index].key
  source_code_hash    = filebase64sha256("${path.module}/layers/${var.layer_name}.zip")

}


resource "aws_lambda_function_event_invoke_config" "lambda_invoke_config" {
  function_name                = aws_lambda_function.lambda_function.function_name
  maximum_event_age_in_seconds = var.max_event_age_in_seconds
  maximum_retry_attempts       = var.max_retry_attempts

}

resource "aws_iam_policy" "lambda_sns" {
  name = "${var.TagEnv}_${var.TagProject}_${var.function_name}_lambda_sns"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "sns:Publish",
        Resource = var.sns_topic_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sns_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_sns.arn
}
