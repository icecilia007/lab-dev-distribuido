# Main Terraform configuration for AWS Serverless Logistics
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "logistics"
}

# Local variables
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# DynamoDB Tables
module "users_table" {
  source = "./aws/dynamodb"
  
  TagEnv       = var.environment
  TagProject   = var.project_name
  table_name   = "users"
  hash_key     = "email"
  sort_key     = ""
  tags         = local.common_tags
}

module "pedidos_table" {
  source = "./aws/dynamodb"
  
  TagEnv       = var.environment
  TagProject   = var.project_name
  table_name   = "pedidos"
  hash_key     = "id"
  sort_key     = ""
  tags         = local.common_tags
}

module "locations_table" {
  source = "./aws/dynamodb"
  
  TagEnv       = var.environment
  TagProject   = var.project_name
  table_name   = "locations"
  hash_key     = "id"
  sort_key     = ""
  tags         = local.common_tags
}

module "notifications_table" {
  source = "./aws/dynamodb"
  
  TagEnv       = var.environment
  TagProject   = var.project_name
  table_name   = "notifications"
  hash_key     = "id"
  sort_key     = ""
  tags         = local.common_tags
}

module "websocket_connections_table" {
  source = "./aws/dynamodb"
  
  TagEnv       = var.environment
  TagProject   = var.project_name
  table_name   = "websocket-connections"
  hash_key     = "connectionId"
  sort_key     = ""
  tags         = local.common_tags
}

module "pedido_ofertas_table" {
  source = "./aws/dynamodb"
  
  TagEnv       = var.environment
  TagProject   = var.project_name
  table_name   = "pedido-ofertas"
  hash_key     = "id"
  sort_key     = ""
  tags         = local.common_tags
}

# SQS Queue for Events
module "events_queue" {
  source = "./aws/sqs"
  
  TagEnv     = var.environment
  TagProject = var.project_name
  sqs_name   = "events"
  tags       = local.common_tags
}

# SNS Topics for Segmented Notifications (Pub/Sub Topics from diagram)
module "notifications_general_topic" {
  source = "./aws/sns"
  
  TagEnv     = var.environment
  TagProject = var.project_name
  Name       = "notifications-general"
  emails_sns = ["admin@logistics.com"]
  tags       = local.common_tags
}

module "notifications_premium_topic" {
  source = "./aws/sns"
  
  TagEnv     = var.environment
  TagProject = var.project_name
  Name       = "notifications-premium"
  emails_sns = ["admin@logistics.com"]
  tags       = local.common_tags
}

module "notifications_regional_topic" {
  source = "./aws/sns"
  
  TagEnv     = var.environment
  TagProject = var.project_name
  Name       = "notifications-regional"
  emails_sns = ["admin@logistics.com"]
  tags       = local.common_tags
}

# Lambda Functions
module "auth_lambda" {
  source = "./aws/lambda_image"
  
  TagEnv         = var.environment
  TagProject     = var.project_name
  lambda_name    = "auth"
  folder         = "aws-serverless-logistics/functions/auth"
  files          = ["Dockerfile", "lambda_function.py", "requirements.txt"]
  aws_region     = var.aws_region
  tag_image      = "latest"
  memory         = 512
  timeout        = 30
  description    = "Authentication Lambda function"
  
  environment_variables = {
    USERS_TABLE = module.users_table.name
    JWT_SECRET  = "your-jwt-secret-key"
  }
  
  additional_policies = [
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  ]
  
  tags = local.common_tags
}

module "usuarios_lambda" {
  source = "./aws/lambda_image"
  
  TagEnv         = var.environment
  TagProject     = var.project_name
  lambda_name    = "usuarios"
  folder         = "aws-serverless-logistics/functions/usuarios"
  files          = ["Dockerfile", "lambda_function.py", "requirements.txt"]
  aws_region     = var.aws_region
  tag_image      = "latest"
  memory         = 512
  timeout        = 30
  description    = "Users management Lambda function"
  
  environment_variables = {
    USERS_TABLE = module.users_table.name
  }
  
