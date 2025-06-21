terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

locals {
  include_quota_settings    = var.quota_limit != null && var.quota_period != null
  include_throttle_settings = var.throttle_burst_limit != null || var.throttle_rate_limit != null
  is_rest_api               = var.api_type == "REST"
  is_http_api               = var.api_type == "HTTP"

  use_cognito_or_jwt = anytrue([
    for method in var.routes.methods :
    method.auth_type == "COGNITO" || method.auth_type == "JWT"
    ])

  use_api_key = anytrue([
    for method in var.routes.methods :
    method.auth_type == "API_KEY"
    ])

  create_main_resource = local.is_rest_api && var.routes.main_path != ""
  http_route_paths = [
    for method in var.routes.methods :
    var.routes.main_path != "" ? "${var.routes.main_path}/${method.path}" : method.path
  ]

  route_path_parts = {
    for idx, method in var.routes.methods :
    idx => {
      full_path    = method.path
      has_variable = can(regex("\\{.+\\}", method.path))
      parts        = split("/", method.path)
    }
  }

  route_path_components = {
    for idx, info in local.route_path_parts :
    idx => {
      base_path        = length(info.parts) > 1 ? info.parts[0] : info.full_path
      has_second_level = length(info.parts) > 1
      second_level     = length(info.parts) > 1 ? info.parts[1] : ""
      full_path        = info.full_path
    }
  }

  base_paths = {
    for idx, comp in local.route_path_components :
    comp.base_path => comp.base_path...
  }

  resource_base_paths = {
    for base_path, _ in local.base_paths :
    base_path => {
      path_part     = base_path
      full_path     = base_path
      has_variables = false
    }
  }

  resource_path_variables = {
    for idx, comp in local.route_path_components :
    idx => {
      parent_path   = comp.base_path
      variable_part = comp.second_level
      full_path     = comp.full_path
    }
    if comp.has_second_level
  }

  method_resource_mappings = {
    for idx, method in var.routes.methods :
    idx => (
      local.is_rest_api ? (
      length(split("/", method.path)) > 1
      ? aws_api_gateway_resource.variable_resources[idx].id
      : aws_api_gateway_resource.base_resources[method.path].id
    ) : "http-api-no-resource-needed"
    )
  }

}


resource "aws_api_gateway_rest_api" "rest_api" {
  count       = local.is_rest_api ? 1 : 0
  name        = "${var.TagEnv}-${var.TagProject}-api"
  description = "API REST para ${var.TagProject} em ambiente ${var.TagEnv}"

  tags = merge(
    var.tags,
    {
      Name        = "${var.TagEnv}-${var.TagProject}-api"
      Environment = var.TagEnv
      Project     = var.TagProject
    }
  )
}

resource "aws_api_gateway_resource" "main_resource" {
  count       = local.create_main_resource ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.rest_api[0].id
  parent_id   = aws_api_gateway_rest_api.rest_api[0].root_resource_id
  path_part   = var.routes.main_path
}

resource "aws_api_gateway_resource" "base_resources" {
  for_each    = local.is_rest_api ? local.resource_base_paths : {}
  rest_api_id = aws_api_gateway_rest_api.rest_api[0].id
  parent_id   = local.create_main_resource ? aws_api_gateway_resource.main_resource[0].id : aws_api_gateway_rest_api.rest_api[0].root_resource_id
  path_part   = each.value.path_part
}

resource "aws_api_gateway_resource" "variable_resources" {
  for_each    = local.is_rest_api ? local.resource_path_variables : {}
  rest_api_id = aws_api_gateway_rest_api.rest_api[0].id
  parent_id   = aws_api_gateway_resource.base_resources[each.value.parent_path].id
  path_part   = each.value.variable_part
}

resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  count         = local.is_rest_api && local.use_cognito_or_jwt ? 1 : 0
  name          = "${var.TagEnv}-${var.TagProject}-cognito-authorizer"
  rest_api_id   = aws_api_gateway_rest_api.rest_api[0].id
  type          = "COGNITO_USER_POOLS"
  provider_arns = var.cognito_user_pool_arn != null ? [var.cognito_user_pool_arn] : ["arn:aws:cognito-idp:${var.region}:123456789012:userpool/${var.cognito_user_pool_id}"]
}

