# -*- coding: utf-8 -*-
# Variables para SNS/SQS Event System (compatível com RabbitMQ Java)

variable "prefix" {
  description = "Prefixo para recursos AWS"
  type        = string
}

variable "tags" {
  description = "Tags padrão para recursos"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Ambiente (dev, prod, etc.)"
  type        = string
  default     = "dev"
}
