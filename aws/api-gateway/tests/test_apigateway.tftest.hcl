mock_provider "aws" {}
mock_provider "random" {}

run "teste_api_basica_sem_auth" {
  plan_options {
    mode = normal
  }

  variables {
    TagEnv     = "dev"
    TagProject = "myapp"
    region     = "us-east-1"
    api_type   = "REST"
    stage_name = "v1"
    routes = {
      methods = [
        {
          path               = "users"
          method             = "GET"
          status_code        = "200"
          authorization      = "NONE"
          api_key_required   = false
          request_parameters = {}
          integration_type   = "MOCK"
          integration_uri    = "mock://test"
          integration_method = "GET"
          use_mock_response  = true
          mock_template      = "{\"message\": \"Sucesso\"}"
          auth_type          = "NONE"
        }
      ]
    }
    tags = {
      Environment = "Development"
      Project     = "MyApp"
    }
  }

  module {
    source = "./"
  }

  command = plan

  assert {
    condition     = aws_api_gateway_rest_api.rest_api[0].name == "dev-myapp-api"
    error_message = "O nome da API deve ser 'dev-myapp-api'"
  }

  assert {
    condition     = aws_api_gateway_resource.base_resources["users"].path_part == "users"
    error_message = "O path da API deve ser 'users'"
  }

  assert {
    condition     = aws_api_gateway_method.rest_endpoint_methods["0"].http_method == "GET"
    error_message = "O método HTTP deve ser 'GET'"
  }

  assert {
    condition     = aws_api_gateway_method.rest_endpoint_methods["0"].authorization == "NONE"
    error_message = "O tipo de autorização deve ser 'NONE'"
  }

  assert {
    condition     = aws_api_gateway_method.rest_endpoint_methods["0"].api_key_required == false
    error_message = "Não deve requerer API Key"
  }

  assert {
    condition     = aws_api_gateway_integration.rest_endpoint_integrations["0"].type == "MOCK"
    error_message = "O tipo de integração deve ser 'MOCK'"
  }
}

run "teste_api_com_api_key" {
  plan_options {
    mode = normal
  }

  variables {
    TagEnv     = "prod"
    TagProject = "myapp"
    region     = "us-east-1"
    api_type   = "REST"
    stage_name = "v1"
    routes = {
      methods = [
        {
          path               = "secure"
          method             = "POST"
          status_code        = "201"
          authorization      = "NONE"
          api_key_required   = true
          request_parameters = {}
          integration_type   = "MOCK"
          integration_uri    = "mock://test"
          integration_method = "POST"
          use_mock_response  = true
          mock_template      = "{\"message\": \"Recurso criado\"}"
          auth_type          = "API_KEY"
        }
      ]
    }
    quota_limit          = 1000
    quota_period         = "DAY"
    throttle_burst_limit = 10
    throttle_rate_limit  = 5
    tags = {
      Environment = "Production"
      Project     = "MyApp"
    }
  }

  module {
    source = "./"
  }

  command = plan

  assert {
    condition     = aws_api_gateway_rest_api.rest_api[0].name == "prod-myapp-api"
    error_message = "O nome da API deve ser 'prod-myapp-api'"
  }

  assert {
    condition     = aws_api_gateway_method.rest_endpoint_methods["0"].api_key_required == true
    error_message = "Deve requerer API Key"
  }

  assert {
    condition     = length(aws_api_gateway_usage_plan.rest_usage_plan) == 1
    error_message = "Deve criar um plano de uso"
  }

  assert {
    condition     = aws_api_gateway_usage_plan.rest_usage_plan[0].name == "prod-myapp-usage-plan"
    error_message = "O nome do plano de uso deve ser 'prod-myapp-usage-plan'"
  }

  assert {
    condition     = aws_api_gateway_usage_plan.rest_usage_plan[0].quota_settings[0].limit == 1000
    error_message = "O limite de quota deve ser 1000"
  }

  assert {
    condition     = aws_api_gateway_usage_plan.rest_usage_plan[0].throttle_settings[0].burst_limit == 10
    error_message = "O limite de burst deve ser 10"
  }

  assert {
    condition     = aws_api_gateway_usage_plan.rest_usage_plan[0].throttle_settings[0].rate_limit == 5
    error_message = "O limite de taxa deve ser 5"
  }

  assert {
    condition     = length(aws_api_gateway_api_key.rest_api_key) == 1
    error_message = "Deve criar uma API Key"
  }

  assert {
    condition     = aws_api_gateway_api_key.rest_api_key[0].name == "prod-myapp-api-key"
    error_message = "O nome da API Key deve ser 'prod-myapp-api-key'"
  }
}


