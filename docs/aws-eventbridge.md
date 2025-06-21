# AWS eventbridge Module

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.policy_scheduler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.schedule_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.scheduler_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_scheduler_schedule.schedule_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/scheduler_schedule) | resource |
| [aws_scheduler_schedule_group.schedule_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/scheduler_schedule_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_TagEnv"></a> [TagEnv](#input\_TagEnv) | n/a | `string` | n/a | yes |
| <a name="input_TagProject"></a> [TagProject](#input\_TagProject) | n/a | `string` | n/a | yes |
| <a name="input_TimeZone"></a> [TimeZone](#input\_TimeZone) | Fuso horário para o cron | `string` | `"UTC"` | no |
| <a name="input_cron"></a> [cron](#input\_cron) | ARN do destino (Lambda, SNS, SQS, etc.) que será invocado | `string` | n/a | yes |
| <a name="input_lambda_function_arn"></a> [lambda\_function\_arn](#input\_lambda\_function\_arn) | ARN da função Lambda a ser invocada pelo agendamento | `string` | n/a | yes |
| <a name="input_scheduler_name"></a> [scheduler\_name](#input\_scheduler\_name) | n/a | `string` | n/a | yes |
| <a name="input_state"></a> [state](#input\_state) | Define se o agendamento está ativo (ENABLED) ou desativado (DISABLED) | `string` | `"DISABLED"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags comuns para os recursos | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | ARN da role do Scheduler |
| <a name="output_group_name"></a> [group\_name](#output\_group\_name) | Nome do grupo de agendamento |
