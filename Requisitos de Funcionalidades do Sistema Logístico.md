<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" class="logo" width="120"/>

# Requisitos de Funcionalidades do Sistema Logístico

## Gestão de Usuários e Perfis

**Autenticação e Autorização**

- O sistema deve permitir login de usuários com diferentes perfis (cliente, motorista, operador logístico)
- Cada perfil deve ter acesso apenas às funcionalidades pertinentes à sua função


## Funcionalidades para Clientes

**Rastreamento de Encomendas**

- O sistema deve exibir a localização em tempo real das encomendas com atualização a cada 2 minutos[^3]
- Deve ser possível visualizar o trajeto da encomenda em um mapa interativo

**Notificações**

- Clientes devem poder configurar suas preferências de notificação (e-mail ou push)[^4]
- O sistema deve enviar alertas sobre mudanças de status das encomendas

**Histórico**

- O sistema deve manter registro de todos os pedidos anteriores do cliente
- Deve ser possível consultar detalhes completos de cada pedido realizado


## Funcionalidades para Motoristas

**Gerenciamento de Rotas**

- O sistema deve calcular rotas otimizadas utilizando OSRM
- Motoristas devem visualizar sua programação diária de entregas

**Sistema de Alerta de Incidentes**

- Motoristas devem poder reportar incidentes em tempo real (bloqueios, acidentes, obras)[^3]
- O sistema deve categorizar os incidentes reportados por tipo e severidade
- Os incidentes reportados devem ter validade temporal definida

**Notificação de Incidentes Próximos**

- O sistema deve identificar automaticamente motoristas que estão na mesma rota ou num raio de 5km de um incidente reportado
- Motoristas próximos devem receber alertas sobre incidentes em tempo real[^4]
- Os alertas devem informar a natureza do incidente e sua localização

**Histórico e Métricas**

- Motoristas devem ter acesso ao seu histórico completo de entregas
- O sistema deve calcular e exibir métricas de desempenho individual


## Funcionalidades para Operadores Logísticos

**Monitoramento de Operações**

- O sistema deve gerar relatórios de produtividade por veículo (km rodados × entregas concluídas)[^4]
- Operadores devem poder monitorar o consumo de combustível em tempo real por rota

**Gestão de Incidentes**

- O sistema deve exibir todos os incidentes ativos no mapa de operações
- Operadores devem poder validar ou remover incidentes reportados pelos motoristas
- O sistema deve gerar análises sobre áreas com maior incidência de problemas


## Infraestrutura Tecnológica

**Armazenamento de Dados**

- Utilizar PostgreSQL para armazenar informações sobre usuários, encomendas, rotas e incidentes[^7]
- Implementar índices espaciais para consultas geográficas eficientes

**Comunicação em Tempo Real**

- Utilizar RabbitMQ como sistema de mensageria para notificações assíncronas[^7]
- Implementar filas específicas para diferentes tipos de alertas e notificações

**Integração com Serviços Externos**

- Integrar com OSRM para cálculo e otimização de rotas
- Implementar APIs para envio de notificações por e-mail e push


