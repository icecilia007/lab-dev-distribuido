# API Gateway - Sistema de Logística

O API Gateway é um componente central do sistema de logística, responsável por gerenciar e direcionar todas as requisições entre os diferentes microsserviços da plataforma.

## Funcionalidades Principais

### 1. Roteamento e Balanceamento de Carga
- Direcionamento inteligente de requisições para os microsserviços apropriados
- Balanceamento de carga entre instâncias dos serviços
- Gerenciamento de rotas dinâmicas para diferentes endpoints

### 2. Segurança e Autenticação
- Implementação de autenticação JWT (JSON Web Tokens)
- Validação de tokens e controle de acesso
- Proteção contra ataques comuns (CSRF, XSS)
- Gerenciamento de sessões e autorizações
- Endpoints de autenticação:
  - `/api/auth/login` - Login de usuários
  - `/api/auth/registro/cliente` - Registro de novos clientes
  - `/api/auth/registro/motorista` - Registro de novos motoristas
  - `/api/auth/registro/operador` - Registro de novos operadores logísticos

### 3. Documentação da API
- Integração com OpenAPI/Swagger para documentação automática
- Interface interativa para teste de endpoints
- Documentação detalhada de todos os serviços disponíveis

### 4. Monitoramento e Resiliência
- Circuit breaker para falhas de serviços
- Timeout e retry policies
- Métricas de performance e disponibilidade
- Logging centralizado de requisições
- Endpoints de fallback para serviços indisponíveis:
  - `/fallback/usuario` - Fallback para serviço de usuários
  - `/fallback/pedido` - Fallback para serviço de pedidos
  - `/fallback/rastreamento` - Fallback para serviço de rastreamento
  - `/fallback/notificacao` - Fallback para serviço de notificações

### 5. Transformação de Dados
- Transformação de payloads entre serviços
- Validação de dados de entrada
- Normalização de respostas

### 6. Filtros e Middleware
O API Gateway implementa uma série de filtros para garantir a segurança, performance e monitoramento:

#### Filtros de Segurança
- **JwtAuthenticationFilter**: 
  - Validação de tokens JWT
  - Extração de claims e roles
  - Adição de headers de autenticação
  - Suporte a caminhos públicos

#### Filtros de Performance
- **SimpleCacheFilter**:
  - Cache em memória para respostas GET
  - TTL configurável (padrão: 1 minuto)
  - Cache por URL
  - Otimização de respostas frequentes

#### Filtros de Rate Limiting
- **InMemoryRateLimiter**:
  - Limitação de requisições por IP
  - Implementação do algoritmo Token Bucket
  - Capacidade configurável (padrão: 100 tokens)
  - Taxa de reposição ajustável

#### Filtros de Monitoramento
- **LoggingFilter**: Registro detalhado de requisições
- **RequestLoggingFilter**: Log de informações da requisição
- **ResponseTimeFilter**: Medição de tempo de resposta
- **SecretHeaderFilter**: Validação de headers internos

## Integração com Microsserviços

O API Gateway se integra com os seguintes microsserviços:

- **Microsserviço de Pedidos**: Gerenciamento do ciclo de vida dos pedidos
- **Microsserviço de Usuários**: Autenticação e gestão de usuários
- **Microsserviço de Rastreamento**: Monitoramento em tempo real
- **Sistema de Mensageria**: Comunicação assíncrona via RabbitMQ

## Tecnologias Utilizadas

- Spring Cloud Gateway
- Spring Security
- Spring WebFlux
- JWT para autenticação
- OpenAPI/Swagger para documentação
- Java 21

## Configuração e Execução

### Pré-requisitos
- Java 21
- Maven
- Docker (opcional)

### Executando Localmente
1. Clone o repositório
2. Execute `mvn clean install`
3. Inicie a aplicação com `mvn spring-boot:run`

### Executando com Docker
1. Construa a imagem: `docker build -t api-gateway .`
2. Execute o container: `docker run -p 8080:8080 api-gateway`

## Endpoints Principais

### Autenticação e Registro
- `/api/auth/login` - Login de usuários
- `/api/auth/registro/cliente` - Registro de clientes
- `/api/auth/registro/motorista` - Registro de motoristas
- `/api/auth/registro/operador` - Registro de operadores

### Serviços
- `/api/pedidos/*` - Rotas para o microsserviço de pedidos
- `/api/usuarios/*` - Rotas para o microsserviço de usuários
- `/api/rastreamento/*` - Rotas para o microsserviço de rastreamento

### Fallback
- `/fallback/*` - Endpoints de fallback para serviços indisponíveis

### Documentação
- `/swagger-ui.html` - Documentação da API

## Contribuição

Para contribuir com o projeto:
1. Faça um fork do repositório
2. Crie uma branch para sua feature
3. Faça commit das mudanças
4. Envie um pull request

## Licença

Este projeto está sob a licença MIT. 