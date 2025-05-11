# Casos de Teste para o Sistema Logístico

Os casos de teste a seguir cobrem o fluxo completo do sistema logístico, incluindo os microsserviços de usuários, pedidos e rastreamento. Cada caso de teste foi elaborado para verificar funcionalidades específicas e a integração entre os diversos componentes.

## Caso de Teste 1: Fluxo Feliz - Pedido Criado, Aceito e Entregue com Sucesso

### Pré-condições:
- Microsserviços de usuários, pedidos e rastreamento estão operacionais
- RabbitMQ está configurado e operacional
- Banco de dados inicializado

### Passos:

1. **Cadastrar um cliente:**
   ```http
   POST /api/usuarios/clientes
   {
     "nome": "João Silva",
     "email": "joao.silva@exemplo.com",
     "senha": "senha123",
     "telefone": "11999998888"
   }
   ```
    - Verificar: resposta 201 Created com detalhes do cliente e ID gerado (armazenar clienteId)

2. **Cadastrar um motorista:**
   ```http
   POST /api/usuarios/motoristas
   {
     "nome": "Pedro Motorista",
     "email": "pedro.motorista@exemplo.com",
     "senha": "senha456",
     "telefone": "11988887777",
     "placa": "ABC1234",
     "modeloVeiculo": "Fiat Strada",
     "anoVeiculo": 2022,
     "consumoMedioPorKm": 12.5
   }
   ```
    - Verificar: resposta 201 Created com detalhes do motorista e ID gerado (armazenar motoristaId)

3. **Criar uma localização inicial para o motorista** (para que seja encontrado pela busca de proximidade):
   ```http
   POST /api/rastreamento/localizacao
   {
     "motoristaId": {motoristaId},
     "pedidoId": null,
     "latitude": 52.516677,
     "longitude": 13.388763,
     "statusVeiculo": "DISPONIVEL"
   }
   ```
    - Verificar: resposta 200 OK com true

4. **Criar pedido** (usando coordenadas de Berlim, Alemanha):
   ```http
   POST /api/pedidos
   {
     "origemLatitude": 52.516677,
     "origemLongitude": 13.388763,
     "destinoLatitude": 52.520008,
     "destinoLongitude": 13.404954,
     "tipoMercadoria": "Eletrônicos",
     "clienteId": {clienteId}
   }
   ```
    - Verificar: resposta 201 Created com detalhes do pedido e status "EM_PROCESSAMENTO" (armazenar pedidoId)

5. **Motorista aceita o pedido:**
   ```http
   POST /api/pedidos/{pedidoId}/aceitar?motoristaId={motoristaId}&latitude=52.517000&longitude=13.389000
   ```
    - Verificar: resposta 200 OK e status alterado para "AGUARDANDO_COLETA"

6. **Simular motorista se deslocando até o ponto de coleta (enviar 3 atualizações de localização):**
   ```http
   POST /api/rastreamento/localizacao
   {
     "motoristaId": {motoristaId},
     "pedidoId": {pedidoId},
     "latitude": 52.516800,
     "longitude": 13.388900,
     "statusVeiculo": "EM_MOVIMENTO"
   }
   ```
    - Repetir com coordenadas se aproximando do ponto de coleta
    - Verificar: resposta 200 OK com true

7. **Consultar localização atual do pedido:**
   ```http
   GET /api/rastreamento/pedido/{pedidoId}
   ```
    - Verificar: resposta 200 OK com dados atualizados da localização

8. **Motorista confirma a coleta do pedido:**
   ```http
   POST /api/rastreamento/pedido/{pedidoId}/coleta?motoristaId={motoristaId}
   ```
    - Verificar: resposta 200 OK com true e consultar o respectivo id do pedido com status "EM_ROTA"

9. **Simular motorista se deslocando até o destino (enviar 3 atualizações de localização):**
   ```http
   POST /api/rastreamento/localizacao
   {
     "motoristaId": {motoristaId},
     "pedidoId": {pedidoId},
     "latitude": 52.518000,
     "longitude": 13.395000,
     "statusVeiculo": "EM_MOVIMENTO"
   }
   ```
    - Repetir com coordenadas se aproximando do ponto de destino
    - Verificar: resposta 200 OK com true

10. **Motorista confirma a entrega do pedido:**
    ```http
    POST /api/rastreamento/pedido/{pedidoId}/entrega?motoristaId={motoristaId}
    ```
    - Verificar: resposta 200 OK com true e pedido com status "ENTREGUE"

11. **Verificar status final do pedido:**
    ```http
    GET /api/pedidos/{pedidoId}
    ```
    - Verificar: resposta 200 OK com status "ENTREGUE"

12. **Consultar estatísticas do motorista:**
    ```http
    GET /api/rastreamento/estatisticas/motorista/{motoristaId}?dataInicio=2025-05-03&dataFim=2025-05-03
    ```
    - Verificar: resposta 200 OK com estatísticas (distanciaTotalKm, tempoEmMovimentoMinutos, etc.)

## Caso de Teste 2: Fluxo de Cancelamento por Falta de Motoristas

### Pré-condições:
- Microsserviços de usuários, pedidos e rastreamento estão operacionais
- Banco de dados inicializado
- Não há motoristas disponíveis na região (ou todos os motoristas têm status diferente de DISPONÍVEL)

### Passos:

1. **Cadastrar um cliente** (se necessário, usar o mesmo do teste anterior)