  additional_policies = [
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  ]
  
  tags = local.common_tags
}

module "pedidos_lambda" {
  source = "./aws/lambda_image"
  
  TagEnv         = var.environment
  TagProject     = var.project_name
  lambda_name    = "pedidos"
  folder         = "aws-serverless-logistics/functions/pedidos"
  files          = ["Dockerfile", "lambda_function.py", "requirements.txt"]
  aws_region     = var.aws_region
  tag_image      = "latest"
  memory         = 512
  timeout        = 30
  description    = "Orders management Lambda function"
  
  environment_variables = {
    PEDIDOS_TABLE  = module.pedidos_table.name
    SQS_QUEUE_URL  = module.events_queue.url
  }
  
  additional_policies = [
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
  ]
  
  tags = local.common_tags
}

module "notificacoes_lambda" {
  source = "./aws/lambda_image"
  
  TagEnv         = var.environment
  TagProject     = var.project_name
  lambda_name    = "notificacoes"
  folder         = "aws-serverless-logistics/functions/notificacoes"
  files          = ["Dockerfile", "lambda_function.py", "requirements.txt"]
  aws_region     = var.aws_region
  tag_image      = "latest"
  memory         = 512
  timeout        = 60
  description    = "Notifications Lambda function"
  
  environment_variables = {
    NOTIFICATIONS_TABLE      = module.notifications_table.name
    USERS_TABLE             = module.users_table.name
    SQS_QUEUE_URL          = module.events_queue.url
    SNS_GENERAL_TOPIC_ARN  = module.notifications_general_topic.arn
    SNS_PREMIUM_TOPIC_ARN  = module.notifications_premium_topic.arn
    SNS_REGIONAL_TOPIC_ARN = module.notifications_regional_topic.arn
    WEBSOCKET_LAMBDA_NAME  = module.websocket_lambda.name
    CONNECTIONS_TABLE      = module.websocket_connections_table.name
  }
  
  additional_policies = [
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess",
    "arn:aws:iam::aws:policy/AmazonSNSFullAccess",
    "arn:aws:iam::aws:policy/AmazonSESFullAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
  ]
  
  tags = local.common_tags
}

module "rastreamento_lambda" {
  source = "./aws/lambda_image"
  
  TagEnv         = var.environment
  TagProject     = var.project_name
  lambda_name    = "rastreamento"
  folder         = "aws-serverless-logistics/functions/rastreamento"
  files          = ["Dockerfile", "lambda_function.py", "requirements.txt"]
  aws_region     = var.aws_region
  tag_image      = "latest"
  memory         = 512
  timeout        = 30
  description    = "Tracking Lambda function"
  
  environment_variables = {
    LOCATIONS_TABLE = module.locations_table.name
    PEDIDOS_TABLE   = module.pedidos_table.name
    SQS_QUEUE_URL   = module.events_queue.url
  }
  
  additional_policies = [
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
  ]
  
  tags = local.common_tags
}

module "websocket_lambda" {
  source = "./aws/lambda_image"
  
  TagEnv         = var.environment
  TagProject     = var.project_name
  lambda_name    = "websocket"
  folder         = "aws-serverless-logistics/functions/websocket"
  files          = ["Dockerfile", "lambda_function.py", "requirements.txt"]
  aws_region     = var.aws_region
  tag_image      = "latest"
  memory         = 512
  timeout        = 30
  description    = "WebSocket Lambda function for real-time notifications"
  
  environment_variables = {
    CONNECTIONS_TABLE      = module.websocket_connections_table.name
    JWT_SECRET            = "your-jwt-secret-key"
    WEBSOCKET_API_ENDPOINT = "https://${aws_apigatewayv2_api.websocket_api.id}.execute-api.${var.aws_region}.amazonaws.com/prod"
  }
  
  additional_policies = [
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/AmazonAPIGatewayInvokeFullAccess"
  ]
  
  tags = local.common_tags
}

module "smart_routing_lambda" {
  source = "./aws/lambda_image"
  
