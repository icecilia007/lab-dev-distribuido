# Detalhamento dos Requisitos do Trabalho sobre Microsserviços (30 pontos)

## Índice

- [Serviço de Pedidos](#serviço-de-pedidos)
- [Serviço de Rastreamento](#serviço-de-rastreamento)
- [Serviço de Notificações](#serviço-de-notificações)
- [API Gateway](#api-gateway)
- [Arquitetura de Referência (Simplificada)](#arquitetura-de-referência-simplificada)
- [Dicas para Implementação](#dicas-para-implementação)
- [Avaliação Prática](#avaliação-prática)

## Serviço de Pedidos

### CRUD de pedidos

- **Objetivo**: Criar uma API REST para gerenciar o ciclo de vida completo dos pedidos.
- **Funcionalidades principais**:
  - Criar novos pedidos com informações básicas (origem, destino, cliente, tipo de mercadoria)
  - Consultar pedidos por ID, cliente ou status
  - Atualizar status do pedido (em processamento, em rota, entregue, etc.)
  - Cancelar/remover pedidos
- **Tecnologia sugerida**: Spring Boot ou Express.js com um banco de dados relacional como PostgreSQL

### Cálculo de rotas otimizadas

- **Objetivo**: Integrar com uma API externa de mapas para calcular a melhor rota entre pontos de coleta e entrega.
- **Funcionamento básico**:
  - Receber pontos de origem e destino
  - Fazer requisição para a API externa (OpenStreetMap, Mapbox ou similar)
  - Retornar a rota otimizada, distância e tempo estimado
- **Dica de implementação**: Comece com uma API gratuita como o OSRM (Open Source Routing Machine) para desenvolvimento

## Serviço de Rastreamento

### Atualização e consulta de localização em tempo real com gRPC

- **Objetivo**: Criar um serviço que permita atualizações eficientes da localização dos veículos e consultas em tempo real.
- **Funcionalidades principais**:
  - Definir arquivos .proto para os serviços e mensagens
  - Implementar endpoint para motoristas enviarem atualizações de localização (latitude, longitude, timestamp)
  - Implementar endpoint para clientes consultarem a localização atual de sua entrega
- **Tecnologia sugerida**: gRPC com implementação em Java, Node ou Go

### Integração com sistema de geolocalização

- **Objetivo**: Armazenar e processar dados de localização para uso em consultas e análises.
- **Funcionamento básico**:
  - Armazenar coordenadas geográficas com timestamps
  - Implementar consultas simples como "encontrar entregas próximas"
  - Calcular distâncias entre pontos
- **Dica de implementação**: Use um banco que suporte operações geoespaciais como MongoDB ou PostgreSQL com extensão PostGIS

## Serviço de Notificações

### Envio de notificações push

- **Objetivo**: Notificar clientes e motoristas sobre eventos relevantes.
- **Tipos de notificações**:
  - Para clientes: status da entrega, atrasos, chegada iminente
  - Para motoristas: novos pedidos, alterações de rota, instruções especiais
- **Tecnologia sugerida**: Firebase Cloud Messaging (FCM) para notificações móveis ou WebSockets para notificações web

### Implementação de filas de mensagens com RabbitMQ

- **Objetivo**: Garantir a entrega confiável de mensagens entre os serviços.
- **Funcionamento básico**:
  - Configurar exchange e filas básicas
  - Implementar padrão de produtor/consumidor
  - Definir filas para diferentes tipos de eventos (ex: atualização de status, localização)
- **Dica de implementação**: Comece com uma configuração simples do RabbitMQ e adicione recursos como dead-letter queues apenas se necessário

## API Gateway

### Roteamento de requisições

- **Objetivo**: Criar um ponto de entrada único que direciona requisições para os microsserviços apropriados.
- **Funcionamento básico**:
  - Mapear rotas de API para os serviços internos (/pedidos, /rastreamento, /notificacoes)
  - Lidar com autenticação e autorização (JWT)
  - Gerenciar logs de requisições
- **Tecnologia sugerida**: Spring Cloud Gateway, Kong Gateway (versão gratuita) ou implementação simples com Express.js

### Implementação de rate limiting e caching

- **Objetivo**: Proteger os serviços contra sobrecarga e melhorar o desempenho.
- **Funcionamento básico**:
  - Implementar limitação de requisições por usuário/IP (ex: 100 requisições/minuto)
  - Armazenar em cache respostas para consultas frequentes (ex: status de pedidos)
  - Definir políticas de expiração de cache
- **Dica de implementação**: Use Redis para armazenar dados de rate limiting e cache

## Arquitetura de Referência (Simplificada)

```text
                    Cliente/App Móvel
                           │
                           ▼
┌─────────────────────────────────────────────────────┐
│                    API Gateway                      │
│   Autenticação, Roteamento, Rate Limiting, Cache    │ 
└─────┬──────────────────┬──────────────────────┬─────┘
      ▼                  ▼                      ▼
┌──────────┐      ┌─────────────┐       ┌─────────────┐
│ Serviço  │      │   Serviço   │       │ Serviço     │
│ Pedidos  │      │Rastreamento │       │Notificacação│
└──────────┘      └─────────────┘       └─────────────┘  

```

## Dicas para Implementação

1. **Comece simples**: Implemente primeiro uma versão básica de cada serviço antes de adicionar recursos avançados.

2. **Documente as APIs**: Use Swagger/OpenAPI para documentar os endpoints de cada serviço.

3. **Comunicação entre serviços**:
    - Síncrona: REST para operações simples
    - Assíncrona: RabbitMQ para eventos e operações de longa duração
    -
4. **Teste local**: Crie scripts para executar todo o sistema localmente.

## Avaliação Prática

O trabalho será avaliado considerando:

1. **Funcionalidade básica**: Cada serviço deve implementar as funcionalidades essenciais descritas.

2. **Integração**: Os serviços devem se comunicar corretamente entre si.

3. **Resiliência**: O sistema deve lidar adequadamente com falhas temporárias (retry, circuit breaker).

4. **Documentação**: Cada serviço deve ter sua API documentada e instruções de execução.

---
