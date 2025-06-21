# -*- coding: utf-8 -*-
# File name infra/modules/lambda_image/outputs.tf

output "arn" {
  value = aws_lambda_function.lambda.arn
}


output "name" {
  value = aws_lambda_function.lambda.function_name
}

output "role_arn" {
  description = "Role usada na lambda"
  value       = aws_iam_role.lambda_role.arn
}

output "role_name" {
  description = "Role usada na lambda"
  value       = aws_iam_role.lambda_role.name
}
