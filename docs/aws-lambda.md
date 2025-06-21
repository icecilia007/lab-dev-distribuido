# AWS lambda Module

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | >= 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | >= 2.0.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.lambda_sns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.lambda_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.lambda_custom_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.lambda_exec_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.lambda_logs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.sns_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.lambda_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function_event_invoke_config.lambda_invoke_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function_event_invoke_config) | resource |
| [aws_lambda_layer_version.custom_layer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_layer_version) | resource |
| [aws_s3_object.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [archive_file.lambda_package](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_iam_policy_document.assume_role_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_TagEnv"></a> [TagEnv](#input\_TagEnv) | n/a | `string` | n/a | yes |
| <a name="input_TagProject"></a> [TagProject](#input\_TagProject) | n/a | `string` | n/a | yes |
| <a name="input_additional_policies"></a> [additional\_policies](#input\_additional\_policies) | Lista de ARNs de políticas adicionais para anexar à role da Lambda | `list(string)` | `[]` | no |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | Variáveis de ambiente para a função Lambda | `map(string)` | `{}` | no |
| <a name="input_function_name"></a> [function\_name](#input\_function\_name) | Nome da função Lambda | `string` | n/a | yes |
| <a name="input_handler"></a> [handler](#input\_handler) | Handler da função Lambda (ex: file\_name.function\_name) | `string` | n/a | yes |
| <a name="input_lambda_layers"></a> [lambda\_layers](#input\_lambda\_layers) | Lista de ARNs de layers | `list(string)` | `[]` | no |
| <a name="input_layer_name"></a> [layer\_name](#input\_layer\_name) | layer name | `string` | `""` | no |
| <a name="input_max_event_age_in_seconds"></a> [max\_event\_age\_in\_seconds](#input\_max\_event\_age\_in\_seconds) | Tempo máximo em segundos para eventos Lambda | `number` | `21600` | no |
| <a name="input_max_retry_attempts"></a> [max\_retry\_attempts](#input\_max\_retry\_attempts) | Número máximo de tentativas de re-execução para eventos | `number` | `0` | no |
| <a name="input_memory_size"></a> [memory\_size](#input\_memory\_size) | Tamanho da memória da Lambda em MB | `number` | `128` | no |
| <a name="input_runtime"></a> [runtime](#input\_runtime) | Runtime da Lambda (ex: python3.10) | `string` | `"python3.10"` | no |
| <a name="input_s3_art"></a> [s3\_art](#input\_s3\_art) | bucket art | `string` | `""` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | Lista de Security Group IDs para a Lambda (quando VPC estiver habilitada). | `list(string)` | `[]` | no |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | n/a | `string` | n/a | yes |
| <a name="input_source_file"></a> [source\_file](#input\_source\_file) | Arquivo fonte da Lambda (caminho para o código Python) | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Lista de Subnet IDs para a Lambda (quando VPC estiver habilitada). | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | n/a | yes |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | Timeout da função Lambda em segundos | `number` | `900` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | ARN da função Lambda criada |
| <a name="output_name"></a> [name](#output\_name) | Nome da função Lambda criada |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | Role usada na lambda |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | Role usada na lambda |
