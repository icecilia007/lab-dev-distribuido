# Mapeamento do Microsserviço de Rastreamento

O microsserviço de Rastreamento é uma peça central do sistema logístico, responsável por monitorar a localização de veículos, calcular rotas, gerenciar incidentes e fornecer dados em tempo real para clientes e operadores. Abaixo está um detalhamento completo de suas funcionalidades:

## Funcionalidades de Negócio

### 1. Rastreamento em Tempo Real

**Principais funcionalidades:**
- Atualização periódica da posição dos veículos (a cada 2 minutos)
- Monitoramento do status dos veículos (DISPONÍVEL, PARADO, EM_MOVIMENTO)
- Cálculo de distâncias e tempos estimados de chegada
- Notificações em tempo real via gRPC e WebSockets

**Endpoints:**
- `POST /api/rastreamento/localizacao` - Atualiza localização do veículo
- `GET /api/rastreamento/pedido/{pedidoId}` - Consulta localização atual
- `GET /api/rastreamento/historico/{pedidoId}` - Obtém histórico de localizações

### 2. Gerenciamento de Incidentes

**Principais funcionalidades:**
- Reporte de problemas nas rotas (obras, bloqueios, acidentes)
- Notificação automática de motoristas próximos ao incidente
- Expiração automática de incidentes após período configurado
- Busca geoespacial de incidentes próximos

**Endpoints:**
- `POST /api/incidentes` - Reporta um novo incidente
- `GET /api/incidentes` - Lista incidentes ativos
- `GET /api/incidentes/proximos` - Busca incidentes próximos
- `PATCH /api/incidentes/{id}/desativar` - Marca incidente como resolvido

### 3. Confirmação de Operações Logísticas

**Principais funcionalidades:**
- Confirmação de coleta com validação de proximidade
- Confirmação de entrega com validação de proximidade
- Atualização automática de status do pedido
- Transição do veículo entre estados operacionais

**Endpoints:**
- `POST /api/rastreamento/pedido/{pedidoId}/coleta` - Confirma coleta
- `POST /api/rastreamento/pedido/{pedidoId}/entrega` - Confirma entrega

### 4. Análise e Estatísticas

**Principais funcionalidades:**
- Relatórios de produtividade por motorista
- Cálculo de distâncias percorridas e tempos em movimento
- Métricas de eficiência e desempenho
- Histórico detalhado de operações

**Endpoints:**
- `GET /api/rastreamento/estatisticas/motorista/{motoristaId}` - Estatísticas por motorista

### 5. Atribuição Inteligente de Motoristas

**Principais funcionalidades:**
- Localização de motoristas disponíveis próximos a um ponto
- Cálculo de distância entre motoristas e pontos de coleta
- Suporte à atribuição automática de pedidos

**Endpoints:**
- `GET /api/rastreamento/motoristas/proximos` - Busca motoristas disponíveis

## Integração com Outros Microsserviços

### Integração com Microsserviço de Pedidos

O sistema se integra com o microsserviço de Pedidos de várias formas:

1. **Consulta de dados do pedido:**
    - Busca coordenadas de origem e destino
    - Obtém informações sobre tempos estimados e distâncias

2. **Atualização de status:**
    - Atualiza o status do pedido com base na localização
    - Confirma coletas e entregas

3. **Suporte à atribuição:**
    - Fornece lista de motoristas próximos para novos pedidos
    - Calcula rotas desde o motorista até o ponto de coleta

### Integração com Microsserviço de Usuários

Realiza comunicação com o microsserviço de Usuários para:

1. **Verificação de dados:**
    - Valida a existência de motoristas e clientes
    - Busca informações de contato para notificações

2. **Atribuições e permissões:**
    - Verifica permissões para reportar incidentes
    - Valida autorização para acessar estatísticas

## Comunicação em Tempo Real

### Implementação gRPC

O microsserviço utiliza gRPC para comunicação bidirecional eficiente:

