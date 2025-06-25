# ==========================================
# CAMPANHAS PROMOCIONAIS INFRASTRUCTURE
# ==========================================

# DynamoDB Table para Métricas de Campanhas
resource "aws_dynamodb_table" "campanhas_metricas" {
  name           = "campanhas-metricas"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "campanha_id"
  range_key      = "timestamp"

  attribute {
    name = "campanha_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  global_secondary_index {
    name            = "status-index"
    hash_key        = "status"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  tags = {
    Name        = "campanhas-metricas"
    Environment = var.environment
  }
}

# SQS Queues para Segmentação de Email
resource "aws_sqs_queue" "email_premium" {
  name                      = "notifications-premium"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 10
  visibility_timeout_seconds = 120

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.email_premium_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name        = "notifications-premium"
    Environment = var.environment
  }
}

resource "aws_sqs_queue" "email_premium_dlq" {
  name                      = "notifications-premium-dlq"
  message_retention_seconds = 1209600

  tags = {
    Name        = "notifications-premium-dlq"
    Environment = var.environment
  }
}

resource "aws_sqs_queue" "email_regiao_sul" {
  name                      = "notifications-regiao-sul"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 10
  visibility_timeout_seconds = 120

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.email_regiao_sul_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name        = "notifications-regiao-sul"
    Environment = var.environment
  }
}

resource "aws_sqs_queue" "email_regiao_sul_dlq" {
  name                      = "notifications-regiao-sul-dlq"
  message_retention_seconds = 1209600

  tags = {
    Name        = "notifications-regiao-sul-dlq"
    Environment = var.environment
  }
}

resource "aws_sqs_queue" "email_geral" {
  name                      = "notifications-geral"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 10
  visibility_timeout_seconds = 120

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.email_geral_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name        = "notifications-geral"
    Environment = var.environment
  }
}

resource "aws_sqs_queue" "email_geral_dlq" {
  name                      = "notifications-geral-dlq"
  message_retention_seconds = 1209600

  tags = {
    Name        = "notifications-geral-dlq"
    Environment = var.environment
  }
}

# IAM Role para Lambda de Campanhas
resource "aws_iam_role" "campanhas_lambda_role" {
  name = "campanhas-lambda-role"

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

# IAM Policy para Lambda de Campanhas
resource "aws_iam_role_policy" "campanhas_lambda_policy" {
  name = "campanhas-lambda-policy"
  role = aws_iam_role.campanhas_lambda_role.id

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
          "dynamodb:Query",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.campanhas_metricas.arn,
          "${aws_dynamodb_table.campanhas_metricas.arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = [
          aws_sqs_queue.email_premium.arn,
          aws_sqs_queue.email_regiao_sul.arn,
          aws_sqs_queue.email_geral.arn,
          aws_sqs_queue.email_notifications.arn
        ]
      }
    ]
  })
}

# CloudWatch Log Group para Lambda de Campanhas
resource "aws_cloudwatch_log_group" "campanhas_lambda_logs" {
  name              = "/aws/lambda/campanhas-processor"
  retention_in_days = 14
}

data "archive_file" "campanhas_zip" {
  type        = "zip"
  source_file = "../lambda/campanhas/lambda_function.py"
  output_path = "campanhas.zip"
}

# Lambda Function para Campanhas
resource "aws_lambda_function" "campanhas_processor" {
  filename         = data.archive_file.campanhas_zip.output_path
  function_name    = "campanhas-processor"
  role            = aws_iam_role.campanhas_lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.11"
  timeout         = 180

  environment {
    variables = {
      DYNAMODB_TABLE           = aws_dynamodb_table.campanhas_metricas.name
      SQS_EMAIL_QUEUE_PREMIUM  = aws_sqs_queue.email_premium.url
      SQS_EMAIL_QUEUE_REGIAO_SUL = aws_sqs_queue.email_regiao_sul.url
      SQS_EMAIL_QUEUE_GERAL    = aws_sqs_queue.email_geral.url
      SQS_EMAIL_QUEUE          = aws_sqs_queue.email_notifications.url
    }
  }

  depends_on = [
    aws_iam_role_policy.campanhas_lambda_policy,
    aws_cloudwatch_log_group.campanhas_lambda_logs,
  ]

  tags = {
    Name        = "campanhas-processor"
    Environment = var.environment
  }
}

# API Gateway Resource - /campanhas
resource "aws_api_gateway_resource" "campanhas" {
  rest_api_id = aws_api_gateway_rest_api.cupons_api.id
  parent_id   = aws_api_gateway_rest_api.cupons_api.root_resource_id
  path_part   = "campanhas"
}

# API Gateway Resource - /campanhas/trigger
resource "aws_api_gateway_resource" "campanhas_trigger" {
  rest_api_id = aws_api_gateway_rest_api.cupons_api.id
  parent_id   = aws_api_gateway_resource.campanhas.id
  path_part   = "trigger"
}

# API Gateway Method - POST /campanhas/trigger
resource "aws_api_gateway_method" "trigger_campanha" {
  rest_api_id   = aws_api_gateway_rest_api.cupons_api.id
  resource_id   = aws_api_gateway_resource.campanhas_trigger.id
  http_method   = "POST"
  authorization = "NONE"
}

# API Gateway Integration - POST /campanhas/trigger
resource "aws_api_gateway_integration" "trigger_campanha_integration" {
  rest_api_id = aws_api_gateway_rest_api.cupons_api.id
  resource_id = aws_api_gateway_resource.campanhas_trigger.id
  http_method = aws_api_gateway_method.trigger_campanha.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.campanhas_processor.invoke_arn
}

# Lambda Permission para API Gateway - campanhas
resource "aws_lambda_permission" "api_gateway_campanhas" {
  statement_id  = "AllowExecutionFromAPIGatewayCampanhas"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.campanhas_processor.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.cupons_api.execution_arn}/*/*"
}

# Event Source Mappings para cada fila SQS
resource "aws_lambda_event_source_mapping" "sqs_premium_lambda_trigger" {
  event_source_arn = aws_sqs_queue.email_premium.arn
  function_name    = aws_lambda_function.email_processor.arn
  batch_size       = 10
  maximum_batching_window_in_seconds = 5
}

resource "aws_lambda_event_source_mapping" "sqs_regiao_sul_lambda_trigger" {
  event_source_arn = aws_sqs_queue.email_regiao_sul.arn
  function_name    = aws_lambda_function.email_processor.arn
  batch_size       = 10
  maximum_batching_window_in_seconds = 5
}

resource "aws_lambda_event_source_mapping" "sqs_geral_lambda_trigger" {
  event_source_arn = aws_sqs_queue.email_geral.arn
  function_name    = aws_lambda_function.email_processor.arn
  batch_size       = 10
  maximum_batching_window_in_seconds = 5
}