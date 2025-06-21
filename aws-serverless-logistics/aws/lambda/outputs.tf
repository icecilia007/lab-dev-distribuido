# -*- coding: utf-8 -*-
# File name infra/modules/lambda/outputs.tf

output "arn" {
  description = "ARN da função Lambda criada"
  value       = aws_lambda_function.lambda_function.arn
}

output "name" {
  description = "Nome da função Lambda criada"
  value       = aws_lambda_function.lambda_function.function_name
}

output "role_arn" {
  description = "Role usada na lambda"
  value       = aws_iam_role.lambda_role.arn
}

output "role_name" {
  description = "Role usada na lambda"
  value       = aws_iam_role.lambda_role.name
}