  TagEnv         = var.environment
  TagProject     = var.project_name
  lambda_name    = "smart-routing"
  folder         = "aws-serverless-logistics/functions/smart-routing"
  files          = ["Dockerfile", "lambda_function.py", "requirements.txt"]
  aws_region     = var.aws_region
  tag_image      = "latest"
  memory         = 1024
  timeout        = 60
  description    = "Smart routing Lambda for intelligent driver assignment"
  
  environment_variables = {
    USERS_TABLE              = module.users_table.name
    PEDIDOS_TABLE           = module.pedidos_table.name
    OFERTAS_TABLE           = module.pedido_ofertas_table.name
    SQS_QUEUE_URL           = module.events_queue.url
    NOTIFICACOES_LAMBDA_NAME = module.notificacoes_lambda.name
  }
  
  additional_policies = [
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
  ]
  
  tags = local.common_tags
}

# SQS Event Source Mapping for Notifications Lambda
resource "aws_lambda_event_source_mapping" "notifications_sqs_trigger" {
  event_source_arn = module.events_queue.arn
  function_name    = module.notificacoes_lambda.name
  batch_size       = 10
  
  depends_on = [module.notificacoes_lambda]
}

# SQS Event Source Mapping for Smart Routing Lambda
resource "aws_lambda_event_source_mapping" "smart_routing_sqs_trigger" {
  event_source_arn = module.events_queue.arn
  function_name    = module.smart_routing_lambda.name
  batch_size       = 5
  
  depends_on = [module.smart_routing_lambda]
}

# API Gateway
module "api_gateway" {
  source = "./aws/api-gateway"
  
  TagEnv     = var.environment
  TagProject = var.project_name
  region     = var.aws_region
  api_type   = "REST"
  stage_name = "prod"

