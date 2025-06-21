# -*- coding: utf-8 -*-
# File name infra/modules/sqs/main.tf

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

resource "aws_sqs_queue" "fifo_queue" {
  name                        = "${var.TagEnv}-${var.TagProject}-${var.sqs_name}-fifo-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  tags                        = var.tags
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_fifo_queue.arn
    maxReceiveCount     = 5
  })
  visibility_timeout_seconds = (60 * 60 * 12)

}


# Recurso de fila SQS dead letter
resource "aws_sqs_queue" "dead_letter_fifo_queue" {
  name                        = "${var.TagEnv}-${var.TagProject}-${var.sqs_name}-dead-letter-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  tags                        = var.tags
  visibility_timeout_seconds  = (60 * 60 * 12)
}
