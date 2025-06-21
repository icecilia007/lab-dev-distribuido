# AWS Serverless Logistics Platform

Migração completa da plataforma logística Java para arquitetura serverless AWS com Python.

## 📁 Estrutura do Projeto

```
aws-serverless-logistics/
├── functions/
│   ├── auth/               # Lambda de autenticação
│   ├── usuarios/           # Lambda de usuários
│   └── pedidos/            # Lambda de pedidos
├── main.tf                 # Configuração principal Terraform
├── terraform.tfvars        # Variáveis do Terraform
├── deploy.sh              # Script de deploy automatizado
└── README.md              # Este arquivo
```

## 🚀 Deploy

### Pré-requisitos

1. **AWS CLI configurado:**
```bash
aws configure
```

2. **Terraform instalado:**
```bash
# Ubuntu/Debian
sudo apt-get install terraform

# macOS
brew install terraform
```

3. **Docker instalado** (para build das imagens Lambda)

### Deploy Completo

```bash
cd aws-serverless-logistics
./deploy.sh
```

O script irá:
1. ✅ Inicializar Terraform
2. ✅ Planejar a infraestrutura
3. ✅ Criar todos os recursos AWS
4. ✅ Fazer build e deploy das Lambdas
5. ✅ Configurar API Gateway

## 🏗️ Infraestrutura Criada

### DynamoDB Tables
- `dev-logistics-users` - Usuários (clientes, motoristas, operadores)
- `dev-logistics-pedidos` - Pedidos
- `dev-logistics-locations` - Localizações de rastreamento
- `dev-logistics-notifications` - Notificações

### Lambda Functions
- `dev_logistics_auth` - Autenticação JWT
- `dev_logistics_usuarios` - CRUD usuários + registro
- `dev_logistics_pedidos` - Gestão de pedidos
- `dev_logistics_notificacoes` - Sistema de notificações (Push + Email + SMS)
- `dev_logistics_rastreamento` - Rastreamento em tempo real + geolocalização

### API Gateway
- **Base URL:** `https://api-id.execute-api.us-east-1.amazonaws.com/prod`
- **Endpoints disponíveis:**
  
  **Auth:**
  - `POST /api/auth/login`
  - `POST /api/auth/registro/cliente`
  - `POST /api/auth/registro/motorista`
  
  **Pedidos:**
  - `GET /api/pedidos/{userType}/{userId}`
  - `POST /api/pedidos`
  - `GET /api/pedidos/{pedidoId}`
  - `POST /api/pedidos/{pedidoId}/aceitar`
  - `PATCH /api/pedidos/{pedidoId}/cancelar`
  
  **Rastreamento:**
  - `GET /api/rastreamento/pedido/{pedidoId}`
  - `GET /api/rastreamento/historico/{pedidoId}`
  - `POST /api/rastreamento/localizacao`
  - `GET /api/rastreamento/estatisticas/motorista/{driverId}`
  - `POST /api/rastreamento/pedido/{pedidoId}/coleta`
  - `POST /api/rastreamento/pedido/{pedidoId}/entrega`
  
  **Notificações:**
  - `GET /api/notificacoes/destinatario/{userId}`
  - `PATCH /api/notificacoes/{notificationId}/marcar-lida`
  - `POST /api/notificacoes/preferencias`
  - `GET /api/notificacoes/preferencias/{userId}`

### Outros Serviços
- **SQS:** Event Queue (EQ do diagrama) - Eventos entre serviços
- **SNS Topics:** Pub/Sub Topics (PST do diagrama) - Campanhas segmentadas
  - `notifications-general` - Campanhas gerais
  - `notifications-premium` - Clientes premium  
  - `notifications-regional` - Campanhas por região
- **SES:** Email Service (ES do diagrama) - Emails transacionais
- **ECR:** Repositórios para imagens Docker das Lambdas

## 📱 Integração com Flutter

Após o deploy, você receberá a URL do API Gateway. No seu app Flutter, altere:

```dart
// api_service.dart - linha 23
// DE:
apiGatewayUrl = apiGatewayUrl ?? 'http://10.0.2.2:8000';

// PARA:
apiGatewayUrl = apiGatewayUrl ?? 'https://SEU-API-ID.execute-api.us-east-1.amazonaws.com/prod';
```

## 🔧 Comandos Úteis

### Ver recursos criados
```bash
terraform output
```

### Atualizar apenas as Lambdas
```bash
terraform apply -target=module.auth_lambda
terraform apply -target=module.usuarios_lambda
terraform apply -target=module.pedidos_lambda
```

### Destruir tudo
```bash
terraform destroy -var-file="terraform.tfvars"
```

### Logs das Lambdas
```bash
aws logs tail /aws/lambda/dev_logistics_auth --follow
aws logs tail /aws/lambda/dev_logistics_usuarios --follow
aws logs tail /aws/lambda/dev_logistics_pedidos --follow
```

## 🔍 Testes

### Testar autenticação
```bash
curl -X POST https://SEU-API-ID.execute-api.us-east-1.amazonaws.com/prod/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "123456"}'
```

### Testar registro de cliente
```bash
curl -X POST https://SEU-API-ID.execute-api.us-east-1.amazonaws.com/prod/api/auth/registro/cliente \
  -H "Content-Type: application/json" \
  -d '{"name": "João", "email": "joao@example.com", "password": "123456", "phone": "11999999999"}'
```

## 💰 Custos Estimados

- **Lambda:** $30-50/mês (1M requests)
- **API Gateway:** $35/mês (1M requests)  
- **DynamoDB:** $25/mês (read/write básico)
- **SQS/SNS:** $10/mês
- **Total:** ~$100-120/mês

## 🛠️ Troubleshooting

### Lambda não consegue acessar DynamoDB
Verifique as permissões IAM nos módulos.

### API Gateway retorna 502
Verifique os logs da Lambda correspondente.

### Build da imagem Docker falha
Certifique-se que o Docker está rodando e que os arquivos existem.

### Cold start muito lento
Configure provisioned concurrency nas Lambdas críticas.

## 📋 Próximos Passos

1. ✅ **Implementar JWT Authorizer** no API Gateway
2. ✅ **Adicionar Lambdas de rastreamento e notificações**
3. ✅ **Configurar CloudWatch dashboards**
4. ✅ **Implementar testes automatizados**
5. ✅ **Configurar CI/CD com GitHub Actions**

---

🎯 **Migração Java → AWS Python:** Completa e funcionando!