run "teste_api_integracao_lambda" {
  plan_options {
    mode = normal
  }

  variables {
    TagEnv     = "stage"
    TagProject = "myapp"
    region     = "us-east-1"
    api_type   = "REST"
    stage_name = "v1"
    routes = {
      methods = [{
        path               = "processo"
        method             = "POST"
        status_code        = "200"
        authorization      = "NONE"
        api_key_required   = false
        request_parameters = {}
        integration_type   = "AWS_PROXY"
        integration_uri    = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:myfunction/invocations"
        integration_method = "POST"
        use_mock_response  = false
        mock_template      = ""
        auth_type          = "NONE"
      }]
    }
    tags = {
      Environment = "Staging"
      Project     = "MyApp"
    }
  }

  module {
    source = "./"
  }

  command = plan

  assert {
    condition     = aws_api_gateway_rest_api.rest_api[0].name == "stage-myapp-api"
    error_message = "O nome da API deve ser 'stage-myapp-api'"
  }

  assert {
    condition     = aws_api_gateway_integration.rest_endpoint_integrations["0"].type == "AWS_PROXY"
    error_message = "O tipo de integração deve ser 'AWS_PROXY'"
  }

  assert {
    condition     = aws_api_gateway_integration.rest_endpoint_integrations["0"].uri == "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:myfunction/invocations"
    error_message = "A URI de integração deve ser o ARN da função Lambda"
  }

  assert {
    condition     = aws_api_gateway_integration.rest_endpoint_integrations["0"].integration_http_method == "POST"
    error_message = "O método de integração deve ser 'POST'"
  }
}

run "teste_api_com_parametros_requisicao" {
  plan_options {
    mode = normal
  }

  variables {
    TagEnv     = "dev"
    TagProject = "myapp"
    region     = "us-east-1"
    api_type   = "REST"
    stage_name = "v1"
    routes = {
      methods = [
        {
          path             = "items/{itemId}"
          method           = "GET"
          status_code      = "200"
          authorization    = "NONE"
          api_key_required = false
          request_parameters = {
            "method.request.path.itemId"        = true
            "method.request.querystring.filter" = false
          }
          integration_type   = "MOCK"
          integration_uri    = "mock://test"
          integration_method = "GET"
          use_mock_response  = true
          mock_template      = "{\"item\": {\"id\": \"$input.params('itemId')\"}}"
          auth_type          = "NONE"
        }
      ]
    }
    tags = {
      Environment = "Development"
      Project     = "MyApp"
    }
  }

  module {
    source = "./"
  }

  command = plan

  assert {
    condition     = aws_api_gateway_method.rest_endpoint_methods["0"].request_parameters["method.request.path.itemId"] == true
    error_message = "O parâmetro de caminho 'itemId' deve ser obrigatório"
  }

  assert {
    condition     = aws_api_gateway_method.rest_endpoint_methods["0"].request_parameters["method.request.querystring.filter"] == false
    error_message = "O parâmetro de consulta 'filter' deve ser opcional"
  }
}

