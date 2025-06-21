# -*- coding: utf-8 -*-
# File name infra/modules/sns/main.tf

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

resource "aws_sns_topic" "this" {
  name         = "${var.TagEnv}_${var.TagProject}_${var.Name}"
  display_name = "${var.TagEnv}_${var.TagProject}_${var.Name}_error"
  tags         = var.tags
}

resource "aws_sns_topic_subscription" "email_subscriptions" {
  for_each  = toset(var.emails_sns)
  topic_arn = aws_sns_topic.this.arn
  protocol  = "email"
  endpoint  = each.value
}
