# -*- coding: utf-8 -*-
# File name infra/modules/iam/main.tf
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.TagEnv}-${var.TagProject}-${var.role_name}-role"
  assume_role_policy = var.assume_role_policy

  tags = var.tags
}


resource "aws_iam_policy" "this" {
  count       = var.policy_document != "" ? 1 : 0
  name        = "${var.TagEnv}-${var.TagProject}-${var.policy_name}-policy"
  description = var.policy_description
  policy      = var.policy_document
}


resource "aws_iam_role_policy_attachment" "this" {
  count      = length(var.attach_policies) > 0 ? length(var.attach_policies) : 0
  role       = aws_iam_role.this.name
  policy_arn = element(var.attach_policies, count.index)
}
