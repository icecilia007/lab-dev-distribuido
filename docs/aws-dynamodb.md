# AWS dynamodb Module

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
| [aws_dynamodb_table.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_dynamodb_table_item.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table_item) | resource |
| [aws_iam_policy.lambda_dynamodb_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role_policy_attachment.lambda_dynamodb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_event_source_mapping.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping) | resource |
| [aws_iam_policy_document.lambda_dynamodb_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_lambda_function.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lambda_function) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_TagEnv"></a> [TagEnv](#input\_TagEnv) | n/a | `string` | n/a | yes |
| <a name="input_TagProject"></a> [TagProject](#input\_TagProject) | n/a | `string` | n/a | yes |
| <a name="input_enable_stream"></a> [enable\_stream](#input\_enable\_stream) | Nome do Projeto | `bool` | `false` | no |
| <a name="input_example_item"></a> [example\_item](#input\_example\_item) | Item de exemplo no formato do DynamoDB para ser inserido na tabela | `string` | `""` | no |
| <a name="input_hash_key"></a> [hash\_key](#input\_hash\_key) | Nome da chave de partição (hash key) | `string` | n/a | yes |
| <a name="input_lambda_function_names"></a> [lambda\_function\_names](#input\_lambda\_function\_names) | Nome da função Lambda que será disparada pelo stream | `list(string)` | `[]` | no |
| <a name="input_sort_key"></a> [sort\_key](#input\_sort\_key) | Nome da chave de ordenação (sort key). Se vazio, a tabela terá apenas a hash key | `string` | `""` | no |
| <a name="input_sort_key_type"></a> [sort\_key\_type](#input\_sort\_key\_type) | Tipo da chave de ordenação (S, N, B) | `string` | `"S"` | no |
| <a name="input_stream_view_type"></a> [stream\_view\_type](#input\_stream\_view\_type) | Tipo de visualização do stream (NEW\_IMAGE, OLD\_IMAGE, NEW\_AND\_OLD\_IMAGES, KEYS\_ONLY) | `string` | `"NEW_AND_OLD_IMAGES"` | no |
| <a name="input_table_name"></a> [table\_name](#input\_table\_name) | Nome da tabela DynamoDB | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags comuns para os recursos | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | ARN da tabela DynamoDB |
| <a name="output_hash_key"></a> [hash\_key](#output\_hash\_key) | hash\_key da tabela DynamoDB |
| <a name="output_id"></a> [id](#output\_id) | ID da tabela DynamoDB |
| <a name="output_name"></a> [name](#output\_name) | Nome da tabela DynamoDB |
| <a name="output_range_key"></a> [range\_key](#output\_range\_key) | range\_key (sort key) da tabela DynamoDB |
