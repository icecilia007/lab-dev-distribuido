# Sistema de Logística Distribuída

Sistema distribuído de logística com microserviços em Java Spring Boot, API Gateway, notificações via Lambda e comunicação por mensageria RabbitMQ.

## 🏗️ Arquitetura do Sistema

### Microserviços
- **API Gateway** (porta 8000) - Roteamento e autenticação JWT
- **Usuário Service** (porta 8080) - Gestão de usuários, clientes e motoristas
- **Pedidos Service** (porta 8081) - Criação e gestão de pedidos
- **Rastreamento Service** (porta 8082) - Localização e movimentação
- **Notificação Service** (porta 8083) - Sistema de notificações

### Infraestrutura
- **PostgreSQL** (porta 5432) - Banco de dados compartilhado
- **RabbitMQ** (porta 5672/15672) - Message broker para eventos
- **Lambda Simulator** (porta 9000) - Simula AWS Lambda para notificações
- **Lambda Webhook** - Conector RabbitMQ → Lambda

## 🚀 Como Iniciar o Sistema

### Pré-requisitos
- Docker
- Docker Compose
- Git

### Início Rápido
```bash
# 1. Clone o repositório
git clone <url-do-repositorio>
cd lab-dev-distribuido

# 2. Construir e iniciar todos os serviços
docker compose up -d --build

# 3. Aguardar inicialização (2-3 minutos)
# Verificar se todos os containers estão rodando
docker ps

# 4. Executar teste completo do sistema
./test-sistema.sh
```

### Verificação de Status
```bash
# Ver logs de todos os serviços
docker compose logs -f

# Ver logs de um serviço específico
docker logs <container-name>

# Verificar saúde dos serviços
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

## 🧪 Como Testar o Sistema

### Teste Automatizado Completo
```bash
./test-sistema.sh
```

Este script executa o fluxo completo:
1. Cadastro de cliente
2. Cadastro de motorista
3. Login e autenticação
4. Definição de localização inicial
5. Criação de pedido
6. Aceitação do pedido pelo motorista
7. Simulação de movimento até coleta
8. Confirmação de coleta
9. Simulação de movimento até entrega
10. Confirmação de entrega
11. Verificação de status final

### Verificação das Notificações Lambda
```bash
# Ver logs do Lambda Simulator
docker logs lambda-simulator

# Ver logs do Lambda Webhook
docker logs lambda-webhook

# Acessar RabbitMQ Management (guest/guest)
http://localhost:15672
```

### Testes Manuais via API
```bash
# Exemplo: Registrar cliente
curl -X POST http://localhost:8000/api/auth/registro/cliente \
  -H "Content-Type: application/json" \
  -H "X-Internal-Auth: 2BE2AB6217329B86A427A3819B626" \
  -d '{
    "nome": "João Silva",
    "email": "joao@exemplo.com",
    "senha": "senha123",
    "telefone": "11999998888"
  }'
```

## 🗑️ Como Limpar/Destruir o Sistema

### Parar Serviços (mantém dados)
```bash
docker compose down
```

### Limpeza Completa (remove tudo)
```bash
# Script de limpeza total - remove TUDO do Docker
./limpar-docker.sh

# Ou manualmente:
docker compose down -v --rmi all
docker system prune -a --volumes --force
```

**⚠️ ATENÇÃO**: O script `limpar-docker.sh` remove **TODAS** as imagens, containers, volumes e redes do Docker, não apenas deste projeto.

### Limpeza Seletiva (apenas este projeto)
```bash
# Parar e remover containers + volumes deste projeto
docker compose down -v

# Remover imagens deste projeto
docker rmi $(docker images | grep "lab-dev-distribuido" | awk '{print $3}')
```

## 🔧 Modificações Realizadas nas Aplicações Java

### 1. API Gateway
**Arquivo**: `api-gatway/src/main/java/com/logistica/apigateway/controller/AuthController.java`

**Modificações**:
- Substituição de URLs hardcoded por variáveis de ambiente
- Adição do parâmetro `@Value("${services.usuario.url}")` 
- Atualização de todas as chamadas para usar `usuarioServiceUrl` em vez de `localhost:8080`

**Antes**:
```java
.uri("http://localhost:8080/api/auth/registro/cliente")
```

**Depois**:
```java
@Value("${services.usuario.url}")
private String usuarioServiceUrl;

