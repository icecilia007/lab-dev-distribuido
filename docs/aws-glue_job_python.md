# AWS glue_job_python Module

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
| [aws_glue_connection.subnet_glue_id](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_connection) | resource |
| [aws_glue_job.job](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_job) | resource |
| [aws_glue_trigger.job_schedule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_trigger) | resource |
| [aws_s3_object.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_TagEnv"></a> [TagEnv](#input\_TagEnv) | Enviroment | `string` | n/a | yes |
| <a name="input_TagProject"></a> [TagProject](#input\_TagProject) | Project Name | `string` | n/a | yes |
| <a name="input_additional_arguments"></a> [additional\_arguments](#input\_additional\_arguments) | Additional arguments for the Glue job | `map(string)` | `{}` | no |
| <a name="input_additional_python_modules"></a> [additional\_python\_modules](#input\_additional\_python\_modules) | Additional Python modules to be installed | `string` | `"pyarrow>=8.0.0,awswrangler>=3.9.1,pyiceberg[glue]"` | no |
| <a name="input_athena_workgroup_name"></a> [athena\_workgroup\_name](#input\_athena\_workgroup\_name) | Nome do Athena Workgroup | `string` | n/a | yes |
| <a name="input_availability_zone"></a> [availability\_zone](#input\_availability\_zone) | n/a | `string` | `null` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags to apply to all resources | `map(string)` | n/a | yes |
| <a name="input_glue_connection_name"></a> [glue\_connection\_name](#input\_glue\_connection\_name) | n/a | `string` | n/a | yes |
| <a name="input_glue_schedule_expression"></a> [glue\_schedule\_expression](#input\_glue\_schedule\_expression) | Expressão cron para agendamento do Glue | `string` | `null` | no |
| <a name="input_iam_role_arn"></a> [iam\_role\_arn](#input\_iam\_role\_arn) | role arn glue | `string` | n/a | yes |
| <a name="input_job_name_suffix"></a> [job\_name\_suffix](#input\_job\_name\_suffix) | Suffix for the job name | `string` | n/a | yes |
| <a name="input_max_capacity"></a> [max\_capacity](#input\_max\_capacity) | Maximum capacity for the Glue job | `number` | `1` | no |
| <a name="input_max_concurrent_runs"></a> [max\_concurrent\_runs](#input\_max\_concurrent\_runs) | Maximum concurrent runs for the Glue job | `number` | `1000` | no |
| <a name="input_s3_art"></a> [s3\_art](#input\_s3\_art) | Map of S3 buckets used by the job | `string` | n/a | yes |
| <a name="input_s3_raw"></a> [s3\_raw](#input\_s3\_raw) | Map of S3 buckets used by the job | `string` | n/a | yes |
| <a name="input_s3_tmp"></a> [s3\_tmp](#input\_s3\_tmp) | Map of S3 buckets used by the job | `string` | n/a | yes |
| <a name="input_script_file"></a> [script\_file](#input\_script\_file) | script file | `string` | n/a | yes |
| <a name="input_script_folder"></a> [script\_folder](#input\_script\_folder) | script file | `string` | `"../scripts/glue/"` | no |
| <a name="input_security_group_id_list"></a> [security\_group\_id\_list](#input\_security\_group\_id\_list) | n/a | `list(string)` | `[]` | no |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | ARN do SNS Topic para notificações de erros | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | n/a | `string` | `null` | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | timeout do Glue | `number` | `68800` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | ARN da função Lambda criada |
| <a name="output_name"></a> [name](#output\_name) | Nome da função Lambda criada |
