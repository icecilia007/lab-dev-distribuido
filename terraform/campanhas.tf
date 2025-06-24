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

# SNS Topics para Segmentação
resource "aws_sns_topic" "clientes_premium" {
  name = "clientes-premium"
  
  tags = {
    Name        = "clientes-premium"
    Environment = var.environment
  }
}

resource "aws_sns_topic" "clientes_regiao_sul" {
  name = "clientes-regiao-sul"
  
  tags = {
    Name        = "clientes-regiao-sul"
    Environment = var.environment
  }
}

resource "aws_sns_topic" "clientes_geral" {
  name = "clientes-geral"
  
  tags = {
    Name        = "clientes-geral"
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
          "sns:Publish",
          "sns:Subscribe",
          "sns:CreateTopic"
        ]
        Resource = [
          aws_sns_topic.clientes_premium.arn,
          aws_sns_topic.clientes_regiao_sul.arn,
          aws_sns_topic.clientes_geral.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = [
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
      DYNAMODB_TABLE         = aws_dynamodb_table.campanhas_metricas.name
      SNS_TOPIC_PREMIUM      = aws_sns_topic.clientes_premium.arn
      SNS_TOPIC_REGIAO_SUL   = aws_sns_topic.clientes_regiao_sul.arn
      SNS_TOPIC_GERAL        = aws_sns_topic.clientes_geral.arn
      SQS_EMAIL_QUEUE        = aws_sqs_queue.email_notifications.url
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

# SNS Subscriptions para SQS (para reprocessar emails)
resource "aws_sns_topic_subscription" "premium_to_sqs" {
  topic_arn = aws_sns_topic.clientes_premium.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.email_notifications.arn
}

resource "aws_sns_topic_subscription" "regiao_sul_to_sqs" {
  topic_arn = aws_sns_topic.clientes_regiao_sul.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.email_notifications.arn
}

resource "aws_sns_topic_subscription" "geral_to_sqs" {
  topic_arn = aws_sns_topic.clientes_geral.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.email_notifications.arn
}

# Permissions para SNS publicar no SQS
resource "aws_sqs_queue_policy" "email_queue_policy" {
  queue_url = aws_sqs_queue.email_notifications.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = "sqs:SendMessage"
        Resource = aws_sqs_queue.email_notifications.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = [
              aws_sns_topic.clientes_premium.arn,
              aws_sns_topic.clientes_regiao_sul.arn,
              aws_sns_topic.clientes_geral.arn
            ]
          }
        }
      }
    ]
  })
}