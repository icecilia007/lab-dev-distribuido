# -*- coding: utf-8 -*-
# File name infra/modules/lambda_image/variables.tf

variable "TagProject" {
  type = string
}

variable "TagEnv" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "folder" {
  type = string
}

variable "files" {
  type = list(string)
}

variable "aws_region" {
  type = string
}

variable "tag_image" {
  type    = string
  default = "latest"
}

variable "lambda_name" {
  type = string
}

variable "memory" {
  type    = number
  default = 128
}

variable "timeout" {
  type    = number
  default = 900
}

variable "maximum_event_age_in_seconds" {
  type    = number
  default = 21600
}

variable "maximum_retry_attempts" {
  type    = number
  default = 0
}

variable "additional_policies" {
  type    = list(string)
  default = []
}

variable "environment_variables" {
  description = "Variáveis de ambiente para a função Lambda"
  type        = map(string)
  default     = {}
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