.uri(usuarioServiceUrl + "/api/auth/registro/cliente")
```

### 2. Configuração do Docker Compose
**Arquivo**: `docker-compose.yml`

**Modificações**:
- Configuração de variáveis de ambiente para todos os serviços
- Definição de rede Docker personalizada (`logistica-network`)
- Configuração de health checks para PostgreSQL e RabbitMQ
- Mapeamento de dependências entre serviços
- Configuração do Lambda Simulator e Webhook

**Variáveis de ambiente adicionadas**:
```yaml
environment:
  - SERVICES_AUTH_URL=http://usuario-service:8080
  - SERVICES_USUARIO_URL=http://usuario-service:8080
  - SERVICES_PEDIDO_URL=http://pedidos-service:8081
  - SERVICES_RASTREAMENTO_URL=http://rastreamento-service:8082
  - SERVICES_NOTIFICACAO_URL=http://notificacao-service:8083
```

### 3. Sistema de Notificações Lambda
**Arquivos**: `lambda/main.py`, `lambda/webhook.py`

**Implementação**:
- Lambda que replica exatamente o comportamento do `EventoConsumer` Java
- Processamento de eventos com mesma estrutura: `evento`, `origem`, `dados`
- Geração de conteúdo de notificação idêntica ao sistema Java
- Salvamento direto no banco PostgreSQL com schema compatível
- Webhook para consumir mensagens do RabbitMQ e enviar para Lambda

### 4. Configuração de Aplicações
**Arquivos de configuração atualizados**:
- `api-gatway/src/main/resources/application.yml`
- `usuario/src/main/resources/application.yml`
- `pedidos/src/main/resources/application.yml`
- `rastreamento/src/main/resources/application.yml`
- `notificacao/src/main/resources/application.yml`

**Modificações**:
- URLs de serviços usando nomes de containers Docker
- Configuração de RabbitMQ com hostname `rabbitmq`
- Configuração de PostgreSQL com hostname `postgres`
- Configuração de environment variables para flexibilidade

## 🌐 Endpoints Principais

### Autenticação
- `POST /api/auth/registro/cliente` - Registrar cliente
- `POST /api/auth/registro/motorista` - Registrar motorista
- `POST /api/auth/login` - Login (retorna JWT no header)

### Usuários
- `GET /api/usuarios/clientes/{id}` - Buscar cliente
- `GET /api/usuarios/motoristas/{id}` - Buscar motorista

### Pedidos
- `POST /api/pedidos` - Criar pedido
- `POST /api/pedidos/{id}/aceitar` - Aceitar pedido
- `GET /api/pedidos/{id}` - Consultar pedido

### Rastreamento
- `POST /api/rastreamento/localizacao` - Atualizar localização
- `POST /api/rastreamento/pedido/{id}/coleta` - Confirmar coleta
- `POST /api/rastreamento/pedido/{id}/entrega` - Confirmar entrega
- `GET /api/rastreamento/pedido/{id}` - Consultar localização

## 🔐 Autenticação

O sistema utiliza:
- **Header interno**: `X-Internal-Auth: 2BE2AB6217329B86A427A3819B626`
- **JWT Token**: Obtido via login, enviado no header `Authorization: Bearer <token>`

## 📊 Monitoramento

### RabbitMQ Management
- URL: http://localhost:15672
- Usuário: `guest`
- Senha: `guest`

### Logs dos Serviços
```bash
# Ver todos os logs
docker compose logs -f

# Ver logs específicos
docker logs usuario-service
docker logs pedidos-service
docker logs rastreamento-service
docker logs notificacao-service
docker logs api-gateway
docker logs lambda-simulator
docker logs lambda-webhook
```

## 🔧 Como Funciona a Pasta Lambda

A pasta `lambda/` contém a implementação de funções AWS Lambda que processam eventos de notificação, replicando exatamente o comportamento do sistema Java.

### Estrutura da Pasta Lambda
```
lambda/
├── main.py                 # Função Lambda principal
├── webhook.py              # Webhook RabbitMQ → Lambda
├── requirements.txt        # Dependências Python para Lambda
├── requirements-webhook.txt # Dependências Python para Webhook
├── Dockerfile             # Container Lambda Simulator
└── Dockerfile.webhook     # Container Lambda Webhook
```

### Arquitetura de Funcionamento

```mermaid
graph LR
    subgraph "Microserviços Java"
        A[Usuario Service<br/>:8080]
        B[Pedidos Service<br/>:8081]
        C[Rastreamento Service<br/>:8082]
        D[Notificação Service<br/>:8083]
    end
    
    subgraph "Message Broker"
        E[RabbitMQ<br/>:5672/15672]
        F[Queue: lambda.webhook]
    end
    
    subgraph "Lambda Environment"
        G[Lambda Webhook<br/>webhook.py]
        H[Lambda Simulator<br/>:9000]
    end
    
    subgraph "Storage"
        I[PostgreSQL<br/>:5432]
    end
    
    A --> E
    B --> E
    C --> E
    D --> E
    
    E --> F
    F --> G
    G -->|HTTP POST<br/>/invocations| H
    H -->|INSERT notificacoes| I
    
    style A fill:#e1f5fe
    style B fill:#e1f5fe
    style C fill:#e1f5fe
    style D fill:#e1f5fe
    style E fill:#fff3e0
    style F fill:#fff3e0
    style G fill:#e8f5e8
    style H fill:#e8f5e8
    style I fill:#fce4ec
