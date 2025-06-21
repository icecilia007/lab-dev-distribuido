# -*- coding: utf-8 -*-
# File name infra/modules/iam/outputs.tf

output "role_arn" {
  value = aws_iam_role.this.arn
}

output "policy_arn" {
  value = length(aws_iam_policy.this) > 0 ? aws_iam_policy.this[0].arn : null
}
