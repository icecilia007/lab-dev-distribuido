terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# SQS Queue para notificações de email
resource "aws_sqs_queue" "email_notifications" {
  name                      = "email-notifications"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 1209600  # 14 dias
  receive_wait_time_seconds = 10
  visibility_timeout_seconds = 120     # Deve ser >= timeout da Lambda
  
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.email_notifications_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name        = "email-notifications"
    Environment = var.environment
  }
}

# Dead Letter Queue
resource "aws_sqs_queue" "email_notifications_dlq" {
  name                      = "email-notifications-dlq"
  message_retention_seconds = 1209600  # 14 dias

  tags = {
    Name        = "email-notifications-dlq"
    Environment = var.environment
  }
}

# IAM Role para Lambda
resource "aws_iam_role" "lambda_execution_role" {
  name = "email-processor-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy para Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "email-processor-lambda-policy"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = [
          aws_sqs_queue.email_notifications.arn,
          aws_sqs_queue.email_notifications_dlq.arn,
          aws_sqs_queue.email_premium.arn,
          aws_sqs_queue.email_regiao_sul.arn,
          aws_sqs_queue.email_geral.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })
}

data "archive_file" "email_zip" {
  type        = "zip"
  source_file = "../lambda/email_processor/lambda_function.py"
  output_path = "email_processor.zip"
}

# Lambda Function
resource "aws_lambda_function" "email_processor" {
  filename         = data.archive_file.email_zip.output_path
  function_name    = "email-send"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.11"
  timeout         = 60

  environment {
    variables = {
      SENDER_EMAIL = "1457902@sga.pucminas.br"
    }
  }

  depends_on = [
    aws_iam_role_policy.lambda_policy,
    aws_cloudwatch_log_group.lambda_logs,
  ]

  tags = {
    Name        = "email-processor"
    Environment = var.environment
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/email-send"
  retention_in_days = 14
}

# Event Source Mapping (SQS -> Lambda)
resource "aws_lambda_event_source_mapping" "sqs_lambda_trigger" {
  event_source_arn = aws_sqs_queue.email_notifications.arn
  function_name    = aws_lambda_function.email_processor.arn
  batch_size       = 10
  maximum_batching_window_in_seconds = 5
}

# SES Email Identities (múltiplos emails)
resource "aws_ses_email_identity" "sender_emails" {
  for_each = toset(var.sender_emails)
  email    = each.value
}

# SES Configuration Set
resource "aws_ses_configuration_set" "email_config" {
  name = "email-notifications-config"
}

# SES Event Destination
resource "aws_ses_event_destination" "cloudwatch" {
  name                   = "cloudwatch-destination"
  configuration_set_name = aws_ses_configuration_set.email_config.name
  enabled                = true
  matching_types         = ["bounce", "complaint", "delivery", "send", "reject"]

  cloudwatch_destination {
    default_value  = "0"
    dimension_name = "MessageTag"
    value_source   = "messageTag"
  }
}

# Outputs para mostrar os emails verificados
output "verified_sender_emails" {
  description = "Lista de emails verificados no SES"
  value       = [for email in aws_ses_email_identity.sender_emails : email.email]
}