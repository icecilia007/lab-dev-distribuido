output "api_id" {
  description = "ID da API Gateway"
  value       = local.is_rest_api ? aws_api_gateway_rest_api.rest_api[0].id : aws_apigatewayv2_api.http_api[0].id
}

output "api_name" {
  description = "Nome da API Gateway"
  value       = local.is_rest_api ? aws_api_gateway_rest_api.rest_api[0].name : aws_apigatewayv2_api.http_api[0].name
}

output "stage_url" {
  description = "URL do estágio da API"
  value       = local.is_rest_api ? "${aws_api_gateway_rest_api.rest_api[0].execution_arn}/stages/${aws_api_gateway_stage.rest_stage[0].stage_name}" : aws_apigatewayv2_stage.http_stage[0].execution_arn
}

output "api_resource_paths" {
  description = "Caminhos dos recursos da API"
  value = local.is_rest_api ? {
    base_resources     = { for k, v in aws_api_gateway_resource.base_resources : k => v.path_part },
    variable_resources = { for k, v in aws_api_gateway_resource.variable_resources : k => v.path_part }
  } : null
}

output "api_key_id" {
  description = "ID da chave de API, se criada (apenas para REST API com API Key)"
  value       = local.is_rest_api && local.use_api_key ? aws_api_gateway_api_key.rest_api_key[0].id : null
}

output "api_key_value" {
  description = "Valor da chave de API, se criada (apenas para REST API com API Key)"
  value       = local.is_rest_api && local.use_api_key ? aws_api_gateway_api_key.rest_api_key[0].value : null
  sensitive   = true
}

output "usage_plan_id" {
  description = "ID do plano de uso, se criado (apenas para REST API com API Key)"
  value       = local.is_rest_api && local.use_api_key ? aws_api_gateway_usage_plan.rest_usage_plan[0].id : null
}

output "rest_api_execution_arn" {
  description = "Execution ARN da REST API"
  value       = local.is_rest_api ? aws_api_gateway_rest_api.rest_api[0].execution_arn : null
}

output "http_api_execution_arn" {
  description = "Execution ARN da HTTP API"
  value       = local.is_http_api ? aws_apigatewayv2_api.http_api[0].execution_arn : null
}

output "authorizer_id" {
  description = "ID do autorizador JWT/Cognito, se criado"
  value       = local.is_rest_api && local.use_cognito_or_jwt ? aws_api_gateway_authorizer.cognito_authorizer[0].id : (local.is_http_api && local.use_cognito_or_jwt ? aws_apigatewayv2_authorizer.jwt_authorizer[0].id : null)
}
