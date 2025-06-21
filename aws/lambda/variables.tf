# -*- coding: utf-8 -*-
# File name infra/modules/lambda/variables.tf

variable "TagProject" {
  type = string
}

variable "TagEnv" {
  type = string
}

variable "tags" {
  type = map(string)
}

# Variables
variable "function_name" {
  description = "Nome da função Lambda"
  type        = string
}

variable "source_file" {
  description = "Arquivo fonte da Lambda (caminho para o código Python)"
  type        = string
}

variable "handler" {
  description = "Handler da função Lambda (ex: file_name.function_name)"
  type        = string
}

variable "runtime" {
  description = "Runtime da Lambda (ex: python3.10)"
  type        = string
  default     = "python3.10"
}

variable "timeout" {
  description = "Timeout da função Lambda em segundos"
  type        = number
  default     = 900
}

variable "memory_size" {
  description = "Tamanho da memória da Lambda em MB"
  type        = number
  default     = 128
}

variable "environment_variables" {
  description = "Variáveis de ambiente para a função Lambda"
  type        = map(string)
  default     = {}
}

variable "max_event_age_in_seconds" {
  description = "Tempo máximo em segundos para eventos Lambda"
  type        = number
  default     = 21600
}

variable "max_retry_attempts" {
  description = "Número máximo de tentativas de re-execução para eventos"
  type        = number
  default     = 0
}

variable "additional_policies" {
  description = "Lista de ARNs de políticas adicionais para anexar à role da Lambda"
  type        = list(string)
  default     = []
}


variable "s3_art" {
  description = "bucket art"
  type        = string
  default     = ""
}

variable "layer_name" {
  description = "layer name"
  type        = string
  default     = ""
}

variable "lambda_layers" {
  description = "Lista de ARNs de layers"
  type        = list(string)
  default     = []
}

variable "sns_topic_arn" {
  type = string
}

variable "subnet_ids" {
  type        = list(string)
  default     = []
  description = "Lista de Subnet IDs para a Lambda (quando VPC estiver habilitada)."
}

variable "security_group_ids" {
  type        = list(string)
  default     = []
  description = "Lista de Security Group IDs para a Lambda (quando VPC estiver habilitada)."
}

variable "reserved_concurrent_executions" {
  type    = number
  default = -1
}

variable "description" {
  type = string
}
