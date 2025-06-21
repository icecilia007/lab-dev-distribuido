# -*- coding: utf-8 -*-
# File name infra/modules/sns/outputs.tf

output "arn" {
  value = aws_sns_topic.this.arn
}


output "name" {
  value = aws_sns_topic.this.name
}
