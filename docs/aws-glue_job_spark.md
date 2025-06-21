# AWS glue_job_spark Module

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
| [aws_glue_job.job](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_job) | resource |
| [aws_s3_object.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_TagEnv"></a> [TagEnv](#input\_TagEnv) | Enviroment | `string` | n/a | yes |
| <a name="input_TagProject"></a> [TagProject](#input\_TagProject) | Project Name | `string` | n/a | yes |
| <a name="input_athena_workgroup_name"></a> [athena\_workgroup\_name](#input\_athena\_workgroup\_name) | Nome do Athena Workgroup | `string` | n/a | yes |
| <a name="input_glue_version"></a> [glue\_version](#input\_glue\_version) | Glue version | `string` | `"4.0"` | no |
| <a name="input_iam_role_arn"></a> [iam\_role\_arn](#input\_iam\_role\_arn) | role arn glue | `string` | n/a | yes |
| <a name="input_job_name_suffix"></a> [job\_name\_suffix](#input\_job\_name\_suffix) | Suffix for the job name | `string` | n/a | yes |
| <a name="input_max_concurrent_runs"></a> [max\_concurrent\_runs](#input\_max\_concurrent\_runs) | Maximum concurrent runs for the Glue job | `number` | `1000` | no |
| <a name="input_max_file_gb"></a> [max\_file\_gb](#input\_max\_file\_gb) | Maximum size file to process | `number` | n/a | yes |
| <a name="input_min_file_mb"></a> [min\_file\_mb](#input\_min\_file\_mb) | Minimum size file to process | `number` | n/a | yes |
| <a name="input_number_of_workers"></a> [number\_of\_workers](#input\_number\_of\_workers) | Number of workers | `number` | n/a | yes |
| <a name="input_s3_art"></a> [s3\_art](#input\_s3\_art) | Map of S3 buckets used by the job | `string` | n/a | yes |
| <a name="input_s3_logs"></a> [s3\_logs](#input\_s3\_logs) | Map of S3 buckets used by the job | `string` | n/a | yes |
| <a name="input_s3_raw"></a> [s3\_raw](#input\_s3\_raw) | Map of S3 buckets used by the job | `string` | n/a | yes |
| <a name="input_s3_tmp"></a> [s3\_tmp](#input\_s3\_tmp) | Map of S3 buckets used by the job | `string` | n/a | yes |
| <a name="input_script_file"></a> [script\_file](#input\_script\_file) | script file | `string` | n/a | yes |
| <a name="input_script_folder"></a> [script\_folder](#input\_script\_folder) | script file | `string` | `"../scripts/glue/"` | no |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | ARN do SNS Topic para notificações de erros | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags to apply to all resources | `map(string)` | n/a | yes |
| <a name="input_test"></a> [test](#input\_test) | rodar em test | `bool` | n/a | yes |
| <a name="input_worker_type"></a> [worker\_type](#input\_worker\_type) | Worker type for Glue job | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | ARN da função Lambda criada |
| <a name="output_name"></a> [name](#output\_name) | Nome da função Lambda criada |
