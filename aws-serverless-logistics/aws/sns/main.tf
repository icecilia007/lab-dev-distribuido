# -*- coding: utf-8 -*-
# SNS Topic Exchange para substituir RabbitMQ (compatível com sistema Java)

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

# SNS Topic principal - substitui "logistica.exchange" do RabbitMQ
resource "aws_sns_topic" "logistics_exchange" {
  name = "${var.prefix}-logistics-exchange"
  
  # Configurações para delivery reliability
  delivery_policy = jsonencode({
    "http" = {
      "defaultHealthyRetryPolicy" = {
        "minDelayTarget"     = 1
        "maxDelayTarget"     = 5
        "numRetries"         = 3
        "numMaxDelayRetries" = 0
        "numMinDelayRetries" = 0
        "numNoDelayRetries"  = 0
        "backoffFunction"    = "linear"
      }
      "disableSubscriptionOverrides" = false
    }
  })
  
  tags = var.tags
}

# SQS Queue principal para notificações - substitui "notificacoes.geral" 
resource "aws_sqs_queue" "notificacoes_geral" {
  name = "${var.prefix}-notificacoes-geral"
  
  # Configurações de reliability (compatível com Java RabbitMQ)
  visibility_timeout_seconds = 300
  message_retention_seconds  = 1209600  # 14 dias
  
  # Dead Letter Queue
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notificacoes_dlq.arn
    maxReceiveCount     = 3
  })
  
  tags = var.tags
}

# Dead Letter Queue para mensagens com falha
resource "aws_sqs_queue" "notificacoes_dlq" {
  name = "${var.prefix}-notificacoes-dlq"
  message_retention_seconds = 1209600  # 14 dias
  
  tags = merge(var.tags, {
    Purpose = "Dead Letter Queue"
  })
}

# Subscription: SNS -> SQS notificacoes.geral 
# Equivale ao binding com routing key "#" do RabbitMQ (todos os eventos)
resource "aws_sns_topic_subscription" "notificacoes_geral" {
  topic_arn = aws_sns_topic.logistics_exchange.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.notificacoes_geral.arn
  
  # Filter policy - aceita todos os eventos (equivale ao "#" do RabbitMQ)
  filter_policy = jsonencode({
    "evento" : ["PEDIDO_CRIADO", "STATUS_ATUALIZADO", "PEDIDO_DISPONIVEL", 
               "PEDIDO_CANCELADO", "ALERTA_INCIDENTE", "STATUS_VEICULO_ALTERADO"]
  })
}

# IAM Policy para SNS publicar na SQS
resource "aws_sqs_queue_policy" "notificacoes_geral_policy" {
  queue_url = aws_sqs_queue.notificacoes_geral.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "sqspolicy"
    Statement = [
      {
        Sid    = "AllowSNSPublish"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.notificacoes_geral.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.logistics_exchange.arn
          }
        }
      }
    ]
  })
}

# IAM Role para Lambdas publicarem no SNS (substitui RabbitTemplate)
resource "aws_iam_role" "sns_publisher_role" {
  name = "${var.prefix}-sns-publisher-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "sns_publisher_policy" {
  name = "${var.prefix}-sns-publisher-policy"
  role = aws_iam_role.sns_publisher_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.logistics_exchange.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}
