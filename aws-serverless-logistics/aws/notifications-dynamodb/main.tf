# -*- coding: utf-8 -*-
# Módulo específico para tabelas de notificações

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

# Tabela de Notificações - replica modelo Java
resource "aws_dynamodb_table" "notificacoes" {
  name         = "${var.TagEnv}-${var.TagProject}-notificacoes"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "destinatarioId"
    type = "N"
  }

  attribute {
    name = "tipoEvento"
    type = "S"
  }

  attribute {
    name = "dataCriacao"
    type = "S"
  }

  # GSI para buscar notificações por usuário
  global_secondary_index {
    name     = "destinatario-index"
    hash_key = "destinatarioId"
    range_key = "dataCriacao"
    projection_type = "ALL"
  }

  # GSI para buscar por tipo de evento
  global_secondary_index {
    name     = "tipo-evento-index"
    hash_key = "tipoEvento"
    projection_type = "ALL"
  }

  # TTL para limpeza automática
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = var.tags
}

# Tabela de Preferências de Notificação - replica modelo Java
resource "aws_dynamodb_table" "preferencias_notificacao" {
  name         = "${var.TagEnv}-${var.TagProject}-preferencias-notificacao"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"

  attribute {
    name = "userId"
    type = "N"
  }

  tags = var.tags
}