run "teste_tags_recursos" {
  plan_options {
    mode = normal
  }

  variables {
    TagEnv     = "qa"
    TagProject = "myapp"
    region     = "us-east-1"
    api_type   = "REST"
    stage_name = "v1"
    routes = {
      methods = [
        {
          path               = "health"
          method             = "GET"
          status_code        = "200"
          authorization      = "NONE"
          api_key_required   = false
          request_parameters = {}
          integration_type   = "MOCK"
          integration_uri    = "mock://test"
          integration_method = "GET"
          use_mock_response  = true
          mock_template      = "{\"status\": \"ok\"}"
          auth_type          = "NONE"
        }
      ]
    }
    tags = {
      Environment = "QA"
      Project     = "MyApp"
      CostCenter  = "CC123"
      Team        = "DevOps"
    }
  }

  module {
    source = "./"
  }

  command = plan

  assert {
    condition     = contains(keys(aws_api_gateway_rest_api.rest_api[0].tags), "Environment")
    error_message = "A tag 'Environment' deve estar presente na API"
  }

  assert {
    condition     = contains(keys(aws_api_gateway_rest_api.rest_api[0].tags), "Project")
    error_message = "A tag 'Project' deve estar presente na API"
  }

  assert {
    condition     = contains(keys(aws_api_gateway_rest_api.rest_api[0].tags), "CostCenter")
    error_message = "A tag 'CostCenter' deve estar presente na API"
  }

  assert {
    condition     = contains(keys(aws_api_gateway_rest_api.rest_api[0].tags), "Team")
    error_message = "A tag 'Team' deve estar presente na API"
  }

  assert {
    condition     = aws_api_gateway_rest_api.rest_api[0].tags["Name"] == "qa-myapp-api"
    error_message = "A tag 'Name' deve ser 'qa-myapp-api'"
  }

  assert {
    condition     = aws_api_gateway_rest_api.rest_api[0].tags["Environment"] == "qa"
    error_message = "A tag 'Environment' deve ser 'qa'"
  }

  assert {
    condition     = aws_api_gateway_rest_api.rest_api[0].tags["Project"] == "myapp"
    error_message = "A tag 'Project' deve ser 'myapp'"
  }
}

run "teste_http_api_basica" {
  plan_options {
    mode = normal
  }

  variables {
    TagEnv     = "dev"
    TagProject = "myapp"
    region     = "us-east-1"
    api_type   = "HTTP"
    stage_name = "v1"
    routes = {
      methods = [
        {
          path               = "users"
          method             = "GET"
          status_code        = "200"
          authorization      = "NONE"
          api_key_required   = false
          request_parameters = {}
          integration_type   = "AWS_PROXY"
          integration_uri    = "arn:aws:lambda:us-east-1:123456789012:function:myfunction"
          integration_method = "POST"
          use_mock_response  = false
          mock_template      = ""
          auth_type          = "NONE"
        }
      ]
    }
    tags = {
      Environment = "Development"
      Project     = "MyApp"
    }
  }

  module {
    source = "./"
  }

  command = plan

  assert {
    condition     = aws_apigatewayv2_api.http_api[0].name == "dev-myapp-http-api"
    error_message = "O nome da API HTTP deve ser 'dev-myapp-http-api'"
  }

  assert {
    condition     = aws_apigatewayv2_api.http_api[0].protocol_type == "HTTP"
    error_message = "O tipo de protocolo deve ser 'HTTP'"
  }

  assert {
    condition     = aws_apigatewayv2_route.http_route["0"].route_key == "GET /users"
    error_message = "A chave da rota deve ser 'GET /users'"
  }

  assert {
    condition     = aws_apigatewayv2_route.http_route["0"].authorization_type == "AWS_IAM"
    error_message = "O tipo de autorização deve ser 'AWS_IAM'"
  }

  assert {
    condition     = aws_apigatewayv2_stage.http_stage[0].name == "v1"
    error_message = "O nome do estágio deve ser 'v1'"
  }
}

