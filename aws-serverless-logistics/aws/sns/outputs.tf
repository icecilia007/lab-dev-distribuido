# -*- coding: utf-8 -*-
# Outputs para SNS/SQS Event System

output "sns_topic_arn" {
  description = "ARN do SNS Topic logistica.exchange"
  value       = aws_sns_topic.logistics_exchange.arn
}

output "sns_topic_name" {
  description = "Nome do SNS Topic"
  value       = aws_sns_topic.logistics_exchange.name
}

output "sqs_notificacoes_arn" {
  description = "ARN da SQS Queue notificacoes.geral"
  value       = aws_sqs_queue.notificacoes_geral.arn
}

output "sqs_notificacoes_url" {
  description = "URL da SQS Queue notificacoes.geral"
  value       = aws_sqs_queue.notificacoes_geral.url
}

output "sqs_notificacoes_name" {
  description = "Nome da SQS Queue notificacoes.geral"
  value       = aws_sqs_queue.notificacoes_geral.name
}

output "sns_publisher_role_arn" {
  description = "ARN da IAM Role para publicar no SNS"
  value       = aws_iam_role.sns_publisher_role.arn
}