  routes = {
    main_path = "api"
    methods = [

      # Auth
      {
        path               = "auth/login"
        method             = "POST"
        auth_type          = "NONE"
        integration_type   = "AWS_PROXY"
        integration_uri    = module.auth_lambda.arn
        integration_method = "POST"
        status_code        = "200"
        use_mock_response  = false
        mock_template      = ""
        api_key_required   = false
        authorization      = "NONE"
        request_parameters = {}
      },
      {
        path               = "auth/registro-cliente"
        method             = "POST"
        auth_type          = "NONE"
        integration_type   = "AWS_PROXY"
        integration_uri    = module.usuarios_lambda.arn
        integration_method = "POST"
        status_code        = "201"
        use_mock_response  = false
        mock_template      = ""
        api_key_required   = false
        authorization      = "NONE"
        request_parameters = {}
      },
      {
        path               = "auth/registro-motorista"
        method             = "POST"
        auth_type          = "NONE"
        integration_type   = "AWS_PROXY"
        integration_uri    = module.usuarios_lambda.arn
        integration_method = "POST"
        status_code        = "201"
        use_mock_response  = false
        mock_template      = ""
        api_key_required   = false
        authorization      = "NONE"
        request_parameters = {}
      },

      # Pedidos
      {
        path               = "pedidos"
        method             = "POST"
        auth_type          = "NONE"
        integration_type   = "AWS_PROXY"
        integration_uri    = module.pedidos_lambda.arn
        integration_method = "POST"
        status_code        = "201"
        use_mock_response  = false
        mock_template      = ""
        api_key_required   = false
        authorization      = "NONE"
        request_parameters = {}
      },
      {
        path               = "pedidos/usuario-info/{userType}/{userId}"
        method             = "GET"
        auth_type          = "NONE"
        integration_type   = "AWS_PROXY"
        integration_uri    = module.pedidos_lambda.arn
        integration_method = "POST"
        status_code        = "200"
        use_mock_response  = false
        mock_template      = ""
        api_key_required   = false
        authorization      = "NONE"
        request_parameters = {}
      },
      {
        path               = "pedidos/consulta/{pedidoId}"
        method             = "GET"
        auth_type          = "NONE"
        integration_type   = "AWS_PROXY"
        integration_uri    = module.pedidos_lambda.arn
        integration_method = "POST"
        status_code        = "200"
        use_mock_response  = false
        mock_template      = ""
        api_key_required   = false
        authorization      = "NONE"
        request_parameters = {}
      },
      {
        path               = "pedidos/acoes-aceitar/{pedidoId}"
        method             = "POST"
        auth_type          = "NONE"
        integration_type   = "AWS_PROXY"
        integration_uri    = module.pedidos_lambda.arn
        integration_method = "POST"
        status_code        = "200"
        use_mock_response  = false
        mock_template      = ""
        api_key_required   = false
        authorization      = "NONE"
        request_parameters = {}
      },
      {
        path               = "pedidos/acoes/cancelar/{pedidoId}"
        method             = "PATCH"
        auth_type          = "NONE"
        integration_type   = "AWS_PROXY"
        integration_uri    = module.pedidos_lambda.arn
        integration_method = "POST"
        status_code        = "204"
        use_mock_response  = false
        mock_template      = ""
        api_key_required   = false
        authorization      = "NONE"
        request_parameters = {}
      },

      # Notificações
      {
        path               = "notificacoes/destinatario/{userId}"
        method             = "GET"
        auth_type          = "NONE"
        integration_type   = "AWS_PROXY"
        integration_uri    = module.notificacoes_lambda.arn
        integration_method = "POST"
        status_code        = "200"
        use_mock_response  = false
        mock_template      = ""
        api_key_required   = false
        authorization      = "NONE"
        request_parameters = {}
      },
      {
        path               = "notificacoes/{notificationId}/marcar-lida"
        method             = "PATCH"
        auth_type          = "NONE"
        integration_type   = "AWS_PROXY"
        integration_uri    = module.notificacoes_lambda.arn
        integration_method = "POST"
        status_code        = "204"
        use_mock_response  = false
        mock_template      = ""
        api_key_required   = false
        authorization      = "NONE"
        request_parameters = {}
      },
      {
        path               = "notificacoes/preferencias"
        method             = "POST"
        auth_type          = "NONE"
        integration_type   = "AWS_PROXY"
        integration_uri    = module.notificacoes_lambda.arn
        integration_method = "POST"
        status_code        = "200"
        use_mock_response  = false
        mock_template      = ""
        api_key_required   = false
        authorization      = "NONE"
        request_parameters = {}
      },
      {
        path               = "notificacoes/preferencias-usuario/{userId}"
        method             = "GET"
        auth_type          = "NONE"
        integration_type   = "AWS_PROXY"
        integration_uri    = module.notificacoes_lambda.arn
        integration_method = "POST"
        status_code        = "200"
        use_mock_response  = false
        mock_template      = ""
        api_key_required   = false
        authorization      = "NONE"
        request_parameters = {}
      },
      {
        path               = "notificacoes/nao-lidas/contagem/{userId}"
        method             = "GET"
        auth_type          = "NONE"
        integration_type   = "AWS_PROXY"
        integration_uri    = module.notificacoes_lambda.arn
        integration_method = "POST"
        status_code        = "200"
        use_mock_response  = false
        mock_template      = ""
        api_key_required   = false
        authorization      = "NONE"
        request_parameters = {}
      },

      # Rastreamento
      {
        path               = "rastreamento/status-pedido/{pedidoId}"
        method             = "GET"
        auth_type          = "NONE"
        integration_type   = "AWS_PROXY"
        integration_uri    = module.rastreamento_lambda.arn
        integration_method = "POST"
        status_code        = "200"
        use_mock_response  = false
        mock_template      = ""
        api_key_required   = false
        authorization      = "NONE"
        request_parameters = {}
      },
      {
        path               = "rastreamento/historico-pedido/{pedidoId}"
        method             = "GET"
        auth_type          = "NONE"
        integration_type   = "AWS_PROXY"
        integration_uri    = module.rastreamento_lambda.arn
        integration_method = "POST"
        status_code        = "200"
        use_mock_response  = false
        mock_template      = ""
        api_key_required   = false
        authorization      = "NONE"
        request_parameters = {}
      },
      {
        path               = "rastreamento/acao-coleta/{pedidoId}"
        method             = "POST"
        auth_type          = "NONE"
        integration_type   = "AWS_PROXY"
        integration_uri    = module.rastreamento_lambda.arn
        integration_method = "POST"
        status_code        = "200"
        use_mock_response  = false
        mock_template      = ""
        api_key_required   = false
        authorization      = "NONE"
        request_parameters = {}
      },
      {
        path               = "rastreamento/acao-entrega/{pedidoId}"
        method             = "POST"
        auth_type          = "NONE"
        integration_type   = "AWS_PROXY"
        integration_uri    = module.rastreamento_lambda.arn
        integration_method = "POST"
        status_code        = "200"
        use_mock_response  = false
        mock_template      = ""
        api_key_required   = false
        authorization      = "NONE"
        request_parameters = {}
      },
      {
        path               = "rastreamento/registrar-localizacao"
        method             = "POST"
        auth_type          = "NONE"
        integration_type   = "AWS_PROXY"
        integration_uri    = module.rastreamento_lambda.arn
        integration_method = "POST"
        status_code        = "200"
        use_mock_response  = false
        mock_template      = ""
        api_key_required   = false
        authorization      = "NONE"
        request_parameters = {}
      },
      {
        path               = "rastreamento/motorista/estatisticas/{driverId}"
        method             = "GET"
        auth_type          = "NONE"
        integration_type   = "AWS_PROXY"
        integration_uri    = module.rastreamento_lambda.arn
        integration_method = "POST"
        status_code        = "200"
        use_mock_response  = false
        mock_template      = ""
        api_key_required   = false
        authorization      = "NONE"
        request_parameters = {}
      },
      {
        path               = "smart-routing/buscar-motoristas"
        method             = "POST"
        auth_type          = "NONE"
        integration_type   = "AWS_PROXY"
        integration_uri    = module.smart_routing_lambda.arn
        integration_method = "POST"
        status_code        = "200"
        use_mock_response  = false
        mock_template      = ""
        api_key_required   = false
        authorization      = "NONE"
        request_parameters = {}
      },
      {
        path               = "smart-routing/oferta-motorista/{pedidoId}"
        method             = "POST"
        auth_type          = "NONE"
        integration_type   = "AWS_PROXY"
        integration_uri    = module.smart_routing_lambda.arn
        integration_method = "POST"
        status_code        = "200"
        use_mock_response  = false
        mock_template      = ""
        api_key_required   = false
        authorization      = "NONE"
        request_parameters = {}
      },
      {
        path               = "smart-routing/oferta-aceitar/{ofertaId}"
        method             = "POST"
        auth_type          = "NONE"
        integration_type   = "AWS_PROXY"
        integration_uri    = module.smart_routing_lambda.arn
        integration_method = "POST"
        status_code        = "200"
        use_mock_response  = false
        mock_template      = ""
        api_key_required   = false
        authorization      = "NONE"
        request_parameters = {}
      },
      {
        path               = "smart-routing/oferta-rejeitar/{ofertaId}"
        method             = "POST"
        auth_type          = "NONE"
        integration_type   = "AWS_PROXY"
        integration_uri    = module.smart_routing_lambda.arn
        integration_method = "POST"
        status_code        = "200"
        use_mock_response  = false
        mock_template      = ""
        api_key_required   = false
        authorization      = "NONE"
        request_parameters = {}
      },
      {
        path               = "smart-routing/ofertas-por-motorista/{motoristaId}"
        method             = "GET"
        auth_type          = "NONE"
        integration_type   = "AWS_PROXY"
        integration_uri    = module.smart_routing_lambda.arn
        integration_method = "POST"
        status_code        = "200"
        use_mock_response  = false
        mock_template      = ""
        api_key_required   = false
        authorization      = "NONE"
        request_parameters = {}
      }
    ]
  }