run "teste_rest_api_com_cognito" {
  plan_options {
    mode = normal
  }

  variables {
    TagEnv                      = "prod"
    TagProject                  = "myapp"
    region                      = "us-east-1"
    api_type                    = "REST"
    cognito_user_pool_id        = "us-east-1_abcd1234"
    cognito_user_pool_client_id = "clientid12345"
    cognito_user_pool_arn       = "arn:aws:cognito-idp:us-east-1:123456789012:userpool/us-east-1_abcd1234"
    stage_name                  = "v1"
    routes = {
      methods = [{
        path               = "secure-endpoint"
        method             = "GET"
        status_code        = "200"
        authorization      = "COGNITO_USER_POOLS"
        api_key_required   = false
        request_parameters = {}
        integration_type   = "AWS_PROXY"
        integration_uri    = "arn:aws:lambda:us-east-1:123456789012:function:myfunction"
        integration_method = "POST"
        use_mock_response  = false
        mock_template      = ""
        auth_type          = "COGNITO"
      }]
    }
    tags = {
      Environment = "Production"
      Project     = "MyApp"
    }
  }

  module {
    source = "./"
  }

  command = plan

  assert {
    condition     = aws_api_gateway_authorizer.cognito_authorizer[0].name == "prod-myapp-cognito-authorizer"
    error_message = "O nome do autorizador Cognito deve ser 'prod-myapp-cognito-authorizer'"
  }

  assert {
    condition     = aws_api_gateway_authorizer.cognito_authorizer[0].type == "COGNITO_USER_POOLS"
    error_message = "O tipo de autorizador deve ser 'COGNITO_USER_POOLS'"
  }

  assert {
    condition     = aws_api_gateway_method.rest_endpoint_methods["0"].authorization == "COGNITO_USER_POOLS"
    error_message = "O tipo de autorização deve ser 'COGNITO_USER_POOLS'"
  }

}


run "teste_http_api_com_jwt" {
  plan_options {
    mode = normal
  }

  variables {
    TagEnv                      = "stage"
    TagProject                  = "myapp"
    region                      = "us-east-1"
    api_type                    = "HTTP"
    cognito_user_pool_id        = "us-east-1_wxyz5678"
    cognito_user_pool_client_id = "clientid67890"
    cognito_user_pool_issuer    = "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_wxyz5678"
    stage_name                  = "v1"
    routes = {
      methods = [{
        path               = "secure-jwt"
        method             = "POST"
        status_code        = "200"
        authorization      = "NONE"
        api_key_required   = false
        request_parameters = {}
        integration_type   = "AWS_PROXY"
        integration_uri    = "arn:aws:lambda:us-east-1:123456789012:function:myfunction"
        integration_method = "POST"
        use_mock_response  = false
        mock_template      = ""
        auth_type          = "JWT"
      }]
    }
    tags = {
      Environment = "Staging"
      Project     = "MyApp"
    }
  }

  module {
    source = "./"
  }

  command = plan

  assert {
    condition     = aws_apigatewayv2_api.http_api[0].name == "stage-myapp-http-api"
    error_message = "O nome da API HTTP deve ser 'stage-myapp-http-api'"
  }

  assert {
    condition     = aws_apigatewayv2_authorizer.jwt_authorizer[0].name == "stage-myapp-jwt-authorizer"
    error_message = "O nome do autorizador JWT deve ser 'stage-myapp-jwt-authorizer'"
  }

  assert {
    condition     = aws_apigatewayv2_authorizer.jwt_authorizer[0].authorizer_type == "JWT"
    error_message = "O tipo de autorizador deve ser 'JWT'"
  }

  assert {
    condition     = aws_apigatewayv2_route.http_route["0"].authorization_type == "JWT"
    error_message = "O tipo de autorização deve ser 'JWT'"
  }
}

