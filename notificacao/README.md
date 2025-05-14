# Documentação Técnica: Serviço de Notificações

## Visão Geral

O Serviço de Notificações é um componente fundamental do sistema de logística, responsável pelo processamento de eventos e geração de notificações para clientes e motoristas. Implementado como um microsserviço independente, ele utiliza o RabbitMQ para comunicação assíncrona e armazena notificações em um banco de dados PostgreSQL.

## Funcionalidades Implementadas

### Processamento de Eventos
- **Consumo de mensagens**: O serviço escuta a fila `notificacoes.geral` no RabbitMQ, processando eventos de diversos tipos.
- **Identificação automática de destinatários**: Extrai IDs de clientes e motoristas dos dados do evento.
- **Geração de notificações**: Cria notificações personalizadas baseadas no tipo de evento recebido.

### Tipos de Eventos Suportados
- `PEDIDO_CRIADO`: Quando um novo pedido é registrado
- `STATUS_ATUALIZADO`: Quando o status de um pedido muda
- `PEDIDO_CANCELADO`: Quando um pedido é cancelado
- `PEDIDO_DISPONIVEL`: Quando há pedidos disponíveis para coleta
- `INCIDENTE_REPORTADO`: Quando um incidente é reportado na rota
- `ALERTA_INCIDENTE`: Quando um motorista deve ser alertado sobre incidente
- `STATUS_VEICULO_ALTERADO`: Quando o status de disponibilidade de um veículo é alterado

### API REST
- `GET /api/notificacoes/destinatario/{id}`: Retorna todas as notificações de um destinatário
- `GET /api/notificacoes/destinatario/{id}/nao-lidas/contagem`: Conta notificações não lidas
- `PATCH /api/notificacoes/{id}/marcar-lida`: Marca uma notificação como lida

## Possíveis Erros

| Código | Descrição | Causa Provável |
| ------ | --------- | -------------- |
| 400 | ID do destinatário inválido | ID menor ou igual a zero |
| 400 | ID da notificação inválido | ID menor ou igual a zero |
| 404 | Notificação não encontrada | ID não existe no banco |
| 500 | Erro interno do servidor | Falha ao processar evento ou ao acessar o banco |

## Limitações e Funcionalidades Pendentes

### Notificação de Chegada Iminente
A funcionalidade de notificar clientes sobre a chegada iminente de seu pedido **não está implementada**. Esta funcionalidade é mencionada nos requisitos do projeto, mas ainda não foi desenvolvida.

### Envio de Notificações
Atualmente, o serviço **não envia notificações** para os dispositivos dos usuários finais. Conforme indicado no comentário TODO no `NotificacaoServiceImpl`, a implementação atual apenas:
1. Processa eventos do sistema
2. Identifica destinatários relevantes
3. Gera o conteúdo da notificação
4. **Salva a notificação no banco de dados**

As seguintes implementações estão pendentes:
- Verificação das preferências de notificação do cliente
- Integração com provedores de envio de notificações (como FCM)
- Envio efetivo de notificações para dispositivos móveis ou navegadores

## Integração com Outros Serviços

O Serviço de Notificações integra-se com:
- **RabbitMQ**: Consumindo eventos da fila `notificacoes.geral`
- **Serviço de Pedidos**: Recebendo eventos relacionados a pedidos
- **Serviço de Rastreamento**: Recebendo eventos de localização e incidentes

## Modelo de Dados

O modelo `Notificacao` armazena:
- `destinatarioId`: ID do cliente ou motorista destinatário
- `tipoEvento`: Tipo do evento que gerou a notificação
- `titulo`: Título resumido da notificação
- `mensagem`: Conteúdo detalhado
- `dadosEvento`: JSON com dados completos do evento (tipo JSONB)
- `status`: Status da notificação (LIDA ou NAO_LIDA)
- `dataCriacao`: Data de criação da notificação
- `dataLeitura`: Data em que a notificação foi lida
