# Estratégia de Migração: Java → AWS Python Serverless

## Visão Geral

Esta estratégia detalha a migração dos microserviços Java para uma arquitetura 100% serverless AWS com Python, mantendo o app Flutter local intacto.

## Situação Atual vs. Destino

### Arquitetura Atual (Java)
```
Flutter App (Local) → API Gateway (Java:8000) → {
  ├── Usuario Service (Java:8080)
  ├── Pedidos Service (Java:8081)  
  ├── Rastreamento Service (Java:8082)
  ├── Notificacao Service (Java:8083)
  └── PostgreSQL + RabbitMQ
}
```

### Arquitetura Destino (AWS Python Serverless)
```
Flutter App (Local) → AWS API Gateway → {
  ├── Lambda Auth (Python)
  ├── Lambda Usuarios (Python)
  ├── Lambda Pedidos (Python)
  ├── Lambda Rastreamento (Python)
  ├── Lambda Notificacoes (Python)
  └── DynamoDB + SQS + SNS + S3
}
```

## Dockerfile Base para Todas as Aplicações

```dockerfile
FROM public.ecr.aws/lambda/python:3.12

# Copy requirements.txt
COPY requirements.txt ${LAMBDA_TASK_ROOT}

# Install the specified packages
RUN pip install -r requirements.txt

# Copy function code
COPY lambda_function.py ${LAMBDA_TASK_ROOT}

# Set the CMD to your handler
CMD [ "lambda_function.handler" ]
```

## Mapeamento de Serviços AWS

| Serviço Java | Substituto AWS | Lambda Function | Container |
|--------------|----------------|-----------------|-----------|
| API Gateway | AWS API Gateway | - | - |
| Usuario Service | Lambda + DynamoDB | `usuarios-lambda` | ✅ |
| Pedidos Service | Lambda + DynamoDB | `pedidos-lambda` | ✅ |
| Rastreamento Service | Lambda + DynamoDB | `rastreamento-lambda` | ✅ |
| Notificacao Service | Lambda + SNS + SES | `notificacao-lambda` | ✅ |
| PostgreSQL | DynamoDB | - | - |
| RabbitMQ | SQS + EventBridge | - | - |

## Estrutura de Diretórios AWS

```
aws-logistics-serverless/
├── functions/
│   ├── auth/
│   │   ├── Dockerfile
│   │   ├── lambda_function.py
│   │   └── requirements.txt
│   ├── usuarios/
│   │   ├── Dockerfile
│   │   ├── lambda_function.py
│   │   └── requirements.txt
│   ├── pedidos/
│   │   ├── Dockerfile
│   │   ├── lambda_function.py
│   │   └── requirements.txt
│   ├── rastreamento/
│   │   ├── Dockerfile
│   │   ├── lambda_function.py
│   │   └── requirements.txt
│   └── notificacoes/
│       ├── Dockerfile
│       ├── lambda_function.py
│       └── requirements.txt
├── shared/
│   ├── models/          # Modelos Pydantic
│   ├── database/        # DynamoDB helpers
│   ├── auth/           # JWT utilities
│   └── utils/          # Funções comuns
├── infrastructure/
│   ├── terraform/      # IaC
│   └── cloudformation/
└── deploy/
    ├── serverless.yml
    └── docker-compose.local.yml
```

## Impacto Mínimo no Flutter

### ✅ SEM MUDANÇAS
- **Endpoints**: Mesmos paths (`/api/auth/login`, `/api/pedidos`, etc.)
- **JSON**: Mesmos formatos de request/response
- **Autenticação**: Mesmo JWT Bearer token
- **Funcionalidades**: Todas mantidas

### 🔧 ÚNICA MUDANÇA NECESSÁRIA
```dart
// api_service.dart - linha 23
// DE:
apiGatewayUrl = apiGatewayUrl ?? 'http://10.0.2.2:8000';

// PARA:
apiGatewayUrl = apiGatewayUrl ?? 'https://seu-api-id.execute-api.us-east-1.amazonaws.com/prod';
```