run "teste_autorizacoes_mistas" {
  plan_options {
    mode = normal
  }

  variables {
    TagEnv                      = "mix"
    TagProject                  = "myapp"
    region                      = "us-east-1"
    api_type                    = "REST"
    cognito_user_pool_id        = "us-east-1_abcd1234"
    cognito_user_pool_client_id = "clientid12345"
    cognito_user_pool_arn       = "arn:aws:cognito-idp:us-east-1:123456789012:userpool/us-east-1_abcd1234"
    stage_name                  = "v1"
    routes = {
      main_path = "api"
      methods = [
        {
          path               = "public"
          method             = "GET"
          status_code        = "200"
          authorization      = "NONE"
          api_key_required   = false
          request_parameters = {}
          integration_type   = "MOCK"
          integration_uri    = "mock://test"
          integration_method = "GET"
          use_mock_response  = true
          mock_template      = "{\"message\": \"Público\"}"
          auth_type          = "NONE"
        },
        {
          path               = "key"
          method             = "GET"
          status_code        = "200"
          authorization      = "NONE"
          api_key_required   = true
          request_parameters = {}
          integration_type   = "MOCK"
          integration_uri    = "mock://test"
          integration_method = "GET"
          use_mock_response  = true
          mock_template      = "{\"message\": \"Com API Key\"}"
          auth_type          = "API_KEY"
        },
        {
          path               = "cognito"
          method             = "GET"
          status_code        = "200"
          authorization      = "COGNITO_USER_POOLS"
          api_key_required   = false
          request_parameters = {}
          integration_type   = "MOCK"
          integration_uri    = "mock://test"
          integration_method = "GET"
          use_mock_response  = true
          mock_template      = "{\"message\": \"Com Cognito\"}"
          auth_type          = "COGNITO"
        }
      ]
    }
    tags = {
      Environment = "Mixed"
      Project     = "MyApp"
    }
  }

  module {
    source = "./"
  }

  command = plan

  assert {
    condition     = aws_api_gateway_method.rest_endpoint_methods["0"].authorization == "NONE"
    error_message = "O endpoint public deve ter autorização 'NONE'"
  }

  assert {
    condition     = aws_api_gateway_method.rest_endpoint_methods["0"].api_key_required == false
    error_message = "O endpoint public não deve requerer API Key"
  }

  assert {
    condition     = aws_api_gateway_method.rest_endpoint_methods["1"].authorization == "NONE"
    error_message = "O endpoint key deve ter autorização 'NONE'"
  }

  assert {
    condition     = aws_api_gateway_method.rest_endpoint_methods["1"].api_key_required == true
    error_message = "O endpoint key deve requerer API Key"
  }

  assert {
    condition     = aws_api_gateway_method.rest_endpoint_methods["2"].authorization == "COGNITO_USER_POOLS"
    error_message = "O endpoint cognito deve ter autorização 'COGNITO_USER_POOLS'"
  }

  assert {
    condition     = length(aws_api_gateway_api_key.rest_api_key) == 1
    error_message = "Deve ser criada uma API Key"
  }

  assert {
    condition     = length(aws_api_gateway_authorizer.cognito_authorizer) == 1
    error_message = "Deve ser criado um autorizador Cognito"
  }
}

run "teste_http_api_e_rest_api_existentes" {
  plan_options {
    mode = normal
  }

  variables {
    TagEnv     = "multi"
    TagProject = "myapp"
    region     = "us-east-1"
    api_type   = "HTTP"
    stage_name = "v1"
    routes = {
      methods = [
        {
          path               = "multi-api"
          method             = "GET"
          status_code        = "200"
          authorization      = "NONE"
          api_key_required   = false
          request_parameters = {}
          integration_type   = "AWS_PROXY"
          integration_uri    = "arn:aws:lambda:us-east-1:123456789012:function:myfunction"
          integration_method = "POST"
          use_mock_response  = false
          mock_template      = ""
          auth_type          = "NONE"
        }
      ]
    }
    tags = {
      Environment = "Multi"
      Project     = "MyApp"
    }
  }

  module {
    source = "./"
  }

  command = plan

  assert {
    condition     = aws_apigatewayv2_api.http_api[0].name == "multi-myapp-http-api"
    error_message = "O nome da API HTTP deve ser 'multi-myapp-http-api'"
  }

  assert {
    condition     = length(aws_api_gateway_rest_api.rest_api) == 0
    error_message = "Não deve criar uma API REST quando api_type é 'HTTP'"
  }
}

