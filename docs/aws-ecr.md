# AWS ecr Module

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0.0 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ecr_lifecycle_policy.delete](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [null_resource.run_script](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_TagEnv"></a> [TagEnv](#input\_TagEnv) | n/a | `string` | n/a | yes |
| <a name="input_TagProject"></a> [TagProject](#input\_TagProject) | n/a | `string` | n/a | yes |
| <a name="input_days_lifecycle_policy"></a> [days\_lifecycle\_policy](#input\_days\_lifecycle\_policy) | Número de imagens a reter no ciclo de vida | `number` | `5` | no |
| <a name="input_files"></a> [files](#input\_files) | Lista de arquivos a serem monitorados para trigger do build | `list(string)` | `[]` | no |
| <a name="input_folder"></a> [folder](#input\_folder) | Pasta onde estão os arquivos para build da imagem | `string` | `""` | no |
| <a name="input_image_tag_mutability"></a> [image\_tag\_mutability](#input\_image\_tag\_mutability) | Mutabilidade da tag da imagem no ECR | `string` | `"MUTABLE"` | no |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | n/a | yes |
| <a name="input_repository_name"></a> [repository\_name](#input\_repository\_name) | Nome do repositório ECR | `string` | n/a | yes |
| <a name="input_scan_on_push"></a> [scan\_on\_push](#input\_scan\_on\_push) | Ativa o scan da imagem no push | `bool` | `true` | no |
| <a name="input_tag_image"></a> [tag\_image](#input\_tag\_image) | Tag da imagem Docker | `string` | `"latest"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | O ARN do repositório ECR |
| <a name="output_name"></a> [name](#output\_name) | O nome do repositório ECR |
| <a name="output_repository_url"></a> [repository\_url](#output\_repository\_url) | A URL do repositório ECR |