  tags = local.common_tags
}

# WebSocket API Gateway for real-time notifications
resource "aws_apigatewayv2_api" "websocket_api" {
  name                       = "${var.environment}-${var.project_name}-websocket"
  protocol_type             = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
  
  tags = local.common_tags
}

resource "aws_apigatewayv2_stage" "websocket_stage" {
  api_id      = aws_apigatewayv2_api.websocket_api.id
  name        = "prod"
  auto_deploy = true
  
  tags = local.common_tags
}

# WebSocket Routes
resource "aws_apigatewayv2_route" "websocket_connect" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.websocket_connect_integration.id}"
}

resource "aws_apigatewayv2_route" "websocket_disconnect" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.websocket_disconnect_integration.id}"
}

resource "aws_apigatewayv2_route" "websocket_message" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "sendMessage"
  target    = "integrations/${aws_apigatewayv2_integration.websocket_message_integration.id}"
}

# WebSocket Integrations
resource "aws_apigatewayv2_integration" "websocket_connect_integration" {
  api_id           = aws_apigatewayv2_api.websocket_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = module.websocket_lambda.arn
}

resource "aws_apigatewayv2_integration" "websocket_disconnect_integration" {
  api_id           = aws_apigatewayv2_api.websocket_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = module.websocket_lambda.arn
}

