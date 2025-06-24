output "sqs_queue_url" {
  description = "URL da fila SQS para notificações de email"
  value       = aws_sqs_queue.email_notifications.url
}

output "sqs_queue_arn" {
  description = "ARN da fila SQS para notificações de email"
  value       = aws_sqs_queue.email_notifications.arn
}

output "lambda_function_arn" {
  description = "ARN da função Lambda processadora de emails"
  value       = aws_lambda_function.email_processor.arn
}

output "ses_email_identity_arn" {
  description = "ARN da identidade de email SES"
  value       = aws_ses_email_identity.sender_email.arn
}

output "sender_email" {
  description = "Email remetente configurado"
  value       = aws_ses_email_identity.sender_email.email
}

output "cupons_api_url" {
  description = "URL base da API de cupons"
  value       = "${aws_api_gateway_rest_api.cupons_api.execution_arn}/prod"
}

output "cupons_api_endpoints" {
  description = "Endpoints da API de cupons"
  value = {
    listar_cupons = "GET ${aws_api_gateway_deployment.cupons_api_deployment.invoke_url}/cupons"
    buscar_cupom  = "GET ${aws_api_gateway_deployment.cupons_api_deployment.invoke_url}/cupons/{id}"
  }
}

output "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB de cupons"
  value       = aws_dynamodb_table.cupons.name
}

output "campanhas_api_endpoint" {
  description = "Endpoint para trigger de campanhas promocionais"
  value       = "POST ${aws_api_gateway_deployment.cupons_api_deployment.invoke_url}/campanhas/trigger"
}

output "sns_topics" {
  description = "Tópicos SNS para segmentação de clientes"
  value = {
    premium     = aws_sns_topic.clientes_premium.arn
    regiao_sul  = aws_sns_topic.clientes_regiao_sul.arn
    geral       = aws_sns_topic.clientes_geral.arn
  }
}

output "campanhas_metricas_table" {
  description = "Tabela DynamoDB para métricas de campanhas"
  value       = aws_dynamodb_table.campanhas_metricas.name
}

# Geração automática da collection do Postman
resource "local_file" "postman_collection" {
  filename = "${path.module}/cupons-api-postman-collection.json"
  content = templatefile("${path.module}/postman-collection.tpl", {
    api_base_url    = aws_api_gateway_deployment.cupons_api_deployment.invoke_url
    api_gateway_id  = aws_api_gateway_rest_api.cupons_api.id
    aws_region      = var.aws_region
    stage          = "prod"
  })
  
  depends_on = [
    aws_api_gateway_deployment.cupons_api_deployment
  ]
}

output "postman_collection_path" {
  description = "Caminho do arquivo da collection do Postman gerada automaticamente"
  value       = local_file.postman_collection.filename
}

# Outputs para gerenciamento de emails
output "setup_script_path" {
  description = "Caminho do script de configuração de emails"
  value       = "${path.module}/setup_emails.sh"
}

output "csv_template_path" {
  description = "Caminho do template CSV para emails"
  value       = "${path.module}/emails_teste.csv"
}

output "email_setup_instructions" {
  description = "Instruções para configurar emails no SES"
  value = <<-EOT
    Para configurar emails de teste:
    
    1. Editar arquivo CSV: ${path.module}/emails_teste.csv
    2. Verificar emails: ./setup_emails.sh emails_teste.csv --verify-only
    3. Atualizar sistema: ./setup_emails.sh emails_teste.csv --terraform-update
    4. Enviar teste: ./setup_emails.sh emails_teste.csv --send-test
    
    Consulte README_EMAILS.md para mais detalhes.
  EOT
}