run "teste_tipo_api_validacao" {
  plan_options {
    mode = normal
  }

  variables {
    TagEnv     = "dev"
    TagProject = "myapp"
    region     = "us-east-1"
    api_type   = "REST"
    stage_name = "v1"
    routes = {
      methods = [
        {
          path               = "validacao"
          method             = "GET"
          status_code        = "200"
          authorization      = "NONE"
          api_key_required   = false
          request_parameters = {}
          integration_type   = "MOCK"
          integration_uri    = "mock://test"
          integration_method = "GET"
          use_mock_response  = true
          mock_template      = "{\"status\": \"ok\"}"
          auth_type          = "NONE"
        }
      ]
    }
    tags = {
      Environment = "Development"
      Project     = "MyApp"
    }
  }

  module {
    source = "./"
  }

  command = plan

  assert {
    condition     = local.is_rest_api == true
    error_message = "A variável local is_rest_api deve ser true quando api_type é 'REST'"
  }

  assert {
    condition     = local.is_http_api == false
    error_message = "A variável local is_http_api deve ser false quando api_type é 'REST'"
  }
}

run "teste_multiplas_rotas_rest_api" {
  plan_options {
    mode = normal
  }

  variables {
    TagEnv     = "dev"
    TagProject = "myapp"
    region     = "us-east-1"
    api_type   = "REST"
    stage_name = "v1"
    routes = {
      main_path = "api"
      methods = [
        {
          path               = "users"
          method             = "GET"
          status_code        = "200"
          authorization      = "NONE"
          api_key_required   = false
          request_parameters = {}
          integration_type   = "MOCK"
          integration_uri    = "mock://test"
          integration_method = "GET"
          use_mock_response  = true
          mock_template      = "{\"message\": \"Lista de usuários\"}"
          auth_type          = "NONE"
        },
        {
          path               = "users"
          method             = "POST"
          status_code        = "201"
          authorization      = "NONE"
          api_key_required   = true
          request_parameters = {}
          integration_type   = "MOCK"
          integration_uri    = "mock://test"
          integration_method = "POST"
          use_mock_response  = true
          mock_template      = "{\"message\": \"Usuário criado\"}"
          auth_type          = "API_KEY"
        },
        {
          path               = "products"
          method             = "GET"
          status_code        = "200"
          authorization      = "NONE"
          api_key_required   = false
          request_parameters = {}
          integration_type   = "MOCK"
          integration_uri    = "mock://test"
          integration_method = "GET"
          use_mock_response  = true
          mock_template      = "{\"message\": \"Lista de produtos\"}"
          auth_type          = "NONE"
        }
      ]
    }
    tags = {
      Environment = "Development"
      Project     = "MyApp"
    }
  }

  module {
    source = "./"
  }

  command = plan

  assert {
    condition     = aws_api_gateway_rest_api.rest_api[0].name == "dev-myapp-api"
    error_message = "O nome da API deve ser 'dev-myapp-api'"
  }

  assert {
    condition     = aws_api_gateway_resource.main_resource[0].path_part == "api"
    error_message = "O recurso principal deve ser 'api'"
  }

  assert {
    condition     = aws_api_gateway_resource.base_resources["users"].path_part == "users"
    error_message = "O recurso base 'users' deve ser criado"
  }

  assert {
    condition     = aws_api_gateway_resource.base_resources["products"].path_part == "products"
    error_message = "O recurso base 'products' deve ser criado"
  }

  assert {
    condition     = aws_api_gateway_method.rest_endpoint_methods["0"].http_method == "GET"
    error_message = "O primeiro método HTTP deve ser 'GET'"
  }

  assert {
    condition     = aws_api_gateway_method.rest_endpoint_methods["1"].http_method == "POST"
    error_message = "O segundo método HTTP deve ser 'POST'"
  }

  assert {
    condition     = aws_api_gateway_method.rest_endpoint_methods["1"].api_key_required == true
    error_message = "O método POST deve requerer API Key"
  }

  assert {
    condition     = aws_api_gateway_method.rest_endpoint_methods["2"].http_method == "GET"
    error_message = "O terceiro método HTTP deve ser 'GET'"
  }
}

