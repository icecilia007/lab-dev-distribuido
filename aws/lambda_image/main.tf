# -*- coding: utf-8 -*-
# File name infra/modules/lambda_image/main.tf
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }
  }
}

module "repo_ecr_lambda" {
  source          = "../ecr"
  TagEnv          = var.TagEnv
  TagProject      = var.TagProject
  region          = var.aws_region
  tags            = var.tags
  repository_name = var.lambda_name
}

data "aws_caller_identity" "current" {}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
}

resource "null_resource" "run_script" {
  for_each = toset(var.files)
  triggers = {
    file = filesha256("./${path.root}/../${var.folder}/${each.key}")
  }

  provisioner "local-exec" {
    command = "chmod +x ./${path.module}/script.sh && ./${path.module}/script.sh"
    environment = {
      FOLDER         = var.folder
      AWS_REGION     = var.aws_region
      AWS_ACCOUNT_ID = local.aws_account_id
      ECR_REPO_NAME  = module.repo_ecr_lambda.name
      IMAGE_TAG      = var.tag_image
    }
    interpreter = ["/bin/bash", "-c"]
  }

}


data "aws_iam_policy_document" "policy_doc" {
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
  name               = "${var.TagEnv}_${var.TagProject}_${var.lambda_name}_role"
  assume_role_policy = data.aws_iam_policy_document.policy_doc.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "policy_cloudwatch" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_custom_policy" {
  count      = length(var.additional_policies)
  role       = aws_iam_role.lambda_role.name
  policy_arn = element(var.additional_policies, count.index)
}

resource "aws_lambda_function" "lambda" {
  function_name = "${var.TagEnv}_${var.TagProject}_${var.lambda_name}"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  memory_size   = var.memory
  image_uri     = "${module.repo_ecr_lambda.repository_url}:${var.tag_image}"
  timeout       = var.timeout
  description   = var.description
  environment {
    variables = var.environment_variables
  }
  tags                           = var.tags
  depends_on                     = [null_resource.run_script]
  reserved_concurrent_executions = var.reserved_concurrent_executions
  dynamic "vpc_config" {
    for_each = length(var.subnet_ids) > 0 ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }
}

resource "aws_lambda_function_event_invoke_config" "retry" {
  function_name                = aws_lambda_function.lambda.function_name
  maximum_event_age_in_seconds = var.maximum_event_age_in_seconds
  maximum_retry_attempts       = var.maximum_retry_attempts
}

resource "null_resource" "update" {
  for_each = toset(var.files)
  triggers = {
    file = filesha256("./${path.root}/../${var.folder}/${each.key}")
  }
  provisioner "local-exec" {
    command = "chmod +x ./${path.module}/update.sh && ./${path.module}/update.sh"
    environment = {
      AWS_REGION     = var.aws_region
      AWS_ACCOUNT_ID = local.aws_account_id
      ECR_REPO_NAME  = module.repo_ecr_lambda.name
      IMAGE_TAG      = var.tag_image
      LAMBDA_UPDATE  = aws_lambda_function.lambda.function_name
    }
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = [aws_lambda_function.lambda]
}
