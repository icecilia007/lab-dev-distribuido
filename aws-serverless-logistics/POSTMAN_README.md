# Postman Collection - AWS Serverless Logistics API

Esta collection contém todos os endpoints da API Gateway configurados atualmente no sistema.

## Arquivos Criados

- `postman-collection.json` - Collection principal com todas as requisições
- `postman-environment.json` - Environment com variáveis de ambiente
- `POSTMAN_README.md` - Este arquivo de instruções

## Como Importar no Postman

### 1. Importar a Collection
1. Abra o Postman
2. Clique em "Import" no canto superior esquerdo
3. Selecione o arquivo `postman-collection.json`
4. A collection "AWS Serverless Logistics API" será criada

### 2. Importar o Environment
1. No Postman, clique no ícone de engrenagem (Settings) no canto superior direito
2. Selecione "Manage Environments"
3. Clique em "Import" 
4. Selecione o arquivo `postman-environment.json`
5. Selecione o environment "AWS Serverless Logistics" na dropdown

## Como Usar

### 1. Fazer Login (OBRIGATÓRIO PRIMEIRO)
1. Vá para a pasta "Auth" → "Login"
2. Execute a requisição com credenciais válidas
3. O token JWT será automaticamente extraído e salvo na variável `authToken`
4. Todas as outras requisições usarão este token automaticamente

### 2. Testar Outros Endpoints
Após o login, você pode testar qualquer endpoint. Todos estão configurados para usar o token automaticamente.

## Estrutura da Collection

### 📁 Auth
- **Login** - Autentica usuário e obtém JWT token
- **Registro Cliente** - Registra novo cliente
- **Registro Motorista** - Registra novo motorista

### 📁 Pedidos
- **Criar Pedido** - Cria novo pedido de entrega
- **Consultar Pedido por ID** - Busca pedido específico
- **Listar Pedidos por Usuário** - Lista pedidos do cliente
- **Listar Pedidos por Motorista** - Lista pedidos do motorista
- **Aceitar Pedido** - Motorista aceita pedido
- **Cancelar Pedido** - Cancela pedido
- **Atualizar Status do Pedido** - Atualiza status durante entrega

### 📁 Notificações
- **Listar Notificações por Usuário** - Busca notificações do usuário

### 📁 Rastreamento
- **Rastrear Pedido** - Localização em tempo real do pedido
- **Rastrear Pedido com Motorista** - Inclui informações do motorista
- **Estatísticas do Motorista** - Dados estatísticos do motorista

### 📁 Incidentes
- **Criar Incidente** - Reporta problema durante entrega

## Variáveis de Ambiente

| Variável | Valor | Descrição |
|----------|-------|-----------|
| `baseUrl` | `https://tntpd380l5.execute-api.us-east-1.amazonaws.com/prod/api` | URL base da API |
| `authToken` | (automático) | Token JWT obtido no login |
| `userId` | `8516440892` | ID de usuário exemplo |
| `pedidoId` | `8860534895` | ID de pedido exemplo |
| `motoristaId` | `1234567890` | ID de motorista exemplo |

## Autenticação

- **Tipo**: Bearer Token (JWT)
- **Header**: `Authorization: Bearer <token>`
- **Configuração**: Automática após login
- **Duração**: 24 horas (configurado na Lambda)

## Exemplos de Uso

### 1. Fluxo Completo de Pedido
1. Login → Registro Cliente → Criar Pedido → Consultar Pedido
2. Login (como motorista) → Aceitar Pedido → Atualizar Status

### 2. Monitoramento
1. Login → Rastrear Pedido → Listar Notificações

### 3. Gestão de Problemas
1. Login → Criar Incidente → Cancelar Pedido (se necessário)

## Status Codes Esperados

- **200**: Sucesso (GET requests)
- **201**: Criado com sucesso (POST requests)
- **204**: Atualizado/deletado com sucesso (PATCH requests)
- **401**: Token inválido ou expirado
- **403**: Acesso negado (usuário tentando acessar dados de outro)
- **404**: Recurso não encontrado
- **500**: Erro interno do servidor

## Troubleshooting

### "Missing Authentication Token"
- Verifique se fez login primeiro
- Verifique se o token não expirou (24h)
- Re-execute o login para obter novo token

### "Acesso negado"
- Usuário tentando acessar dados de outro usuário
- Verifique se está usando o userId correto

### "Token inválido ou expirado"
- Token JWT expirou (24h)
- Execute login novamente

## Notas Importantes

1. **Sempre faça login primeiro** - O token é necessário para todas as requisições exceto auth
2. **Tokens expiram em 24h** - Faça login novamente quando necessário
3. **IDs são específicos** - Use IDs reais do seu banco de dados
4. **CORS está habilitado** - Pode ser usado em aplicações web
5. **Todas as senhas** nos exemplos são "123456" - Altere conforme necessário