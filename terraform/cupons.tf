# DynamoDB Table para Cupons
resource "aws_dynamodb_table" "cupons" {
  name           = "cupons"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "cupom_id"

  attribute {
    name = "cupom_id"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  global_secondary_index {
    name            = "status-index"
    hash_key        = "status"
    projection_type = "ALL"
  }

  tags = {
    Name        = "cupons"
    Environment = var.environment
  }
}

# IAM Role para Lambda de Cupons
resource "aws_iam_role" "cupons_lambda_role" {
  name = "cupons-lambda-role"

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

# IAM Policy para Lambda de Cupons
resource "aws_iam_role_policy" "cupons_lambda_policy" {
  name = "cupons-lambda-policy"
  role = aws_iam_role.cupons_lambda_role.id

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
          "dynamodb:DeleteItem",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.cupons.arn,
          "${aws_dynamodb_table.cupons.arn}/index/*"
        ]
      }
    ]
  })
}

# CloudWatch Log Group para Lambda de Cupons
resource "aws_cloudwatch_log_group" "cupons_lambda_logs" {
  name              = "/aws/lambda/cupons-api"
  retention_in_days = 14
}

data "archive_file" "cupons_zip" {
  type        = "zip"
  source_file = "../lambda/cupons/lambda_function.py"
  output_path = "cupons.zip"
}

# Lambda Function para Cupons
resource "aws_lambda_function" "cupons_api" {
  filename         = data.archive_file.cupons_zip.output_path
  function_name    = "cupons-api"
  role            = aws_iam_role.cupons_lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.11"
  timeout         = 30

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.cupons.name
    }
  }

  depends_on = [
    aws_iam_role_policy.cupons_lambda_policy,
    aws_cloudwatch_log_group.cupons_lambda_logs,
  ]

  tags = {
    Name        = "cupons-api"
    Environment = var.environment
  }
}

# API Gateway
resource "aws_api_gateway_rest_api" "cupons_api" {
  name        = "cupons-api"
  description = "API para gerenciamento de cupons"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = "cupons-api"
    Environment = var.environment
  }
}

# API Gateway Resource - /cupons
resource "aws_api_gateway_resource" "cupons" {
  rest_api_id = aws_api_gateway_rest_api.cupons_api.id
  parent_id   = aws_api_gateway_rest_api.cupons_api.root_resource_id
  path_part   = "cupons"
}

# API Gateway Resource - /cupons/{id}
resource "aws_api_gateway_resource" "cupom_by_id" {
  rest_api_id = aws_api_gateway_rest_api.cupons_api.id
  parent_id   = aws_api_gateway_resource.cupons.id
  path_part   = "{id}"
}

# API Gateway Method - GET /cupons (listar cupons disponíveis)
resource "aws_api_gateway_method" "list_cupons" {
  rest_api_id   = aws_api_gateway_rest_api.cupons_api.id
  resource_id   = aws_api_gateway_resource.cupons.id
  http_method   = "GET"
  authorization = "NONE"
}

# API Gateway Method - GET /cupons/{id} (buscar cupom específico)
resource "aws_api_gateway_method" "get_cupom" {
  rest_api_id   = aws_api_gateway_rest_api.cupons_api.id
  resource_id   = aws_api_gateway_resource.cupom_by_id.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.id" = true
  }
}

# API Gateway Integration - GET /cupons
resource "aws_api_gateway_integration" "list_cupons_integration" {
  rest_api_id = aws_api_gateway_rest_api.cupons_api.id
  resource_id = aws_api_gateway_resource.cupons.id
  http_method = aws_api_gateway_method.list_cupons.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.cupons_api.invoke_arn
}

# API Gateway Integration - GET /cupons/{id}
resource "aws_api_gateway_integration" "get_cupom_integration" {
  rest_api_id = aws_api_gateway_rest_api.cupons_api.id
  resource_id = aws_api_gateway_resource.cupom_by_id.id
  http_method = aws_api_gateway_method.get_cupom.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.cupons_api.invoke_arn
}

# Lambda Permission para API Gateway - listar cupons
resource "aws_lambda_permission" "api_gateway_list_cupons" {
  statement_id  = "AllowExecutionFromAPIGatewayList"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cupons_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.cupons_api.execution_arn}/*/*"
}

# Lambda Permission para API Gateway - buscar cupom
resource "aws_lambda_permission" "api_gateway_get_cupom" {
  statement_id  = "AllowExecutionFromAPIGatewayGet"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cupons_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.cupons_api.execution_arn}/*/*"
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "cupons_api_deployment" {
  depends_on = [
    aws_api_gateway_integration.list_cupons_integration,
    aws_api_gateway_integration.get_cupom_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.cupons_api.id
  stage_name  = "prod"

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.cupons.id,
      aws_api_gateway_resource.cupom_by_id.id,
      aws_api_gateway_method.list_cupons.id,
      aws_api_gateway_method.get_cupom.id,
      aws_api_gateway_integration.list_cupons_integration.id,
      aws_api_gateway_integration.get_cupom_integration.id,
      try(aws_api_gateway_resource.campanhas.id, ""),
      try(aws_api_gateway_resource.campanhas_trigger.id, ""),
      try(aws_api_gateway_method.trigger_campanha.id, ""),
      try(aws_api_gateway_integration.trigger_campanha_integration.id, ""),
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}