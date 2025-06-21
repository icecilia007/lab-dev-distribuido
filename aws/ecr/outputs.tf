# -*- coding: utf-8 -*-
# File name infra/modules/ecr/outputs.tf

output "repository_url" {
  description = "A URL do repositório ECR"
  value       = aws_ecr_repository.this.repository_url
}

output "name" {
  description = "O nome do repositório ECR"
  value       = aws_ecr_repository.this.name
}

output "arn" {
  description = "O ARN do repositório ECR"
  value       = aws_ecr_repository.this.arn
}
