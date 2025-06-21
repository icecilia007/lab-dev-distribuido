# AWS route53 Module

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
| [aws_acm_certificate.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_api_gateway_base_path_mapping.rest_api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_base_path_mapping) | resource |
| [aws_api_gateway_domain_name.rest_api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_domain_name) | resource |
| [aws_apigatewayv2_api_mapping.http_api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api_mapping) | resource |
| [aws_apigatewayv2_domain_name.http_api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_domain_name) | resource |
| [aws_cloudwatch_log_group.route53_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_resource_policy.route53_query_logging_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_resource_policy) | resource |
| [aws_kms_key.dnssec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_route53_hosted_zone_dnssec.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_hosted_zone_dnssec) | resource |
| [aws_route53_key_signing_key.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_key_signing_key) | resource |
| [aws_route53_query_log.query_logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_query_log) | resource |
| [aws_route53_record.api_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.api_gateway_mapping](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.certificate_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_zone.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_TagEnv"></a> [TagEnv](#input\_TagEnv) | Ambiente (dev, staging, prod) | `string` | n/a | yes |
| <a name="input_TagProject"></a> [TagProject](#input\_TagProject) | Nome do projeto | `string` | n/a | yes |
| <a name="input_api_gateway_domain_name"></a> [api\_gateway\_domain\_name](#input\_api\_gateway\_domain\_name) | Nome de domínio do API Gateway para criar um alias direto (CloudFront ou regional endpoint) | `string` | `""` | no |
| <a name="input_api_gateway_hosted_zone_id"></a> [api\_gateway\_hosted\_zone\_id](#input\_api\_gateway\_hosted\_zone\_id) | ID da zona hospedada do API Gateway para criar um alias direto | `string` | `""` | no |
| <a name="input_api_gateway_subdomain"></a> [api\_gateway\_subdomain](#input\_api\_gateway\_subdomain) | Subdomínio para o API Gateway (ex: 'api' criará api.exemplo.com) | `string` | `"api"` | no |
| <a name="input_api_id"></a> [api\_id](#input\_api\_id) | ID da API Gateway (REST ou HTTP) para o mapeamento de domínio personalizado | `string` | `""` | no |
| <a name="input_api_mapping_key"></a> [api\_mapping\_key](#input\_api\_mapping\_key) | Caminho base para o mapeamento da API (ex: 'v1'). Deixe vazio para o caminho raiz. | `string` | `""` | no |
| <a name="input_api_stage_name"></a> [api\_stage\_name](#input\_api\_stage\_name) | Nome do estágio da API para o mapeamento de domínio personalizado | `string` | `""` | no |
| <a name="input_api_type"></a> [api\_type](#input\_api\_type) | Tipo de API Gateway: 'REST' ou 'HTTP' | `string` | `"REST"` | no |
| <a name="input_certificate_arn"></a> [certificate\_arn](#input\_certificate\_arn) | ARN de um certificado ACM existente, caso não esteja criando um novo | `string` | `""` | no |
| <a name="input_create_api_mapping"></a> [create\_api\_mapping](#input\_create\_api\_mapping) | Define se será criado um mapeamento de domínio personalizado para o API Gateway | `bool` | `false` | no |
| <a name="input_create_certificate"></a> [create\_certificate](#input\_create\_certificate) | Define se um certificado ACM será criado para o domínio | `bool` | `true` | no |
| <a name="input_create_zone"></a> [create\_zone](#input\_create\_zone) | Define se uma nova zona hospedada será criada. Defina como false para usar um domínio existente | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Nome de domínio para a zona do Route 53 (ex: exemplo.com) | `string` | n/a | yes |
| <a name="input_subject_alternative_names"></a> [subject\_alternative\_names](#input\_subject\_alternative\_names) | Nomes alternativos de domínio para o certificado ACM (ex: ["*.exemplo.com"]) | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags adicionais para os recursos | `map(string)` | `{}` | no |
| <a name="input_validation_method"></a> [validation\_method](#input\_validation\_method) | Método de validação para o certificado ACM (DNS ou EMAIL) | `string` | `"DNS"` | no |
| <a name="input_validation_timeout"></a> [validation\_timeout](#input\_validation\_timeout) | Tempo máximo para aguardar a validação do certificado (ex: '45m' para 45 minutos) | `string` | `"45m"` | no |
| <a name="input_wait_for_validation"></a> [wait\_for\_validation](#input\_wait\_for\_validation) | Define se o terraform deve esperar pela validação do certificado. Defina como false para evitar bloqueio durante a validação | `bool` | `false` | no |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | ID da zona hospedada existente, caso não esteja criando uma nova | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_domain_name"></a> [api\_domain\_name](#output\_api\_domain\_name) | Nome de domínio configurado para o API Gateway |
| <a name="output_certificate_arn"></a> [certificate\_arn](#output\_certificate\_arn) | ARN do certificado ACM |
| <a name="output_certificate_arn_debug"></a> [certificate\_arn\_debug](#output\_certificate\_arn\_debug) | n/a |
| <a name="output_certificate_status"></a> [certificate\_status](#output\_certificate\_status) | Status do certificado ACM |
| <a name="output_certificate_validation_options"></a> [certificate\_validation\_options](#output\_certificate\_validation\_options) | n/a |
| <a name="output_domain_validation_options"></a> [domain\_validation\_options](#output\_domain\_validation\_options) | Opções de validação de domínio para o certificado ACM |
| <a name="output_http_api_domain_name"></a> [http\_api\_domain\_name](#output\_http\_api\_domain\_name) | Nome de domínio configurado para o HTTP API Gateway |
| <a name="output_http_api_mapping_id"></a> [http\_api\_mapping\_id](#output\_http\_api\_mapping\_id) | ID do mapeamento de domínio personalizado para o HTTP API Gateway |
| <a name="output_name_servers"></a> [name\_servers](#output\_name\_servers) | Name servers da zona hospedada |
| <a name="output_rest_api_domain_name"></a> [rest\_api\_domain\_name](#output\_rest\_api\_domain\_name) | Nome de domínio configurado para o REST API Gateway |
| <a name="output_rest_api_mapping_id"></a> [rest\_api\_mapping\_id](#output\_rest\_api\_mapping\_id) | ID do mapeamento de domínio personalizado para o REST API Gateway |
| <a name="output_zone_id"></a> [zone\_id](#output\_zone\_id) | ID da zona hospedada do Route 53 |
| <a name="output_zone_name"></a> [zone\_name](#output\_zone\_name) | Nome da zona hospedada do Route 53 |
