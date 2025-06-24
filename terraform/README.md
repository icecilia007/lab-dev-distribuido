# Infraestrutura AWS para Notificações de Email

Este diretório contém a infraestrutura Terraform para implementar um sistema de notificações de email usando AWS SQS, Lambda e SES.

## Arquitetura

```
Aplicação Java → SQS Queue → Lambda Function → SES → Email do Usuário
```

## Componentes

- **SQS Queue**: Recebe mensagens de email do serviço de notificação
- **Lambda Function**: Processa mensagens da fila e formata emails
- **SES**: Envia emails formatados para os usuários
- **Dead Letter Queue**: Para mensagens que falharam no processamento

## Pré-requisitos

1. AWS CLI configurado com credenciais apropriadas
2. Terraform instalado
3. Python 3.11+ para build da Lambda
4. Conta AWS (SES Sandbox é suficiente para desenvolvimento)

## Deploy

### 1. Build da Função Lambda
```bash
cd ../lambda
./build_deploy.sh
```

### 2. Deploy da Infraestrutura
```bash
# Inicializar Terraform
terraform init

# Planejar deployment (usando seu email)
terraform plan -var="sender_email=seu-email@gmail.com"

# Aplicar mudanças
terraform apply -var="sender_email=seu-email@gmail.com"
```

### 3. Verificar Email no SES
**IMPORTANTE**: Após o deploy, você deve verificar o email remetente no SES:

```bash
# Verificar email remetente
aws ses verify-email-identity --email-address seu-email@gmail.com

# Verificar status
aws ses get-identity-verification-attributes --identities seu-email@gmail.com
```

Você receberá um email de verificação no endereço fornecido. Clique no link para verificar.

### 4. Verificar Emails de Destino (SES Sandbox)
No SES Sandbox, você também precisa verificar os emails de destino:

```bash
# Exemplo: verificar email do usuário que vai receber notificações
aws ses verify-email-identity --email-address usuario@exemplo.com
```

## Configuração da Aplicação

Após o deploy, atualize o `application.yml` da aplicação com a URL da fila SQS:

```yaml
aws:
  region: us-east-1
  sqs:
    email-queue-url: [URL_DA_FILA_DO_OUTPUT]
```

## Variáveis de Ambiente

- `AWS_REGION`: Região AWS (padrão: us-east-1)
- `AWS_SQS_EMAIL_QUEUE_URL`: URL da fila SQS (definida pelo output do Terraform)

## Monitoramento

- CloudWatch Logs: `/aws/lambda/email-processor`
- SQS Metrics: Número de mensagens, falhas, etc.
- SES Metrics: Bounce rate, complaint rate, etc.

## Custos Estimados

- SQS: ~$0.40 por 1M requests
- Lambda: Primeiro 1M requests gratuitos
- SES: $0.10 por 1,000 emails
- CloudWatch Logs: $0.50 per GB

## Troubleshooting

### Lambda não está processando mensagens
1. Verificar permissões IAM
2. Verificar logs no CloudWatch
3. Verificar Dead Letter Queue

### Emails não estão sendo enviados
1. Verificar se domínio está verificado no SES
2. Verificar se está fora do SES Sandbox
3. Verificar logs da Lambda

### Mensagens ficando na fila
1. Verificar configuração do Event Source Mapping
2. Verificar se Lambda está ativa
3. Verificar timeout da Lambda