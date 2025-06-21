# -*- coding: utf-8 -*-
# File name infra/modules/dynamodb/outputs.tf

output "id" {
  description = "ID da tabela DynamoDB"
  value       = aws_dynamodb_table.this.id
}

output "arn" {
  description = "ARN da tabela DynamoDB"
  value       = aws_dynamodb_table.this.arn
}

output "name" {
  description = "Nome da tabela DynamoDB"
  value       = aws_dynamodb_table.this.name
}

output "hash_key" {
  description = "hash_key da tabela DynamoDB"
  value       = aws_dynamodb_table.this.hash_key
}

output "range_key" {
  description = "range_key (sort key) da tabela DynamoDB"
  value       = var.sort_key != "" ? var.sort_key : null
}