## Arquitetura API Gateway + Lambdas

### API Gateway gerencia:
- ✅ **Rotas**: `/api/auth/login`, `/api/pedidos`, etc.
- ✅ **Autenticação**: JWT Authorizer
- ✅ **CORS**: Headers automáticos
- ✅ **Validação**: Request/Response
- ✅ **Rate Limiting**: Throttling

### Lambdas fazem:
- ✅ **Processamento puro**: Lógica de negócio
- ✅ **Database**: DynamoDB operations
- ✅ **Events**: SQS/SNS integration
- ✅ **Return**: JSON response simples

## Implementação por Serviço

### 1. Lambda Auth (login)

**requirements.txt:**
```
boto3==1.34.0
PyJWT==2.8.0
bcrypt==4.1.0
```

**lambda_function.py:**
```python
import json
import boto3
import jwt
import bcrypt
from datetime import datetime, timedelta

dynamodb = boto3.resource('dynamodb')
users_table = dynamodb.Table('Users')

def handler(event, context):
    try:
        # Parse request body (API Gateway já parsed)
        body = json.loads(event['body'])
        email = body['email']
        password = body['password']
        
        # Buscar usuário no DynamoDB
        response = users_table.get_item(Key={'email': email})
        
        if 'Item' not in response:
            return {
                'statusCode': 401,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'message': 'Email ou senha inválidos'})
            }
        
        user = response['Item']
        
        # Verificar senha
        if not bcrypt.checkpw(password.encode('utf-8'), user['password'].encode('utf-8')):
            return {
                'statusCode': 401,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'message': 'Email ou senha inválidos'})
            }
        
        # Gerar JWT
        payload = {
            'user_id': user['id'],
            'email': user['email'],
            'type': user['type'],
            'exp': datetime.utcnow() + timedelta(hours=24)
        }
        
        token = jwt.encode(payload, 'your-secret-key', algorithm='HS256')
        
        # Retorna mesmo formato que Java
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Authorization': f'Bearer {token}'
            },
            'body': json.dumps({
                'id': user['id'],
                'name': user['name'],
                'email': user['email'],
                'type': user['type'],
                'phone': user.get('phone')
            })
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'message': f'Erro interno: {str(e)}'})
        }
```

### 2. Lambda Register Cliente

**requirements.txt:**
```
boto3==1.34.0
bcrypt==4.1.0
```

**lambda_function.py:**
```python
import json
import boto3
import bcrypt
import uuid

dynamodb = boto3.resource('dynamodb')
users_table = dynamodb.Table('Users')

def handler(event, context):
    try:
        body = json.loads(event['body'])
        
        # Hash da senha
        hashed_password = bcrypt.hashpw(
            body['password'].encode('utf-8'), 
            bcrypt.gensalt()
        ).decode('utf-8')
        
        # Criar usuário
        user_id = int(str(uuid.uuid4().int)[:10])
        
        users_table.put_item(Item={
            'id': user_id,
            'email': body['email'],
            'name': body['name'],
            'password': hashed_password,
            'type': 'CLIENTE',
            'phone': body.get('phone'),
            'created_at': str(datetime.utcnow())
        })
        
        return {
            'statusCode': 201,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'message': 'Cliente registrado com sucesso'})
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'message': f'Erro: {str(e)}'})
        }
```

### 3. Lambda Get Pedidos

**requirements.txt:**
```
boto3==1.34.0
```