run "teste_caminhos_com_variaveis" {
  plan_options {
    mode = normal
  }

  variables {
    TagEnv     = "dev"
    TagProject = "myapp"
    region     = "us-east-1"
    api_type   = "REST"
    stage_name = "v1"
    routes = {
      methods = [
        {
          path               = "users"
          method             = "GET"
          status_code        = "200"
          authorization      = "NONE"
          api_key_required   = false
          request_parameters = {}
          integration_type   = "MOCK"
          integration_uri    = "mock://test"
          integration_method = "GET"
          use_mock_response  = true
          mock_template      = "{\"message\": \"Lista de usuários\"}"
          auth_type          = "NONE"
        },
        {
          path             = "users/{id}"
          method           = "GET"
          status_code      = "200"
          authorization    = "NONE"
          api_key_required = false
          request_parameters = {
            "method.request.path.id" = true
          }
          integration_type   = "MOCK"
          integration_uri    = "mock://test"
          integration_method = "GET"
          use_mock_response  = true
          mock_template      = "{\"message\": \"Usuário específico\"}"
          auth_type          = "NONE"
        }
      ]
    }
    tags = {
      Environment = "Development"
      Project     = "MyApp"
    }
  }

  module {
    source = "./"
  }

  command = plan

  assert {
    condition     = aws_api_gateway_resource.base_resources["users"].path_part == "users"
    error_message = "O recurso base 'users' deve ser criado"
  }

  assert {
    condition     = length(aws_api_gateway_resource.variable_resources) > 0
    error_message = "Deve ser criado recurso para variável de caminho"
  }

  assert {
    condition     = aws_api_gateway_resource.variable_resources["1"].path_part == "{id}"
    error_message = "O recurso de variável de caminho '{id}' deve ser criado"
  }

  assert {
    condition     = aws_api_gateway_method.rest_endpoint_methods["1"].request_parameters["method.request.path.id"] == true
    error_message = "O parâmetro de caminho 'id' deve ser obrigatório"
  }
}

run "teste_formatacao_correta_uri_lambda" {
  plan_options {
    mode = normal
  }

  variables {
    TagEnv     = "dev"
    TagProject = "myapp"
    region     = "us-east-1"
    api_type   = "REST"
    stage_name = "v1"
    routes = {
      methods = [
        {
          path               = "function"
          method             = "GET"
          status_code        = "200"
          authorization      = "NONE"
          api_key_required   = false
          request_parameters = {}
          integration_type   = "AWS_PROXY"
          integration_uri    = "arn:aws:lambda:us-east-1:123456789012:function:my-lambda-function"
          integration_method = "POST"
          use_mock_response  = false
          mock_template      = ""
          auth_type          = "NONE"
        }
      ]
    }
    tags = {
      Environment = "Development"
      Project     = "MyApp"
    }
  }

  module {
    source = "./"
  }

  command = plan

  assert {
    condition     = aws_api_gateway_integration.rest_endpoint_integrations["0"].uri == "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:my-lambda-function/invocations"
    error_message = "O URI de integração da Lambda deve estar formatado corretamente"
  }

  assert {
    condition     = aws_api_gateway_integration.rest_endpoint_integrations["0"].type == "AWS_PROXY"
    error_message = "O tipo de integração deve ser 'AWS_PROXY'"
  }

  assert {
    condition     = aws_api_gateway_integration.rest_endpoint_integrations["0"].integration_http_method == "POST"
    error_message = "O método de integração deve ser 'POST'"
  }
}

