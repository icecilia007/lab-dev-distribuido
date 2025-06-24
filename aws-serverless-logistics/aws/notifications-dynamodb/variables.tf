# -*- coding: utf-8 -*-
# Variables para tabelas de notificações

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
  description = "Tags adicionais para os recursos"
  default     = {}
}