```

### 1. main.py - Função Lambda Principal

**Função**: Processa eventos e cria notificações no banco de dados

**Características**:
- **Replica 100% do EventoConsumer Java**: Mesma lógica de processamento
- **Compatibilidade total**: Usa mesma estrutura de dados (`evento`, `origem`, `dados`)
- **Banco de dados**: Salva diretamente na tabela `notificacoes` do PostgreSQL
- **Tipos de evento suportados**:
  - `PEDIDO_CRIADO`
  - `STATUS_ATUALIZADO` 
  - `PEDIDO_DISPONIVEL`
  - `STATUS_VEICULO_ALTERADO`
  - `PEDIDO_CANCELADO`

**Principais métodos**:
```python
def processar_evento(mensagem):
    """Método principal - idêntico ao Java processarEvento"""
    
def gerar_conteudo_notificacao(tipo_evento, dados):
    """Gera conteúdo - idêntico ao Java gerarConteudoNotificacao"""
    
def criar_notificacao(destinatario_id, tipo_evento, origem, dados):
    """Cria notificação - idêntico ao Java criarNotificacao"""
```

### 2. webhook.py - Conector RabbitMQ → Lambda

**Função**: Consome mensagens do RabbitMQ e envia para o Lambda

**Características**:
- **Conecta automaticamente** ao RabbitMQ na inicialização
- **Escuta fila**: `lambda.webhook` (recebe TODOS os eventos)
- **Formato AWS**: Converte mensagens para formato AWS Lambda RabbitMQ
- **Retry automático**: Rejeita e reprocessa mensagens em caso de erro
- **Logs detalhados**: Para debugging e monitoramento

**Fluxo de funcionamento**:
1. Conecta ao RabbitMQ (`rabbitmq:5672`)
2. Escuta a fila `lambda.webhook`
3. Converte mensagem para formato AWS Lambda
4. Envia HTTP POST para Lambda Simulator
5. Confirma processamento (ACK) ou rejeita (NACK)

### 3. Containers Docker

#### Lambda Simulator (Dockerfile)
- **Base**: `public.ecr.aws/lambda/python:3.12`
- **Porta**: 9000 (mapeada para 8080 interno)
- **Endpoint**: `/2015-03-31/functions/function/invocations`
- **Runtime**: AWS Lambda Python Runtime
- **Conectividade**: Acesso direto ao PostgreSQL

#### Lambda Webhook (Dockerfile.webhook)  
- **Base**: `python:3.12-slim`
- **Função**: Daemon que roda continuamente
- **Conectividade**: RabbitMQ + Lambda Simulator
- **Auto-restart**: `unless-stopped`

### 4. Configuração e Variáveis de Ambiente

#### Lambda Simulator
```yaml
environment:
  - NOTIFICACOES_URL=http://notificacao-service:8083
  - DB_HOST=postgres
  - DB_PORT=5432
  - DB_NAME=main_db
  - DB_USER=postgres
  - DB_PASSWORD=postgres
```

#### Lambda Webhook
```yaml
environment:
  - RABBITMQ_URL=amqp://guest:guest@rabbitmq:5672/
  - LAMBDA_URL=http://lambda-simulator:8080/2015-03-31/functions/function/invocations
  - QUEUE_NAME=lambda.webhook
```

### 5. Fluxo Completo de Eventos

```mermaid
sequenceDiagram
    participant JS as Java Service<br/>(Pedidos)
    participant RMQ as RabbitMQ
    participant LW as Lambda Webhook
    participant LS as Lambda Simulator
    participant DB as PostgreSQL

    Note over JS: Evento ocorre<br/>(ex: pedido criado)
    
    JS->>RMQ: Publica evento JSON
    Note over RMQ: {<br/>"evento": "PEDIDO_CRIADO",<br/>"origem": "PEDIDOS_SERVICE",<br/>"dados": {...}<br/>}
    
    RMQ->>LW: Entrega para fila<br/>lambda.webhook
    
    Note over LW: Converte para<br/>formato AWS Lambda
    
    LW->>LS: HTTP POST /invocations
    Note over LW,LS: AWS Lambda format:<br/>Records[].rmqMessagesByQueue
    
    Note over LS: 1. Extrai evento<br/>2. Identifica destinatários<br/>3. Gera conteúdo<br/>4. Processa notificação
    
    LS->>DB: INSERT INTO notificacoes
    Note over DB: Notificação salva:<br/>- tipo_evento<br/>- destinatario_id<br/>- titulo/mensagem<br/>- dados_evento
    
    LS->>LW: Response 200 OK
    LW->>RMQ: ACK (confirma processamento)
