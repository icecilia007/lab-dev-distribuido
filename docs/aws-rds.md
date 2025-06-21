# AWS rds Module

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
| [aws_db_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_subnet_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_security_group.rds_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_TagEnv"></a> [TagEnv](#input\_TagEnv) | Nome do ambiente (ex: prod, staging) | `string` | n/a | yes |
| <a name="input_TagProject"></a> [TagProject](#input\_TagProject) | Nome do projeto (ex: myapp) | `string` | n/a | yes |
| <a name="input_instance_class"></a> [instance\_class](#input\_instance\_class) | Tipo de instância RDS | `string` | `"db.t3.micro"` | no |
| <a name="input_skip_final_snapshot"></a> [skip\_final\_snapshot](#input\_skip\_final\_snapshot) | n/a | `bool` | `false` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Lista de IDs das sub‐redes (pelo menos 2) para o DB Subnet Group | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags comuns a todos os recursos | `map(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID da VPC onde criar o RDS | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_db_instance_address"></a> [db\_instance\_address](#output\_db\_instance\_address) | Endereço da instância RDS sem a porta |
| <a name="output_db_instance_endpoint"></a> [db\_instance\_endpoint](#output\_db\_instance\_endpoint) | Endpoint da conexão para a instância RDS |
| <a name="output_db_instance_id"></a> [db\_instance\_id](#output\_db\_instance\_id) | Identificador da instância do banco de dados |
| <a name="output_db_instance_port"></a> [db\_instance\_port](#output\_db\_instance\_port) | Porta da instância do banco de dados |
| <a name="output_db_instance_username"></a> [db\_instance\_username](#output\_db\_instance\_username) | Nome de usuário do administrador da base de dados |
| <a name="output_db_subnet_group_id"></a> [db\_subnet\_group\_id](#output\_db\_subnet\_group\_id) | ID do grupo de subnets para o RDS |
| <a name="output_endpoint"></a> [endpoint](#output\_endpoint) | Endpoint de conexão do RDS (host:port) |
| <a name="output_endpoint_host"></a> [endpoint\_host](#output\_endpoint\_host) | Host da endpoint sem a porta |
| <a name="output_rds_master_password_secret_arn"></a> [rds\_master\_password\_secret\_arn](#output\_rds\_master\_password\_secret\_arn) | O ARN do secret no Secrets Manager que contém a senha master do RDS |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID do grupo de segurança criado para o RDS |