resource "aws_api_gateway_method" "rest_endpoint_methods" {
  for_each           = local.is_rest_api ? { for idx, method in var.routes.methods : idx => method } : {}
  rest_api_id        = aws_api_gateway_rest_api.rest_api[0].id
  resource_id        = local.method_resource_mappings[each.key]
  http_method        = each.value.method
  authorization      = each.value.auth_type == "NONE" ? "NONE" : each.value.auth_type == "API_KEY" ? "NONE" : "COGNITO_USER_POOLS"
  authorizer_id      = each.value.auth_type == "COGNITO" || each.value.auth_type == "JWT" ? aws_api_gateway_authorizer.cognito_authorizer[0].id : null
  api_key_required   = each.value.auth_type == "API_KEY"
  request_parameters = each.value.request_parameters
}

resource "aws_api_gateway_integration" "rest_endpoint_integrations" {
  for_each    = local.is_rest_api ? { for idx, method in var.routes.methods : idx => method } : {}
  rest_api_id = aws_api_gateway_rest_api.rest_api[0].id
  resource_id = local.method_resource_mappings[each.key]
  http_method = aws_api_gateway_method.rest_endpoint_methods[each.key].http_method
  type        = each.value.integration_type

  uri = each.value.integration_type == "AWS_PROXY" ? (
    can(regex("^arn:aws:apigateway:", each.value.integration_uri)) ?
    each.value.integration_uri :
      contains(split(":", each.value.integration_uri), "lambda") ?
      "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${each.value.integration_uri}/invocations" :
      each.value.integration_uri
  ) : (
    each.value.integration_type != "MOCK" ? each.value.integration_uri : null
  )

  integration_http_method = each.value.integration_type != "MOCK" ? each.value.integration_method : null
  request_templates = each.value.integration_type == "MOCK" ? {
    "application/json" = jsonencode({
      statusCode = tonumber(each.value.status_code)
    })
  } : null

  passthrough_behavior = each.value.integration_type != "MOCK" ? "WHEN_NO_TEMPLATES" : "NEVER"
}

resource "aws_api_gateway_method_response" "rest_endpoint_method_responses" {
  for_each    = local.is_rest_api ? { for idx, method in var.routes.methods : idx => method } : {}
  rest_api_id = aws_api_gateway_rest_api.rest_api[0].id
  resource_id = local.method_resource_mappings[each.key]
  http_method = aws_api_gateway_method.rest_endpoint_methods[each.key].http_method
  status_code = each.value.status_code

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "rest_endpoint_integration_responses" {
  for_each    = local.is_rest_api ? { for idx, method in var.routes.methods : idx => method } : {}
  rest_api_id = aws_api_gateway_rest_api.rest_api[0].id
  resource_id = local.method_resource_mappings[each.key]
  http_method = aws_api_gateway_method.rest_endpoint_methods[each.key].http_method
  status_code = aws_api_gateway_method_response.rest_endpoint_method_responses[each.key].status_code
  response_templates = each.value.use_mock_response ? {
    "application/json" = each.value.mock_template
  } : null

  depends_on = [
    aws_api_gateway_method.rest_endpoint_methods,
    aws_api_gateway_method_response.rest_endpoint_method_responses,
    aws_api_gateway_integration.rest_endpoint_integrations
  ]
}

resource "aws_api_gateway_deployment" "rest_deployment" {
  count       = local.is_rest_api ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.rest_api[0].id

  triggers = {
    redeployment = sha1(jsonencode({
      routes                = var.routes
      integrations          = [for k, v in aws_api_gateway_integration.rest_endpoint_integrations : v.id]
      integration_responses = [for k, v in aws_api_gateway_integration_response.rest_endpoint_integration_responses : v.id]
      methods               = [for k, v in aws_api_gateway_method.rest_endpoint_methods : v.id]
      method_responses      = [for k, v in aws_api_gateway_method_response.rest_endpoint_method_responses : v.id]
    }))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.rest_endpoint_integrations,
    aws_api_gateway_integration_response.rest_endpoint_integration_responses,
    aws_api_gateway_method.rest_endpoint_methods,
    aws_api_gateway_method_response.rest_endpoint_method_responses
  ]
}

resource "aws_api_gateway_stage" "rest_stage" {
  count         = local.is_rest_api ? 1 : 0
  deployment_id = aws_api_gateway_deployment.rest_deployment[0].id
  rest_api_id   = aws_api_gateway_rest_api.rest_api[0].id
  stage_name    = var.stage_name
}

resource "aws_api_gateway_usage_plan" "rest_usage_plan" {
  count       = local.is_rest_api && local.use_api_key ? 1 : 0
  name        = "${var.TagEnv}-${var.TagProject}-usage-plan"
  description = "Plano de uso para a API de ${var.TagProject} em ambiente ${var.TagEnv}"

  api_stages {
    api_id = aws_api_gateway_rest_api.rest_api[0].id
    stage  = aws_api_gateway_stage.rest_stage[0].stage_name
  }

  dynamic "quota_settings" {
    for_each = local.include_quota_settings ? [1] : []
    content {
      limit  = var.quota_limit
      period = var.quota_period
    }
  }

  dynamic "throttle_settings" {
    for_each = local.include_throttle_settings ? [1] : []
    content {
      burst_limit = var.throttle_burst_limit
      rate_limit  = var.throttle_rate_limit
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.TagEnv}-${var.TagProject}-usage-plan"
      Environment = var.TagEnv
      Project     = var.TagProject
    }
  )
}