```

#### Exemplo Prático de Evento

1. **Microserviço Java** publica evento no RabbitMQ
   ```json
   {
     "evento": "PEDIDO_CRIADO",
     "origem": "PEDIDOS_SERVICE", 
     "dados": {
       "pedidoId": 1,
       "clienteId": 1,
       "origemLatitude": "52.516677"
     }
   }
   ```

2. **RabbitMQ** roteia para fila `lambda.webhook`

3. **Lambda Webhook** consome e converte para formato AWS:
   ```json
   {
     "Records": [{
       "eventSource": "aws:rmq",
       "rmqMessagesByQueue": {
         "lambda.webhook::/": [{
           "data": "{evento JSON}",
           "basicProperties": {...}
         }]
       }
     }]
   }
   ```

4. **Lambda Simulator** processa evento:
   - Extrai dados do evento
   - Determina destinatários (clienteId, motoristaId)
   - Gera conteúdo da notificação
   - Salva no PostgreSQL

5. **Resultado** armazenado na tabela `notificacoes`:
   ```sql
   INSERT INTO notificacoes (
     tipo_evento, origem, destinatario_id, 
     titulo, mensagem, data_criacao, status, dados_evento
   ) VALUES (
     'PEDIDO_CRIADO', 'PEDIDOS_SERVICE', 1,
     'Novo pedido criado', 'Seu pedido foi registrado com sucesso!',
     NOW(), 'NAO_LIDA', '{"evento": "PEDIDO_CRIADO", ...}'
   );
   ```

### 6. Monitoramento e Debug

#### Logs Lambda Simulator
```bash
docker logs lambda-simulator
```
Mostra:
- Eventos recebidos
- Processamento detalhado
- Notificações criadas
- Erros de processamento

#### Logs Lambda Webhook
```bash
docker logs lambda-webhook
```
Mostra:
- Conexão com RabbitMQ
- Mensagens consumidas
- Comunicação com Lambda
- Status de processamento

#### Verificação no Banco
```sql
-- Ver notificações criadas
SELECT * FROM notificacoes ORDER BY data_criacao DESC;

-- Contar por tipo de evento
SELECT tipo_evento, COUNT(*) FROM notificacoes GROUP BY tipo_evento;
```

### 7. Vantagens da Implementação

1. **Compatibilidade 100%**: Lambda replica exatamente o comportamento Java
2. **Escalabilidade**: Lambda processa eventos de forma independente  
3. **Resiliência**: Webhook com retry automático
4. **Observabilidade**: Logs detalhados para debugging
5. **Flexibilidade**: Fácil adição de novos tipos de evento
6. **Testabilidade**: Ambiente local que simula AWS Lambda

## 🛠️ Desenvolvimento

### Estrutura do Projeto
```
lab-dev-distribuido/
├── api-gatway/          # API Gateway Spring Cloud
├── usuario/             # Microserviço de usuários
├── pedidos/             # Microserviço de pedidos
├── rastreamento/        # Microserviço de rastreamento
├── notificacao/         # Microserviço de notificações
├── lambda/              # Funções Lambda Python (detalhado acima)
├── infra/rabbitmq/      # Configuração RabbitMQ
├── docker-compose.yml   # Orquestração dos serviços
├── test-sistema.sh      # Script de teste automatizado
├── limpar-docker.sh     # Script de limpeza
└── README.md           # Esta documentação
```

### Modificar e Rebuildar
```bash
# Rebuild apenas um serviço
docker compose up -d --build <service-name>

# Rebuild tudo
docker compose up -d --build
```

## 🔧 Solução de Problemas

### Serviços não iniciam
```bash
# Verificar logs
docker compose logs

# Verificar se PostgreSQL está rodando
docker logs postgres-db

# Verificar se RabbitMQ está rodando
docker logs rabbitmq
```

### Problemas de rede
```bash
# Verificar rede Docker
docker network ls
docker network inspect lab-dev-distribuido_logistica-network
```

### Limpar e reiniciar
```bash
# Limpeza completa e restart
./limpar-docker.sh
docker compose up -d --build
```

---

**Desenvolvido para demonstrar arquitetura de microserviços com Docker, Spring Boot, RabbitMQ e integração Lambda.**