**lambda_function.py:**
```python
import json
import boto3

dynamodb = boto3.resource('dynamodb')
pedidos_table = dynamodb.Table('Pedidos')

def handler(event, context):
    try:
        # API Gateway já parsed os path parameters
        user_type = event['pathParameters']['userType']
        user_id = int(event['pathParameters']['userId'])
        
        # Query DynamoDB
        if user_type == 'cliente':
            response = pedidos_table.scan(
                FilterExpression='clienteId = :client_id',
                ExpressionAttributeValues={':client_id': user_id}
            )
        elif user_type == 'motorista':
            response = pedidos_table.scan(
                FilterExpression='motoristaId = :motorista_id',
                ExpressionAttributeValues={':motorista_id': user_id}
            )
        
        pedidos = response.get('Items', [])
        
        # Converter para formato Java compatível
        formatted_pedidos = []
        for pedido in pedidos:
            formatted_pedidos.append({
                'id': pedido['id'],
                'origemLatitude': pedido['origemLatitude'],
                'origemLongitude': pedido['origemLongitude'],
                'destinoLatitude': pedido['destinoLatitude'],
                'destinoLongitude': pedido['destinoLongitude'],
                'tipoMercadoria': pedido['tipoMercadoria'],
                'status': pedido['status'],
                'clienteId': pedido.get('clienteId'),
                'motoristaId': pedido.get('motoristaId'),
                'dataCriacao': pedido['dataCriacao']
            })
        
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps(formatted_pedidos)
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'message': f'Erro: {str(e)}'})
        }
```

### 4. Lambda Create Pedido

**requirements.txt:**
```
boto3==1.34.0
```

**lambda_function.py:**
```python
import json
import boto3
import uuid
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
sqs = boto3.client('sqs')
pedidos_table = dynamodb.Table('Pedidos')

def handler(event, context):
    try:
        body = json.loads(event['body'])
        
        # Criar pedido
        pedido_id = int(str(uuid.uuid4().int)[:10])
        
        pedido = {
            'id': pedido_id,
            'origemLatitude': body['origemLatitude'],
            'origemLongitude': body['origemLongitude'],
            'destinoLatitude': body['destinoLatitude'],
            'destinoLongitude': body['destinoLongitude'],
            'tipoMercadoria': body['tipoMercadoria'],
            'clienteId': body['clienteId'],
            'status': 'AGUARDANDO_MOTORISTA',
            'dataCriacao': str(datetime.utcnow())
        }
        
        # Salvar no DynamoDB
        pedidos_table.put_item(Item=pedido)
        
        # Enviar evento para SQS (notificações)
        sqs.send_message(
            QueueUrl='https://sqs.region.amazonaws.com/account/pedido-created',
            MessageBody=json.dumps({
                'event': 'pedido_created',
                'pedido_id': pedido_id,
                'cliente_id': body['clienteId']
            })
        )
        
        return {
            'statusCode': 201,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps(pedido)
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'message': f'Erro: {str(e)}'})
        }
```

### 5. Lambda Update Location

**requirements.txt:**
```
boto3==1.34.0
geopy==2.4.0
```

**lambda_function.py:**
```python
import json
import boto3
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
locations_table = dynamodb.Table('Locations')

def handler(event, context):
    try:
        body = json.loads(event['body'])
        
        # Salvar localização
        location = {
            'id': str(uuid.uuid4()),
            'motoristaId': body['motoristaId'],
            'pedidoId': body.get('pedidoId'),
            'latitude': body['latitude'],
            'longitude': body['longitude'],
            'statusVeiculo': body['statusVeiculo'],
            'timestamp': str(datetime.utcnow())
        }
        
        locations_table.put_item(Item=location)
        
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'success': True})
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'message': f'Erro: {str(e)}'})
        }
```

## Infraestrutura AWS (Terraform)

### DynamoDB Tables
```hcl
resource "aws_dynamodb_table" "users" {
  name           = "Users"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  
  attribute {
    name = "id"
    type = "N"
  }
}

resource "aws_dynamodb_table" "pedidos" {
  name           = "Pedidos"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  
  attribute {
    name = "id"
    type = "N"
  }
}
```