resource "aws_api_gateway_api_key" "rest_api_key" {
  count = local.is_rest_api && local.use_api_key ? 1 : 0
  name  = "${var.TagEnv}-${var.TagProject}-api-key"

  tags = merge(
    var.tags,
    {
      Name        = "${var.TagEnv}-${var.TagProject}-api-key"
      Environment = var.TagEnv
      Project     = var.TagProject
    }
  )
}

resource "aws_api_gateway_usage_plan_key" "rest_usage_plan_key" {
  count         = local.is_rest_api && local.use_api_key ? 1 : 0
  key_id        = aws_api_gateway_api_key.rest_api_key[0].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.rest_usage_plan[0].id
}

resource "aws_apigatewayv2_api" "http_api" {
  count         = local.is_http_api ? 1 : 0
  name          = "${var.TagEnv}-${var.TagProject}-http-api"
  protocol_type = "HTTP"
  description   = "API HTTP para ${var.TagProject} em ambiente ${var.TagEnv}"

  tags = merge(
    var.tags,
    {
      Name        = "${var.TagEnv}-${var.TagProject}-http-api"
      Environment = var.TagEnv
      Project     = var.TagProject
    }
  )
}

resource "aws_apigatewayv2_authorizer" "jwt_authorizer" {
  count            = local.is_http_api && local.use_cognito_or_jwt ? 1 : 0
  api_id           = aws_apigatewayv2_api.http_api[0].id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${var.TagEnv}-${var.TagProject}-jwt-authorizer"

  jwt_configuration {
    audience = [var.cognito_user_pool_client_id]
    issuer   = var.cognito_user_pool_issuer != null ? var.cognito_user_pool_issuer : "https://cognito-idp.${var.region}.amazonaws.com/${var.cognito_user_pool_id}"
  }
}

resource "aws_apigatewayv2_integration" "http_integration" {
  for_each               = local.is_http_api ? { for idx, method in var.routes.methods : idx => method } : {}
  api_id                 = aws_apigatewayv2_api.http_api[0].id
  integration_type       = each.value.integration_type == "AWS_PROXY" ? "AWS_PROXY" : (each.value.integration_type == "HTTP_PROXY" ? "HTTP_PROXY" : "AWS_PROXY")
  integration_uri        = each.value.integration_uri
  integration_method     = each.value.integration_method
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "http_route" {
  for_each           = local.is_http_api ? { for idx, method in var.routes.methods : idx => method } : {}
  api_id             = aws_apigatewayv2_api.http_api[0].id
  route_key          = "${each.value.method} /${local.http_route_paths[tonumber(each.key)]}"
  authorization_type = each.value.auth_type == "NONE" ? "AWS_IAM" : (each.value.auth_type == "JWT" || each.value.auth_type == "COGNITO") ? "JWT" : "AWS_IAM"
  authorizer_id      = each.value.auth_type == "JWT" || each.value.auth_type == "COGNITO" ? aws_apigatewayv2_authorizer.jwt_authorizer[0].id : null
  target             = "integrations/${aws_apigatewayv2_integration.http_integration[each.key].id}"
}

resource "aws_apigatewayv2_stage" "http_stage" {
  count       = local.is_http_api ? 1 : 0
  api_id      = aws_apigatewayv2_api.http_api[0].id
  name        = var.stage_name
  auto_deploy = true

  tags = merge(
    var.tags,
    {
      Name        = "${var.TagEnv}-${var.TagProject}-stage"
      Environment = var.TagEnv
      Project     = var.TagProject
    }
  )
}
