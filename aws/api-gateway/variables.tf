variable "TagProject" {
  type        = string
  description = "Nome do projeto"
}

variable "TagEnv" {
  type        = string
  description = "Ambiente (dev, staging, prod)"
}

variable "tags" {
  type        = map(string)
  description = "Tags adicionais para o recurso"
}

variable "region" {
  type        = string
  description = "Região da AWS onde os recursos serão criados"
}

variable "stage_name" {
  type        = string
  description = "Nome do estágio da API Gateway"
  default     = "v1"
}

variable "api_type" {
  type        = string
  description = "Tipo de API Gateway: 'REST' ou 'HTTP'"
  default     = "REST"
  validation {
    condition     = contains(["REST", "HTTP"], var.api_type)
    error_message = "O tipo de API deve ser 'REST' ou 'HTTP'."
  }
}

variable "routes" {
  description = <<-EOT
    Configuração de múltiplas rotas para a API.

    main_path: (string)
      Caminho principal da API (opcional para API REST, será o prefixo de todos os paths)
      Exemplo: "api", "v1", "secure-data"

    methods: (list)
      Lista de métodos/endpoints da API, cada um contendo:

      path: (string)
        Caminho do endpoint na API. Pode incluir parâmetros de caminho entre chaves.
        Exemplos: "produtos", "produtos/{id}", "clientes/{clienteId}/pedidos"

      method: (string)
        Método HTTP para o endpoint.
        Valores válidos: GET, POST, PUT, DELETE, PATCH, OPTIONS, HEAD

      api_key_required: (bool)
        Define se o endpoint requer autenticação via API Key.
        true = API Key obrigatória, false = acesso público

      status_code: (string)
        Código de status HTTP padrão para respostas bem-sucedidas.
        Exemplos: "200", "201", "204"

      request_parameters: (map(bool))
        Mapa de parâmetros de requisição e se são obrigatórios.
        Exemplo: { "method.request.path.id" = true } torna o parâmetro 'id' obrigatório

      integration_type: (string)
        Tipo de integração do API Gateway com o backend.
        Valores possíveis:
          - MOCK: Resposta simulada sem backend real
          - AWS_PROXY: Integração Lambda Proxy (recomendado para Lambda)
          - AWS: Integração Lambda não-proxy (permite transformação)
          - HTTP_PROXY: Proxy direto para HTTP/HTTPS
          - HTTP: Integração HTTP não-proxy (permite transformação)

      integration_uri: (string)
        URI para o serviço de backend.
        Para Lambda: ARN da função (arn:aws:lambda:region:account:function:name)
        Para HTTP: URL completa (https://api.exemplo.com/recurso)

      integration_method: (string)
        Método HTTP usado pelo API Gateway para se comunicar com o backend.
        Para Lambda (AWS_PROXY): Sempre "POST"
        Para HTTP: Qualquer método válido (GET, POST, etc.)

      use_mock_response: (bool)
        Define se deve usar um template de resposta mock.
        true = usar template, false = passar resposta do backend diretamente

      mock_template: (string)
        Template de resposta em formato JSON ou VTL (Velocity Template Language).
        Usado quando integration_type é "MOCK" ou use_mock_response é true.

      auth_type: (string)
        Tipo de autorização.
        Valores válidos: "NONE", "API_KEY", "COGNITO", "JWT"
  EOT

  type = object({
    main_path = optional(string, "")
    methods = list(object({
      path               = string
      method             = string
      api_key_required   = bool
      status_code        = string
      request_parameters = map(bool)
      authorization      = string
      integration_type   = string
      integration_uri    = string
      integration_method = string
      use_mock_response  = bool
      mock_template      = string
      auth_type          = string
    }))
  })

  validation {
    condition = alltrue([
      for method in var.routes.methods :
      contains(["NONE", "API_KEY", "COGNITO", "JWT"], method.auth_type)
    ])
    error_message = "O tipo de autenticação deve ser 'NONE', 'API_KEY', 'COGNITO' ou 'JWT'."
  }
}

variable "quota_limit" {
  type        = number
  description = "Limite do plano de quota"
  default     = null
}

variable "quota_period" {
  type        = string
  description = "Período para o limite de quota (DAY, WEEK, MONTH)"
  default     = null
}

variable "throttle_burst_limit" {
  type        = number
  description = "Limite de burst de throttling"
  default     = null
}

variable "throttle_rate_limit" {
  type        = number
  description = "Taxa de limite de throttling"
  default     = null
}

variable "cognito_user_pool_id" {
  type        = string
  description = "ID do User Pool do Cognito para autenticação"
  default     = null
}

variable "cognito_user_pool_client_id" {
  type        = string
  description = "ID do Client do User Pool do Cognito"
  default     = null
}

variable "cognito_user_pool_arn" {
  type        = string
  description = "ARN completo do User Pool do Cognito, se disponível"
  default     = null
}

variable "cognito_user_pool_issuer" {
  type        = string
  description = "URL do emissor do Cognito User Pool para autenticação JWT"
  default     = null
}
