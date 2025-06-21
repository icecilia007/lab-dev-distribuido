# AWS sqs Module

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
| [aws_sqs_queue.dead_letter_fifo_queue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue.fifo_queue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_TagEnv"></a> [TagEnv](#input\_TagEnv) | n/a | `string` | n/a | yes |
| <a name="input_TagProject"></a> [TagProject](#input\_TagProject) | n/a | `string` | n/a | yes |
| <a name="input_sqs_name"></a> [sqs\_name](#input\_sqs\_name) | Nome da fila sqs | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | ARN |
| <a name="output_dead_letter_arn"></a> [dead\_letter\_arn](#output\_dead\_letter\_arn) | ARN |
| <a name="output_dead_letter_url"></a> [dead\_letter\_url](#output\_dead\_letter\_url) | n/a |
| <a name="output_url"></a> [url](#output\_url) | n/a |
