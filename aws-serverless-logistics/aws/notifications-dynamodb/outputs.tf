# -*- coding: utf-8 -*-
# Outputs das tabelas de notificações

output "notificacoes_table_name" {
  description = "Nome da tabela de notificações"
  value       = aws_dynamodb_table.notificacoes.name
}

output "notificacoes_table_arn" {
  description = "ARN da tabela de notificações"
  value       = aws_dynamodb_table.notificacoes.arn
}

output "preferencias_table_name" {
  description = "Nome da tabela de preferências"
  value       = aws_dynamodb_table.preferencias_notificacao.name
}

output "preferencias_table_arn" {
  description = "ARN da tabela de preferências"
  value       = aws_dynamodb_table.preferencias_notificacao.arn
}