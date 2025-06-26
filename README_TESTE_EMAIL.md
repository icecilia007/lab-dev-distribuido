# 📧 Teste de Envio de Email de Entrega

Este sistema envia automaticamente um email quando uma entrega é finalizada, utilizando o fluxo:
**Docker → SQS → Lambda → SES → Email**

## 🚀 Como Usar

### 1️⃣ Verificar Credenciais AWS
```bash
./verificar_aws.sh
```

### 2️⃣ Configurar Credenciais (se necessário)
```bash
./configurar_aws.sh
```

### 3️⃣ Reiniciar Serviço de Notificação
```bash
docker-compose up -d notificacao-service
```

### 4️⃣ Executar Teste Completo
```bash
./teste_email_completo.sh
```

## 📋 O que o Teste Faz

1. **Cria cliente** com email `arihenriquedev@hotmail.com`
2. **Cria motorista** de teste
3. **Simula corrida completa:**
   - Criação do pedido
   - Aceitação pelo motorista
   - Deslocamento para coleta
   - Confirmação de coleta
   - Deslocamento para destino (EM_MOVIMENTO)
   - **Finalização da entrega** → **Dispara email**

## 🔧 Configuração Técnica

### Docker Compose
- Container monta `~/.aws:/root/.aws:ro` (somente leitura)
- Credenciais AWS são lidas automaticamente do host

### Fluxo de Email
1. `RastreamentoServiceImpl.confirmarEntregaPedido()` → Status `ENTREGUE`
2. `EventoConsumer` detecta evento `STATUS_ATUALIZADO` 
3. `enviarEmailEntrega()` → `EmailService.enviarEmail()`
4. Mensagem enviada para **SQS**
5. **Lambda** processa e envia via **SES**
6. Email chega em `arihenriquedev@hotmail.com`

## 🔍 Debug

### Verificar Logs
```bash
docker logs notificacao-service | grep -i entregue
```

### Verificar Status do Pedido
```bash
curl -X GET "http://localhost:8000/api/pedidos/{PEDIDO_ID}" -H "Authorization: Bearer {TOKEN}"
```

### Verificar Fila SQS
```bash
aws sqs receive-message --queue-url https://sqs.us-east-1.amazonaws.com/176343551411/email-notifications
```

## ✅ Pontos de Verificação

- [ ] Credenciais AWS configuradas em `~/.aws/`
- [ ] Container reiniciado após configuração
- [ ] Status do pedido mudou para `ENTREGUE`
- [ ] Logs mostram "Status é ENTREGUE, enviando email de entrega"
- [ ] Nenhum erro de credenciais AWS nos logs
- [ ] Email recebido em `arihenriquedev@hotmail.com`

## 🎯 Requisitos para Funcionar

1. **Credenciais AWS válidas** com acesso ao SQS
2. **Fila SQS** configurada e acessível
3. **Lambda** configurada para processar mensagens da fila
4. **SES** configurado para envio de emails
5. **Email de destino** verificado no SES (se em sandbox)

---
*Sistema de Logística - Teste de Email de Entrega* 📦✉️