### API Gateway (Terraform)
```hcl
resource "aws_api_gateway_rest_api" "logistics_api" {
  name = "logistics-api"
  description = "Logistics Platform API"
}

# JWT Authorizer
resource "aws_api_gateway_authorizer" "jwt_auth" {
  name                   = "jwt-authorizer"
  rest_api_id           = aws_api_gateway_rest_api.logistics_api.id
  authorizer_uri        = aws_lambda_function.auth_lambda.invoke_arn
  authorizer_credentials = aws_iam_role.api_gateway_auth_invocation_role.arn
  type                  = "TOKEN"
  identity_source       = "method.request.header.Authorization"
}

# Resources and Methods
resource "aws_api_gateway_resource" "auth" {
  rest_api_id = aws_api_gateway_rest_api.logistics_api.id
  parent_id   = aws_api_gateway_rest_api.logistics_api.root_resource_id
  path_part   = "auth"
}

resource "aws_api_gateway_resource" "login" {
  rest_api_id = aws_api_gateway_rest_api.logistics_api.id
  parent_id   = aws_api_gateway_resource.auth.id
  path_part   = "login"
}

resource "aws_api_gateway_method" "login_post" {
  rest_api_id   = aws_api_gateway_rest_api.logistics_api.id
  resource_id   = aws_api_gateway_resource.login.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "login_lambda" {
  rest_api_id = aws_api_gateway_rest_api.logistics_api.id
  resource_id = aws_api_gateway_method.login_post.resource_id
  http_method = aws_api_gateway_method.login_post.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.login_lambda.invoke_arn
}

# Pedidos Resource
resource "aws_api_gateway_resource" "pedidos" {
  rest_api_id = aws_api_gateway_rest_api.logistics_api.id
  parent_id   = aws_api_gateway_rest_api.logistics_api.root_resource_id
  path_part   = "pedidos"
}

resource "aws_api_gateway_method" "pedidos_get" {
  rest_api_id   = aws_api_gateway_rest_api.logistics_api.id
  resource_id   = aws_api_gateway_resource.pedidos.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.jwt_auth.id
}

resource "aws_api_gateway_integration" "pedidos_lambda" {
  rest_api_id = aws_api_gateway_rest_api.logistics_api.id
  resource_id = aws_api_gateway_method.pedidos_get.resource_id
  http_method = aws_api_gateway_method.pedidos_get.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.pedidos_lambda.invoke_arn
}

# Deploy
resource "aws_api_gateway_deployment" "prod" {
  rest_api_id = aws_api_gateway_rest_api.logistics_api.id
  stage_name  = "prod"
  
  depends_on = [
    aws_api_gateway_method.login_post,
    aws_api_gateway_method.pedidos_get,
    aws_api_gateway_integration.login_lambda,
    aws_api_gateway_integration.pedidos_lambda,
  ]
}

# CORS
resource "aws_api_gateway_method" "options" {
  for_each = toset([
    aws_api_gateway_resource.login.id,
    aws_api_gateway_resource.pedidos.id
  ])
  
  rest_api_id   = aws_api_gateway_rest_api.logistics_api.id
  resource_id   = each.value
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options" {
  for_each = aws_api_gateway_method.options
  
  rest_api_id = aws_api_gateway_rest_api.logistics_api.id
  resource_id = each.value.resource_id
  http_method = each.value.http_method
  type        = "MOCK"
  
  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_method_response" "options" {
  for_each = aws_api_gateway_method.options
  
  rest_api_id = aws_api_gateway_rest_api.logistics_api.id
  resource_id = each.value.resource_id
  http_method = each.value.http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}
```

### Configuração Completa API Gateway

