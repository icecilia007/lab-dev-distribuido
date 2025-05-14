# Mapeamento do Microsserviço de Pedidos

Após analisar o código-fonte do microsserviço de pedidos, identifiquei as seguintes funcionalidades de negócio implementadas no sistema:

## Funcionalidades Principais do Microsserviço

### 1. Gestão do Ciclo de Vida do Pedido

O microsserviço gerencia todo o ciclo de vida de um pedido logístico, desde a criação até a entrega ou cancelamento, passando pelos seguintes estados:

- **CRIADO** - Pedido acabou de ser registrado no sistema
- **EM_PROCESSAMENTO** - Pedido está aguardando aceitação por um motorista (15 minutos máximo)
- **AGUARDANDO_COLETA** - Motorista aceitou o pedido e está a caminho do local de coleta
- **EM_ROTA** - Motorista coletou o pacote e está a caminho do destino
- **ENTREGUE** - Pedido foi entregue com sucesso
- **CANCELADO** - Pedido foi cancelado (por falta de motoristas ou outro motivo)

### 2. Roteamento e Otimização

- Integração com OSRM para cálculo de rotas otimizadas
- Cálculo automático de distância e tempo estimado de entrega
- Armazenamento de dados completos da rota para uso futuro

### 3. Atribuição Inteligente de Motoristas

- Localização automática de motoristas próximos à origem do pedido
- Notificação de motoristas disponíveis sobre novos pedidos
- Sistema de aceitação de pedidos pelos motoristas

### 4. Monitoramento e Rastreamento

- Integração com o microsserviço de rastreamento para acompanhamento em tempo real
- Atualização de status do pedido baseada na localização do motorista

### 5. Sistema de Notificações

- Notificações em tempo real via RabbitMQ
- Diferentes tipos de eventos: criação de pedido, mudança de status, cancelamento
- Notificações direcionadas para clientes e motoristas específicos

## Exemplos de Navegação no Aplicativo

### Fluxo do Cliente

1. **Criação de um novo pedido:**
    - Cliente abre o app e seleciona "Novo Pedido"
    - Informa endereços de origem e destino
    - Escolhe o tipo de mercadoria
    - Confirma o pedido
    - Recebe confirmação com detalhes da rota, distância e tempo estimado

2. **Acompanhamento do pedido:**
    - Cliente acessa "Meus Pedidos" e seleciona o pedido ativo
    - Visualiza o status atual (EM_PROCESSAMENTO, AGUARDANDO_COLETA, etc.)
    - Acompanha em tempo real a localização do motorista no mapa
    - Recebe notificações sobre mudanças de status

3. **Histórico de pedidos:**
    - Cliente acessa "Histórico" e visualiza todos os pedidos anteriores
    - Filtra por período ou status (entregues, cancelados)
    - Acessa detalhes completos de cada pedido realizado

### Fluxo do Motorista

1. **Recebimento de notificações de pedidos disponíveis:**
    - Motorista recebe alerta sobre novo pedido disponível próximo à sua localização
    - Visualiza detalhes do pedido (distância, origem, destino, tipo de mercadoria)
    - Aceita ou recusa o pedido

2. **Aceitação e coleta:**
    - Após aceitar, motorista recebe navegação até o ponto de coleta
    - Ao chegar, confirma a coleta do pacote
    - Status do pedido é atualizado para EM_ROTA

3. **Entrega:**
    - Motorista segue a rota otimizada até o destino
    - Ao chegar, confirma a entrega
    - Status do pedido é atualizado para ENTREGUE

4. **Gestão de entregas:**
    - Motorista visualiza lista de entregas do dia
    - Acessa métricas de desempenho (tempo médio, distância percorrida)

### Fluxo do Operador Logístico

1. **Monitoramento de pedidos:**
    - Operador visualiza todos os pedidos ativos no sistema
    - Filtra por status, região ou motorista
    - Identifica pedidos com atrasos ou problemas

2. **Gestão de atribuições:**
    - Operador pode atribuir manualmente motoristas a pedidos específicos
    - Monitora a eficiência da atribuição automática
    - Intervém em casos de problemas ou cancelamentos

3. **Relatórios e métricas:**
    - Acessa relatórios de produtividade por motorista
    - Visualiza estatísticas de tempo de entrega por região
    - Analisa padrões de demanda e otimiza recursos

## Integrações com Outros Microsserviços

- **Microsserviço de Usuários**: Verificação de clientes e motoristas
- **Microsserviço de Rastreamento**: Localização de motoristas e monitoramento em tempo real
- **Sistema de Mensageria (RabbitMQ)**: Comunicação assíncrona para notificações

Esta implementação atende aos requisitos do documento de especificação, fornecendo um sistema completo para gestão de pedidos logísticos com funcionalidades para todos os perfis de usuário do sistema.