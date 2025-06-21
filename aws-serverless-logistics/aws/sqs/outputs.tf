# -*- coding: utf-8 -*-
# File name infra/modules/sqs/outputs.tf

output "arn" {
  description = "ARN"
  value       = aws_sqs_queue.fifo_queue.arn
}

output "dead_letter_arn" {
  description = "ARN"
  value       = aws_sqs_queue.fifo_queue.arn
}

output "url" {
  value = aws_sqs_queue.fifo_queue.url
}

output "dead_letter_url" {
  value = aws_sqs_queue.dead_letter_fifo_queue.url
}
