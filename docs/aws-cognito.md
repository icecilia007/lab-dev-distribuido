# AWS cognito Module

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
| [aws_cognito_user_pool.pool](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool) | resource |
| [aws_cognito_user_pool_client.client](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_client) | resource |
| [aws_cognito_user_pool_domain.domain](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_domain) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_TagEnv"></a> [TagEnv](#input\_TagEnv) | Tag de ambiente para identificação | `string` | n/a | yes |
| <a name="input_TagProject"></a> [TagProject](#input\_TagProject) | Tag de projeto para identificação | `string` | n/a | yes |
| <a name="input_additional_schemas"></a> [additional\_schemas](#input\_additional\_schemas) | Schemas adicionais para o User Pool | <pre>list(object({<br>    name                = string<br>    attribute_data_type = string<br>    mutable             = optional(bool, true)<br>    required            = optional(bool, false)<br>    min_length          = optional(number)<br>    max_length          = optional(number)<br>  }))</pre> | `[]` | no |
| <a name="input_allowed_oauth_flows"></a> [allowed\_oauth\_flows](#input\_allowed\_oauth\_flows) | Fluxos OAuth permitidos | `list(string)` | <pre>[<br>  "implicit"<br>]</pre> | no |
| <a name="input_allowed_oauth_scopes"></a> [allowed\_oauth\_scopes](#input\_allowed\_oauth\_scopes) | Escopos OAuth permitidos | `list(string)` | <pre>[<br>  "openid"<br>]</pre> | no |
| <a name="input_auto_verified_attributes"></a> [auto\_verified\_attributes](#input\_auto\_verified\_attributes) | Lista de atributos que serão auto-verificados | `list(string)` | <pre>[<br>  "email"<br>]</pre> | no |
| <a name="input_callback_urls"></a> [callback\_urls](#input\_callback\_urls) | URLs de callback para o cliente Cognito | `list(string)` | <pre>[<br>  "https://localhost:3000/callback"<br>]</pre> | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Nome do domínio Cognito para a página de login | `string` | `""` | no |
| <a name="input_explicit_auth_flows"></a> [explicit\_auth\_flows](#input\_explicit\_auth\_flows) | Lista de fluxos de autenticação explicitamente habilitados | `list(string)` | <pre>[<br>  "ALLOW_ADMIN_USER_PASSWORD_AUTH",<br>  "ALLOW_USER_PASSWORD_AUTH",<br>  "ALLOW_REFRESH_TOKEN_AUTH"<br>]</pre> | no |
| <a name="input_generate_secret"></a> [generate\_secret](#input\_generate\_secret) | n/a | `bool` | `false` | no |
| <a name="input_lambda_config_arn"></a> [lambda\_config\_arn](#input\_lambda\_config\_arn) | n/a | `string` | `""` | no |
| <a name="input_logout_urls"></a> [logout\_urls](#input\_logout\_urls) | URLs de logout para o cliente Cognito | `list(string)` | <pre>[<br>  "https://localhost:3000/logout"<br>]</pre> | no |
| <a name="input_password_policy"></a> [password\_policy](#input\_password\_policy) | Configurações personalizadas de política de senha | <pre>object({<br>    minimum_length    = optional(number, 8)<br>    require_lowercase = optional(bool, true)<br>    require_numbers   = optional(bool, true)<br>    require_symbols   = optional(bool, true)<br>    require_uppercase = optional(bool, true)<br>  })</pre> | <pre>{<br>  "minimum_length": 8,<br>  "require_lowercase": true,<br>  "require_numbers": true,<br>  "require_symbols": true,<br>  "require_uppercase": true<br>}</pre> | no |
| <a name="input_supported_identity_providers"></a> [supported\_identity\_providers](#input\_supported\_identity\_providers) | Provedores de identidade suportados | `list(string)` | <pre>[<br>  "COGNITO"<br>]</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags comuns para todos os recursos | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_user_pool_arn"></a> [user\_pool\_arn](#output\_user\_pool\_arn) | ARN do User Pool Cognito |
| <a name="output_user_pool_client_id"></a> [user\_pool\_client\_id](#output\_user\_pool\_client\_id) | ID do Cliente Cognito |
| <a name="output_user_pool_client_secret"></a> [user\_pool\_client\_secret](#output\_user\_pool\_client\_secret) | Segredo do Cliente Cognito |
| <a name="output_user_pool_domain"></a> [user\_pool\_domain](#output\_user\_pool\_domain) | Domínio do User Pool Cognito |
| <a name="output_user_pool_id"></a> [user\_pool\_id](#output\_user\_pool\_id) | ID do User Pool Cognito |