2. **Criar pedido em região sem motoristas próximos** (Lisboa, Portugal):
   ```http
   POST /api/pedidos
   {
     "origemLatitude": 38.736946,
     "origemLongitude": -9.142685,
     "destinoLatitude": 38.712825,
     "destinoLongitude": -9.140080,
     "tipoMercadoria": "Documentos",
     "clienteId": {clienteId}
   }
   ```
    - Verificar: resposta 201 Created com detalhes do pedido (armazenar pedidoId)

3. **Verificar status do pedido após alguns segundos:**
   ```http
   GET /api/pedidos/{pedidoId}
   ```
    - Verificar: resposta 200 OK com status "CANCELADO" e descrição indicando falta de motoristas disponíveis

4. **Alternativa: Aguardar o job que cancela pedidos sem aceite após 15 minutos**
    - Após 15 minutos, verificar se o status mudou para "CANCELADO"

## Caso de Teste 3: Reportando e Respondendo a Incidentes

### Pré-condições:
- Caso de Teste 1 executado com sucesso até o passo 8 (motorista em rota para entrega)
- Existe pelo menos outro motorista próximo cadastrado e disponível

### Passos:

1. **Motorista reporta um incidente na rota:**
   ```http
   POST /api/incidentes
   {
     "motoristaId": {motoristaId},
     "latitude": 52.518500,
     "longitude": 13.396000,
     "tipo": "BLOQUEIO",
     "descricao": "Rua bloqueada por obra",
     "raioImpactoKm": 1.0,
     "duracaoHoras": 5
   }
   ```
    - Verificar: resposta 201 Created com detalhes do incidente (armazenar incidenteId)

2. **Consultar incidentes próximos:**
   ```http
   GET /api/incidentes/proximos?latitude=52.518800&longitude=13.395500&raioKm=2.0
   ```
    - Verificar: resposta 200 OK contendo o incidente reportado na lista

3. **Verificar se a notificação foi enviada para o RabbitMQ** (verificar logs ou usar ferramenta de monitoramento do RabbitMQ)

4. **Desativar o incidente após resolução:**
   ```http
   PATCH /api/incidentes/{incidenteId}/desativar
   ```
    - Verificar: resposta 204 No Content

5. **Verificar se o incidente não aparece mais nas consultas:**
   ```http
   GET /api/incidentes/proximos?latitude=52.518800&longitude=13.395500&raioKm=2.0
   ```
    - Verificar: resposta 200 OK sem o incidente desativado

## Caso de Teste 4: Validações Geográficas na Coleta/Entrega

### Pré-condições:
- Caso de Teste 1 executado com sucesso até o passo 6 (motorista se deslocando para coleta)

### Passos:

1. **Tentar confirmar coleta estando longe do ponto de origem:**
   ```http
   POST /api/rastreamento/pedido/{pedidoId}/coleta?motoristaId={motoristaId}
   ```
    - Verificar: resposta 400 Bad Request com mensagem "Motorista deve estar próximo ao ponto de coleta"

2. **Enviar localização próxima ao ponto de coleta:**
   ```http
   POST /api/rastreamento/localizacao
   {
     "motoristaId": {motoristaId},
     "pedidoId": {pedidoId},
     "latitude": 52.516677,
     "longitude": 13.388763,
     "statusVeiculo": "PARADO"
   }
   ```
    - Verificar: resposta 200 OK com true

3. **Agora confirmar coleta estando no local correto:**
   ```http
   POST /api/rastreamento/pedido/{pedidoId}/coleta?motoristaId={motoristaId}
   ```
    - Verificar: resposta 200 OK com true e pedido com status "EM_ROTA"

4. **Tentar confirmar entrega estando longe do destino:**
   ```http
   POST /api/rastreamento/pedido/{pedidoId}/entrega?motoristaId={motoristaId}
   ```
    - Verificar: resposta 400 Bad Request com mensagem "Motorista deve estar próximo ao ponto de entrega"

5. **Enviar localização próxima ao ponto de entrega:**
   ```http
   POST /api/rastreamento/localizacao
   {
     "motoristaId": {motoristaId},
     "pedidoId": {pedidoId},
     "latitude": 52.520008,
     "longitude": 13.404954,
     "statusVeiculo": "PARADO"
   }
   ```
    - Verificar: resposta 200 OK com true

6. **Agora confirmar entrega estando no local correto:**
   ```http
   POST /api/rastreamento/pedido/{pedidoId}/entrega?motoristaId={motoristaId}
   ```
    - Verificar: resposta 200 OK com true e pedido com status "ENTREGUE"

## Observações para Execução dos Testes

1. **Coordenadas**: Como mencionado, o OSRM está com problemas para dados do Brasil. Use coordenadas europeias como as sugeridas nos testes (Berlim, Lisboa).

2. **Temporização**: Algumas operações podem exigir um intervalo entre elas, especialmente as atualizações de localização que simulam o deslocamento do motorista.

3. **Ordem de execução**: Execute os testes na ordem apresentada, já que alguns dependem do estado criado em testes anteriores.

4. **Monitoramento do RabbitMQ**: Para uma verificação completa, monitore o RabbitMQ para confirmar que as mensagens estão sendo publicadas corretamente nas filas.

Estes casos de teste permitem verificar o funcionamento completo do sistema logístico e a integração entre seus diversos microsserviços.