run "teste_http_api_com_multiplas_rotas" {
  plan_options {
    mode = normal
  }

  variables {
    TagEnv     = "dev"
    TagProject = "myapp"
    region     = "us-east-1"
    api_type   = "HTTP"
    stage_name = "v1"
    routes = {
      main_path = "api"
      methods = [
        {
          path               = "status"
          method             = "GET"
          status_code        = "200"
          authorization      = "NONE"
          api_key_required   = false
          request_parameters = {}
          integration_type   = "AWS_PROXY"
          integration_uri    = "arn:aws:lambda:us-east-1:123456789012:function:status-function"
          integration_method = "POST"
          use_mock_response  = false
          mock_template      = ""
          auth_type          = "NONE"
        },
        {
          path               = "auth"
          method             = "GET"
          status_code        = "200"
          authorization      = "JWT"
          api_key_required   = false
          request_parameters = {}
          integration_type   = "AWS_PROXY"
          integration_uri    = "arn:aws:lambda:us-east-1:123456789012:function:auth-function"
          integration_method = "POST"
          use_mock_response  = false
          mock_template      = ""
          auth_type          = "JWT"
        }
      ]
    }
    cognito_user_pool_id        = "us-east-1_abcd1234"
    cognito_user_pool_client_id = "clientid12345"
    cognito_user_pool_issuer    = "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_abcd1234"
    tags = {
      Environment = "Development"
      Project     = "MyApp"
    }
  }

  module {
    source = "./"
  }

  command = plan

  assert {
    condition     = aws_apigatewayv2_api.http_api[0].protocol_type == "HTTP"
    error_message = "O tipo de protocolo deve ser 'HTTP'"
  }

  assert {
    condition     = aws_apigatewayv2_route.http_route["0"].route_key == "GET /api/status"
    error_message = "A chave da rota deve ser 'GET /api/status'"
  }

  assert {
    condition     = aws_apigatewayv2_route.http_route["1"].route_key == "GET /api/auth"
    error_message = "A chave da rota deve ser 'GET /api/auth'"
  }

  assert {
    condition     = aws_apigatewayv2_route.http_route["0"].authorization_type == "AWS_IAM"
    error_message = "O tipo de autorização para status deve ser 'AWS_IAM'"
  }

  assert {
    condition     = aws_apigatewayv2_route.http_route["1"].authorization_type == "JWT"
    error_message = "O tipo de autorização para auth deve ser 'JWT'"
  }

}

run "teste_recursos_hierarquicos" {
  plan_options {
    mode = normal
  }

  variables {
    TagEnv     = "dev"
    TagProject = "myapp"
    region     = "us-east-1"
    api_type   = "REST"
    stage_name = "v1"
    routes = {
      main_path = "api"
      methods = [
        {
          path               = "users"
          method             = "GET"
          status_code        = "200"
          authorization      = "NONE"
          api_key_required   = false
          request_parameters = {}
          integration_type   = "MOCK"
          integration_uri    = "mock://test"
          integration_method = "GET"
          use_mock_response  = true
          mock_template      = "{\"message\": \"Lista de usuários\"}"
          auth_type          = "NONE"
        },
        {
          path             = "users/{id}"
          method           = "GET"
          status_code      = "200"
          authorization    = "NONE"
          api_key_required = false
          request_parameters = {
            "method.request.path.id" = true
          }
          integration_type   = "MOCK"
          integration_uri    = "mock://test"
          integration_method = "GET"
          use_mock_response  = true
          mock_template      = "{\"message\": \"Usuário específico\"}"
          auth_type          = "NONE"
        },
        {
          path             = "users/{id}/orders"
          method           = "GET"
          status_code      = "200"
          authorization    = "NONE"
          api_key_required = false
          request_parameters = {
            "method.request.path.id" = true
          }
          integration_type   = "MOCK"
          integration_uri    = "mock://test"
          integration_method = "GET"
          use_mock_response  = true
          mock_template      = "{\"message\": \"Pedidos do usuário\"}"
          auth_type          = "NONE"
        }
      ]
    }
    tags = {
      Environment = "Development"
      Project     = "MyApp"
    }
  }

  module {
    source = "./"
  }

  command = plan

  assert {
    condition     = aws_api_gateway_resource.main_resource[0].path_part == "api"
    error_message = "Deve ser criado o recurso principal 'api'"
  }

  assert {
    condition     = aws_api_gateway_resource.base_resources["users"].path_part == "users"
    error_message = "Deve ser criado o recurso base 'users'"
  }

  assert {
    condition     = aws_api_gateway_resource.variable_resources["1"].path_part == "{id}"
    error_message = "Deve ser criado o recurso para variável {id}"
  }
}