resource "aws_apigatewayv2_integration" "websocket_message_integration" {
  api_id           = aws_apigatewayv2_api.websocket_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = module.websocket_lambda.arn
}

# Lambda permissions for API Gateway
resource "aws_lambda_permission" "auth_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.auth_lambda.name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.rest_api_execution_arn}/*/*"
}

resource "aws_lambda_permission" "usuarios_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.usuarios_lambda.name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.rest_api_execution_arn}/*/*"
}

resource "aws_lambda_permission" "pedidos_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.pedidos_lambda.name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.rest_api_execution_arn}/*/*"
}

resource "aws_lambda_permission" "notificacoes_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.notificacoes_lambda.name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.rest_api_execution_arn}/*/*"
}

resource "aws_lambda_permission" "rastreamento_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.rastreamento_lambda.name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.rest_api_execution_arn}/*/*"
}

# WebSocket Lambda permissions
resource "aws_lambda_permission" "websocket_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.websocket_lambda.name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket_api.execution_arn}/*/*"
}

# Smart Routing Lambda permissions
resource "aws_lambda_permission" "smart_routing_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.smart_routing_lambda.name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.rest_api_execution_arn}/*/*"
}

# Outputs
output "api_gateway_id" {
  description = "ID do API Gateway"
  value       = module.api_gateway.api_id
}

output "api_gateway_invoke_url" {
  description = "URL de invocação do API Gateway"
  value       = "https://${module.api_gateway.api_id}.execute-api.${var.aws_region}.amazonaws.com/prod"
}

output "websocket_api_id" {
  description = "ID do WebSocket API Gateway"
  value       = aws_apigatewayv2_api.websocket_api.id
}

output "websocket_api_url" {
  description = "URL do WebSocket API Gateway"
  value       = "wss://${aws_apigatewayv2_api.websocket_api.id}.execute-api.${var.aws_region}.amazonaws.com/prod"
}

output "dynamodb_tables" {
  description = "DynamoDB table names"
  value = {
    users                = module.users_table.name
    pedidos              = module.pedidos_table.name
    locations            = module.locations_table.name
    notifications        = module.notifications_table.name
    websocket_connections = module.websocket_connections_table.name
    pedido_ofertas       = module.pedido_ofertas_table.name
  }
}

output "sqs_queue_url" {
  description = "SQS Queue URL"
  value       = module.events_queue.url
}

output "lambda_functions" {
  description = "Lambda function names"
  value = {
    auth          = module.auth_lambda.name
    usuarios      = module.usuarios_lambda.name
    pedidos       = module.pedidos_lambda.name
    notificacoes  = module.notificacoes_lambda.name
    rastreamento  = module.rastreamento_lambda.name
    websocket     = module.websocket_lambda.name
    smart_routing = module.smart_routing_lambda.name
  }
}

output "sns_topics" {
  description = "SNS Topic ARNs"
  value = {
    general  = module.notifications_general_topic.arn
    premium  = module.notifications_premium_topic.arn
    regional = module.notifications_regional_topic.arn
  }
}