- `AtualizarLocalizacao` - Atualiza a posição do veículo
- `ConsultarLocalizacao` - Busca localização pontual
- `MonitorarLocalizacao` - Stream para atualizações contínuas
- `BuscarEntregasProximas` - Localiza entregas em um raio

### Sistema de Mensageria (RabbitMQ)

Utiliza RabbitMQ para comunicação assíncrona:

- Publicação de eventos de incidentes
- Notificação sobre mudanças de status
- Alertas para motoristas próximos a problemas

## Exemplos de Navegação no Aplicativo

### Aplicativo do Cliente

1. **Acompanhamento de Pedido:**
   ```
   Tela Principal > Meus Pedidos > [Selecionar Pedido] > Acompanhar
   ```
    - Visualiza mapa com localização atual do motorista
    - Vê tempo estimado de chegada atualizado a cada 2 minutos
    - Recebe notificações sobre mudanças de status

2. **Histórico de Entregas:**
   ```
   Tela Principal > Histórico > [Selecionar Pedido] > Detalhes da Rota
   ```
    - Visualiza o percurso completo realizado pelo motorista
    - Acessa pontos de parada e tempos de espera
    - Vê métricas como distância total e tempo de entrega

### Aplicativo do Motorista

1. **Navegação até a Coleta:**
   ```
   Tela Principal > Pedidos Disponíveis > [Aceitar Pedido] > Iniciar Rota
   ```
    - Recebe rota otimizada até o ponto de coleta
    - Envia atualizações de localização automaticamente
    - App habilita botão "Confirmar Coleta" quando próximo

2. **Reporte de Incidentes:**
   ```
   Tela Principal > [Menu] > Reportar Problema
   ```
    - Seleciona tipo de incidente (ACIDENTE, OBRA, BLOQUEIO)
    - Define raio de impacto (padrão: 5km)
    - Sistema notifica automaticamente outros motoristas na área

3. **Visualização de Alertas:**
   ```
   [Notificação Push] > Detalhes do Alerta > Ver no Mapa
   ```
    - Recebe alertas sobre incidentes próximos
    - Visualiza incidentes no mapa com informações detalhadas
    - Pode marcar incidentes como resolvidos

### Painel do Operador Logístico

1. **Monitoramento de Frota:**
   ```
   Dashboard > Monitoramento em Tempo Real > Mapa de Veículos
   ```
    - Visualiza posição atual de todos os veículos
    - Acompanha status (DISPONÍVEL, EM_MOVIMENTO, PARADO)
    - Identifica atrasos e problemas em tempo real

2. **Análise de Desempenho:**
   ```
   Dashboard > Relatórios > Desempenho de Motoristas
   ```
    - Gera estatísticas por motorista, região ou período
    - Compara métricas como tempo médio por entrega
    - Identifica oportunidades de otimização

## Rotas Disponíveis (API REST)

### Rastreamento
- `POST /api/rastreamento/localizacao` - Atualiza localização
- `GET /api/rastreamento/pedido/{pedidoId}` - Consulta localização atual
- `GET /api/rastreamento/historico/{pedidoId}` - Histórico de localizações
- `GET /api/rastreamento/proximas` - Busca entregas próximas
- `GET /api/rastreamento/estatisticas/motorista/{motoristaId}` - Estatísticas
- `POST /api/rastreamento/pedido/{pedidoId}/coleta` - Confirma coleta
- `POST /api/rastreamento/pedido/{pedidoId}/entrega` - Confirma entrega
- `GET /api/rastreamento/motoristas/proximos` - Busca motoristas próximos

### Incidentes
- `POST /api/incidentes` - Reporta incidente
- `GET /api/incidentes` - Lista incidentes ativos
- `GET /api/incidentes/proximos` - Busca incidentes próximos
- `GET /api/incidentes/{id}` - Detalhes do incidente
- `PATCH /api/incidentes/{id}/desativar` - Desativa incidente

Esta implementação atende aos requisitos do documento fornecido, possibilitando o rastreamento em tempo real, alertas de incidentes e geração de relatórios de produtividade, beneficiando clientes, motoristas e operadores logísticos.