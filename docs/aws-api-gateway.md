# AWS api-gateway Module

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_api_gateway_api_key.rest_api_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_api_key) | resource |
| [aws_api_gateway_authorizer.cognito_authorizer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_authorizer) | resource |
| [aws_api_gateway_deployment.rest_deployment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment) | resource |
| [aws_api_gateway_integration.rest_endpoint_integrations](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_integration_response.rest_endpoint_integration_responses](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration_response) | resource |
| [aws_api_gateway_method.rest_endpoint_methods](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method) | resource |
| [aws_api_gateway_method_response.rest_endpoint_method_responses](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_response) | resource |
| [aws_api_gateway_resource.base_resources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.main_resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.variable_resources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_rest_api.rest_api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api) | resource |
| [aws_api_gateway_stage.rest_stage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_stage) | resource |
| [aws_api_gateway_usage_plan.rest_usage_plan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_usage_plan) | resource |
| [aws_api_gateway_usage_plan_key.rest_usage_plan_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_usage_plan_key) | resource |
| [aws_apigatewayv2_api.http_api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api) | resource |
| [aws_apigatewayv2_authorizer.jwt_authorizer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_authorizer) | resource |
| [aws_apigatewayv2_integration.http_integration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_integration) | resource |
| [aws_apigatewayv2_route.http_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_stage.http_stage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_stage) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_TagEnv"></a> [TagEnv](#input\_TagEnv) | Ambiente (dev, staging, prod) | `string` | n/a | yes |
| <a name="input_TagProject"></a> [TagProject](#input\_TagProject) | Nome do projeto | `string` | n/a | yes |
| <a name="input_api_type"></a> [api\_type](#input\_api\_type) | Tipo de API Gateway: 'REST' ou 'HTTP' | `string` | `"REST"` | no |
| <a name="input_cognito_user_pool_arn"></a> [cognito\_user\_pool\_arn](#input\_cognito\_user\_pool\_arn) | ARN completo do User Pool do Cognito, se disponível | `string` | `null` | no |
| <a name="input_cognito_user_pool_client_id"></a> [cognito\_user\_pool\_client\_id](#input\_cognito\_user\_pool\_client\_id) | ID do Client do User Pool do Cognito | `string` | `null` | no |
| <a name="input_cognito_user_pool_id"></a> [cognito\_user\_pool\_id](#input\_cognito\_user\_pool\_id) | ID do User Pool do Cognito para autenticação | `string` | `null` | no |
| <a name="input_cognito_user_pool_issuer"></a> [cognito\_user\_pool\_issuer](#input\_cognito\_user\_pool\_issuer) | URL do emissor do Cognito User Pool para autenticação JWT | `string` | `null` | no |
| <a name="input_quota_limit"></a> [quota\_limit](#input\_quota\_limit) | Limite do plano de quota | `number` | `null` | no |
| <a name="input_quota_period"></a> [quota\_period](#input\_quota\_period) | Período para o limite de quota (DAY, WEEK, MONTH) | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | Região da AWS onde os recursos serão criados | `string` | n/a | yes |
| <a name="input_routes"></a> [routes](#input\_routes) | Configuração de múltiplas rotas para a API.<br><br>main\_path: (string)<br>  Caminho principal da API (opcional para API REST, será o prefixo de todos os paths)<br>  Exemplo: "api", "v1", "secure-data"<br><br>methods: (list)<br>  Lista de métodos/endpoints da API, cada um contendo:<br><br>  path: (string)<br>    Caminho do endpoint na API. Pode incluir parâmetros de caminho entre chaves.<br>    Exemplos: "produtos", "produtos/{id}", "clientes/{clienteId}/pedidos"<br><br>  method: (string)<br>    Método HTTP para o endpoint.<br>    Valores válidos: GET, POST, PUT, DELETE, PATCH, OPTIONS, HEAD<br><br>  api\_key\_required: (bool)<br>    Define se o endpoint requer autenticação via API Key.<br>    true = API Key obrigatória, false = acesso público<br><br>  status\_code: (string)<br>    Código de status HTTP padrão para respostas bem-sucedidas.<br>    Exemplos: "200", "201", "204"<br><br>  request\_parameters: (map(bool))<br>    Mapa de parâmetros de requisição e se são obrigatórios.<br>    Exemplo: { "method.request.path.id" = true } torna o parâmetro 'id' obrigatório<br><br>  integration\_type: (string)<br>    Tipo de integração do API Gateway com o backend.<br>    Valores possíveis:<br>      - MOCK: Resposta simulada sem backend real<br>      - AWS\_PROXY: Integração Lambda Proxy (recomendado para Lambda)<br>      - AWS: Integração Lambda não-proxy (permite transformação)<br>      - HTTP\_PROXY: Proxy direto para HTTP/HTTPS<br>      - HTTP: Integração HTTP não-proxy (permite transformação)<br><br>  integration\_uri: (string)<br>    URI para o serviço de backend.<br>    Para Lambda: ARN da função (arn:aws:lambda:region:account:function:name)<br>    Para HTTP: URL completa (https://api.exemplo.com/recurso)<br><br>  integration\_method: (string)<br>    Método HTTP usado pelo API Gateway para se comunicar com o backend.<br>    Para Lambda (AWS\_PROXY): Sempre "POST"<br>    Para HTTP: Qualquer método válido (GET, POST, etc.)<br><br>  use\_mock\_response: (bool)<br>    Define se deve usar um template de resposta mock.<br>    true = usar template, false = passar resposta do backend diretamente<br><br>  mock\_template: (string)<br>    Template de resposta em formato JSON ou VTL (Velocity Template Language).<br>    Usado quando integration\_type é "MOCK" ou use\_mock\_response é true.<br><br>  auth\_type: (string)<br>    Tipo de autorização.<br>    Valores válidos: "NONE", "API\_KEY", "COGNITO", "JWT" | <pre>object({<br>    main_path = optional(string, "")<br>    methods = list(object({<br>      path               = string<br>      method             = string<br>      api_key_required   = bool<br>      status_code        = string<br>      request_parameters = map(bool)<br>      authorization      = string<br>      integration_type   = string<br>      integration_uri    = string<br>      integration_method = string<br>      use_mock_response  = bool<br>      mock_template      = string<br>      auth_type          = string<br>    }))<br>  })</pre> | n/a | yes |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | Nome do estágio da API Gateway | `string` | `"v1"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags adicionais para o recurso | `map(string)` | n/a | yes |
| <a name="input_throttle_burst_limit"></a> [throttle\_burst\_limit](#input\_throttle\_burst\_limit) | Limite de burst de throttling | `number` | `null` | no |
| <a name="input_throttle_rate_limit"></a> [throttle\_rate\_limit](#input\_throttle\_rate\_limit) | Taxa de limite de throttling | `number` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_id"></a> [api\_id](#output\_api\_id) | ID da API Gateway |
| <a name="output_api_key_id"></a> [api\_key\_id](#output\_api\_key\_id) | ID da chave de API, se criada (apenas para REST API com API Key) |
| <a name="output_api_key_value"></a> [api\_key\_value](#output\_api\_key\_value) | Valor da chave de API, se criada (apenas para REST API com API Key) |
| <a name="output_api_name"></a> [api\_name](#output\_api\_name) | Nome da API Gateway |
| <a name="output_api_resource_paths"></a> [api\_resource\_paths](#output\_api\_resource\_paths) | Caminhos dos recursos da API |
| <a name="output_authorizer_id"></a> [authorizer\_id](#output\_authorizer\_id) | ID do autorizador JWT/Cognito, se criado |
| <a name="output_http_api_execution_arn"></a> [http\_api\_execution\_arn](#output\_http\_api\_execution\_arn) | Execution ARN da HTTP API |
| <a name="output_rest_api_execution_arn"></a> [rest\_api\_execution\_arn](#output\_rest\_api\_execution\_arn) | Execution ARN da REST API |
| <a name="output_stage_url"></a> [stage\_url](#output\_stage\_url) | URL do estágio da API |
| <a name="output_usage_plan_id"></a> [usage\_plan\_id](#output\_usage\_plan\_id) | ID do plano de uso, se criado (apenas para REST API com API Key) |