**Estrutura de Rotas:**
```
/prod/api/
├── auth/
│   ├── login (POST) → login-lambda
│   ├── registro/cliente (POST) → register-cliente-lambda  
│   ├── registro/motorista (POST) → register-motorista-lambda
│   └── registro/operador (POST) → register-operador-lambda
├── pedidos/
│   ├── (GET) → list-pedidos-lambda
│   ├── (POST) → create-pedido-lambda
│   ├── {id} (GET) → get-pedido-lambda
│   ├── {id}/cancelar (PATCH) → cancel-pedido-lambda
│   ├── {id}/aceitar (POST) → accept-pedido-lambda
│   └── {id}/status (POST) → update-status-lambda
├── rastreamento/
│   ├── pedido/{id} (GET) → get-location-lambda
│   ├── historico/{id} (GET) → get-history-lambda
│   ├── localizacao (POST) → update-location-lambda
│   └── estatisticas/motorista/{id} (GET) → stats-lambda
└── notificacoes/
    ├── destinatario/{id} (GET) → get-notifications-lambda
    ├── {id}/marcar-lida (PATCH) → mark-read-lambda
    └── preferencias (POST) → update-prefs-lambda
```

**Authorizer Lambda (JWT):**
```python
import json
import jwt

def handler(event, context):
    token = event['authorizationToken'].replace('Bearer ', '')
    
    try:
        # Verificar JWT
        payload = jwt.decode(token, 'your-secret-key', algorithms=['HS256'])
        
        # Retornar policy do IAM
        return {
            'principalId': payload['user_id'],
            'policyDocument': {
                'Version': '2012-10-17',
                'Statement': [
                    {
                        'Action': 'execute-api:Invoke',
                        'Effect': 'Allow',
                        'Resource': event['methodArn']
                    }
                ]
            },
            'context': {
                'user_id': payload['user_id'],
                'user_type': payload['type'],
                'email': payload['email']
            }
        }
    except:
        raise Exception('Unauthorized')
```

## Plano de Migração (4 Fases)

### Fase 1: Setup Infraestrutura (1 semana)
- [ ] Criar DynamoDB tables
- [ ] Setup API Gateway
- [ ] CI/CD pipeline
- [ ] Monitoring básico

### Fase 2: Auth + Usuarios (1 semana)
- [ ] Lambda Auth com container
- [ ] Lambda Usuarios
- [ ] Testes com Flutter
- [ ] Deploy staging

### Fase 3: Pedidos + Rastreamento (2 semanas)
- [ ] Lambda Pedidos
- [ ] Lambda Rastreamento
- [ ] Integração SQS
- [ ] Testes end-to-end

### Fase 4: Notificações + Go-Live (1 semana)
- [ ] Lambda Notificações
- [ ] SNS + SES setup
- [ ] Cutover produção
- [ ] Descomissionamento Java

## Deploy e CI/CD

### GitHub Actions
```yaml
name: Deploy Lambda Functions

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build and Push Docker Images
        run: |
          for service in auth usuarios pedidos rastreamento notificacoes; do
            docker build -t logistics-$service ./functions/$service/
            docker tag logistics-$service:latest $ECR_REGISTRY/logistics-$service:latest
            docker push $ECR_REGISTRY/logistics-$service:latest
          done
      
      - name: Update Lambda Functions
        run: |
          aws lambda update-function-code \
            --function-name logistics-auth \
            --image-uri $ECR_REGISTRY/logistics-auth:latest
```

## Custos Estimados

### Atual (Java + Containers)
- **Infraestrutura**: $300/mês
- **Manutenção**: Alto

### AWS Serverless
- **Lambda**: $50/mês
- **API Gateway**: $35/mês  
- **DynamoDB**: $30/mês
- **SQS/SNS**: $10/mês
- **Total**: $125/mês

**Economia**: 58% de redução

## Critérios de Sucesso

- [ ] Flutter funciona sem alterações (exceto URL)
- [ ] Mesma performance ou melhor
- [ ] Zero downtime na migração
- [ ] Redução de custos > 50%
- [ ] Facilidade de manutenção

## Próximos Passos

1. **Esta Semana**: Setup AWS + primeiro Lambda
2. **Próxima Semana**: Auth funcionando
3. **Próximas 2 Semanas**: Todos os serviços
4. **Go-Live**: Migração completa

---
**Status**: 🟡 Aguardando aprovação
