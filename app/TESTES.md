# Casos de Teste para o Aplicativo Móvel - Sistema Logístico

Os casos de teste a seguir cobrem os principais fluxos de interação com o aplicativo móvel, incluindo a criação de pedidos, rastreamento, entrega e situações excepcionais como cancelamentos e incidentes. Cada caso de teste foi elaborado para verificar as funcionalidades e integrações entre o aplicativo móvel e o backend.

## Pré-requisitos para Execução dos Testes

- Emulador Android configurado no IntelliJ IDEA
- JDK 21
- Flutter versão 3.13.6
- Dart versão 3.3.4
- Todos os microsserviços em execução:
    - API Gateway rodando
    - Serviço de Usuários rodando
    - Serviço de Pedidos rodando
    - Serviço de Rastreamento rodando
    - Serviço de Notificações rodando
- RabbitMQ em execução
- Banco de dados PostgreSQL em execução

## Caso de Teste 1: Cadastro e Login de Cliente

### Passos:

1. **Abrir o aplicativo**
    - Verificar: Tela de login é exibida com os campos "Email" e "Senha"

2. **Clicar no link "Registre-se aqui"**
    - Verificar: Tela de registro é exibida com opções para selecionar o tipo de usuário

3. **Selecionar a opção "Cliente"**
    - Verificar: Formulário de registro específico para cliente é exibido

4. **Preencher os campos do formulário de cadastro de cliente:**
    - Nome: "João Silva"
    - Email: "joao.cliente@exemplo.com"
    - Telefone: "11999998888"
    - Senha: "Senha123@"
    - Confirmar Senha: "Senha123@"
    - Clicar em "REGISTRAR"
    - Verificar: Mensagem de sucesso é exibida e usuário é redirecionado para a tela de login

5. **Realizar login com as credenciais cadastradas:**
    - Email: "joao.cliente@exemplo.com"
    - Senha: "Senha123@"
    - Clicar em "ENTRAR"
    - Verificar: Login é bem-sucedido e a tela principal do cliente é exibida com os elementos:
        - Dashboard com opção para criar novo pedido
        - Menu inferior com opções de Dashboard, Histórico e Configurações
        - Nome do usuário "João Silva" exibido no topo da tela

6. **Fazer logout:**
    - Clicar no ícone de sair no canto superior direito
    - Verificar: Usuário é desconectado e redirecionado para a tela de login

## Caso de Teste 2: Cadastro e Login de Motorista

### Passos:

1. **Abrir o aplicativo**
    - Verificar: Tela de login é exibida com os campos "Email" e "Senha"

2. **Clicar no link "Registre-se aqui"**
    - Verificar: Tela de registro é exibida com opções para selecionar o tipo de usuário

3. **Selecionar a opção "Motorista"**
    - Verificar: Formulário de registro específico para motorista é exibido

4. **Preencher os campos do formulário de cadastro de motorista:**
    - Nome: "Pedro Motorista"
    - Email: "pedro.motorista@exemplo.com"
    - Telefone: "11988887777"
    - Senha: "Senha456@"
    - Confirmar Senha: "Senha456@"
    - Placa do Veículo: "ABC1234"
    - Modelo do Veículo: "Fiat Strada"
    - Ano do Veículo: "2022"
    - Consumo Médio por Km: "12.5"
    - Clicar em "REGISTRAR"
    - Verificar: Mensagem de sucesso é exibida e usuário é redirecionado para a tela de login

5. **Realizar login com as credenciais cadastradas:**
    - Email: "pedro.motorista@exemplo.com"
    - Senha: "Senha456@"
    - Clicar em "ENTRAR"
    - Verificar: Login é bem-sucedido e a tela principal do motorista é exibida com os elementos:
        - Lista de entregas disponíveis
        - Indicador de status atual (Disponível, Em Movimento ou Parado)
        - Menu inferior com opções de Entregas e Configurações
        - Nome do usuário "Pedro Motorista" exibido no topo da tela

6. **Fazer logout:**
    - Clicar no ícone de sair no canto superior direito
    - Verificar: Usuário é desconectado e redirecionado para a tela de login

## Caso de Teste 3: Cadastro e Login de Operador

### Passos:

1. **Abrir o aplicativo**
    - Verificar: Tela de login é exibida com os campos "Email" e "Senha"

2. **Clicar no link "Registre-se aqui"**
    - Verificar: Tela de registro é exibida com opções para selecionar o tipo de usuário

3. **Selecionar a opção "Operador"**
    - Verificar: Formulário de registro específico para operador logístico é exibido

4. **Preencher os campos do formulário de cadastro de operador:**
    - Nome: "Ana Operadora"
    - Email: "ana.operadora@exemplo.com"
    - Telefone: "11977776666"
    - Senha: "Senha789@"
    - Confirmar Senha: "Senha789@"
    - Código da Empresa: "LOG12345" (se aplicável)
    - Clicar em "REGISTRAR"
    - Verificar: Mensagem de sucesso é exibida e usuário é redirecionado para a tela de login

## Caso de Teste 4: Entrega Completa de um Pedido

### Pré-condições:
- Usuário cliente já cadastrado e logado no aplicativo
- Usuário motorista já cadastrado e logado em uma segunda instância do aplicativo

### Passos (Cliente):

1. **Criar novo pedido:**
    - Na tela principal, clicar no botão "Novo Pedido"
    - Selecionar ponto de origem no mapa ou marcar "Usar minha localização atual como origem"
    - Selecionar ponto de destino no mapa
    - Preencher campo "Tipo de Mercadoria" (ex: "Eletrônicos")
    - Clicar em "Criar Pedido"
    - Verificar: Mensagem de sucesso e pedido aparecendo na lista de "Pedidos Ativos" com status "EM_PROCESSAMENTO"

### Passos (Motorista):

2. **Aceitar o pedido:**
    - Visualizar a notificação de novo pedido disponível
    - Clicar na notificação ou acessar a lista de entregas disponíveis
    - Visualizar os detalhes do pedido
    - Clicar em "Aceitar Pedido"
    - Verificar: Pedido aparece na lista de entregas com status "AGUARDANDO_COLETA"

3. **Simular deslocamento até o ponto de coleta:**
    - Clicar no pedido aceito
    - Clicar em "Ver Rota"
    - Verificar: O mapa exibe a rota até o ponto de coleta
    - Verificar: Status do motorista como "EM_MOVIMENTO" ou "PARADO"
    - Verificar: Atualizações de localização são enviadas a cada 2 minutos

4. **Confirmar a coleta:**
    - Ao chegar no local, clicar em "Atualizar"
    - Selecionar "Coletar (com foto)"
    - Tirar foto da mercadoria
    - Verificar: Status do pedido muda para "EM_ROTA"

### Passos (Cliente):

5. **Verificar atualizações de rastreamento:**
    - Clicar no pedido ativo na lista
    - Clicar em "Rastrear"
    - Verificar: Mapa exibe a posição atual do motorista e a rota até o destino
    - Verificar: Informações de distância restante e tempo estimado estão visíveis

### Passos (Motorista):

6. **Simular deslocamento até o ponto de entrega:**
    - Continuar com status "EM_MOVIMENTO"
    - Verificar: Atualizações de localização continuam sendo enviadas
    - Verificar: Rota e marcadores no mapa estão corretos

7. **Confirmar entrega:**
    - Ao chegar no destino, clicar em "Atualizar"
    - Selecionar "Entregar (com foto)"
    - Tirar foto da entrega
    - Verificar: Mensagem de sucesso aparece
    - Verificar: Status do pedido muda para "ENTREGUE"

### Passos (Cliente):

8. **Verificar conclusão do pedido:**
    - Verificar: O pedido aparece como "ENTREGUE"
    - Verificar: O pedido é movido para o histórico de pedidos
    - Verificar: Cliente recebe notificação de entrega concluída

## Caso de Teste 5: Cancelamento de Pedido antes da Aceitação pelo Motorista

### Passos (Cliente):

1. **Criar novo pedido:**
    - Na tela principal, clicar no botão "Novo Pedido"
    - Selecionar ponto de origem no mapa
    - Selecionar ponto de destino no mapa
    - Preencher campo "Tipo de Mercadoria" (ex: "Documentos")
    - Clicar em "Criar Pedido"
    - Verificar: Mensagem de sucesso e pedido aparecendo na lista de "Pedidos Ativos" com status "EM_PROCESSAMENTO"

2. **Cancelar o pedido:**
    - Na lista de pedidos ativos, identificar o pedido recém-criado
    - Clicar no pedido para ver seus detalhes
    - Clicar no botão "Cancelar" no card do pedido
    - Confirmar o cancelamento na caixa de diálogo clicando em "Sim, Cancelar"
    - Verificar: Mensagem "Pedido cancelado com sucesso"
    - Verificar: O pedido é removido da lista de pedidos ativos
    - Verificar: O pedido aparece no histórico com status "CANCELADO"

### Passos (Motorista):

3. **Verificar que o pedido não está disponível para motoristas:**
    - Verificar que não é possível atender o pedido.

## Caso de Teste 6: Relatando Incidentes no Meio da Rota

### Pré-condições:
- Usuário cliente já cadastrado e logado no aplicativo
- Usuário motorista já cadastrado e logado em uma segunda instância do aplicativo

### Passos (Cliente):

1. **Criar novo pedido:**
    - Na tela principal, clicar no botão "Novo Pedido"
    - Selecionar ponto de origem no mapa ou marcar "Usar minha localização atual como origem"
    - Selecionar ponto de destino no mapa
    - Preencher campo "Tipo de Mercadoria" (ex: "Eletrônicos")
    - Clicar em "Criar Pedido"
    - Verificar: Mensagem de sucesso e pedido aparecendo na lista de "Pedidos Ativos" com status "EM_PROCESSAMENTO"

### Passos (Motorista):

2. **Aceitar o pedido:**
    - Visualizar a notificação de novo pedido disponível
    - Clicar na notificação ou acessar a lista de entregas disponíveis
    - Visualizar os detalhes do pedido
    - Clicar em "Aceitar Pedido"
    - Verificar: Pedido aparece na lista de entregas com status "AGUARDANDO_COLETA"

3. **Simular deslocamento até o ponto de coleta:**
    - Clicar no pedido aceito
    - Clicar em "Ver Rota"
    - Verificar: O mapa exibe a rota até o ponto de coleta
    - Verificar: Status do motorista como "EM_MOVIMENTO" ou "PARADO"
    - Verificar: Atualizações de localização são enviadas a cada 2 minutos

4. **Reportar incidente durante o trajeto:**
    - Com o pedido em status "EM_ROTA", clicar no pedido para acessar os detalhes
    - Clicar em "Atualizar"
    - Selecionar "Relatar Incidente"
    - Preencher os campos do formulário:
        - Tipo de incidente: "BLOQUEIO"
        - Descrição: "Via bloqueada por obras" (Exemplo)
        - Raio de impacto: "1.0" km
        - Duração estimada: "5" horas
    - Clicar em "Reportar"
    - Verificar: Mensagem "Incidente reportado com sucesso"

5. **Verificar registro do incidente:**
    - Verificar se o incidente aparece no mapa de rastreamento com o ícone apropriado
    - Verificar se outros motoristas próximos recebem notificação do incidente

### Passos (Cliente):

6. **Verificar atualizações de rastreamento:**
    - Clicar no pedido ativo na lista
    - Clicar em "Rastrear"
    - Verificar: O mapa exibe informações sobre o incidente (se aplicável)
    - Verificar: Cliente recebe notificação sobre possível atraso

### Passos (Motorista):

7. **Continuar a entrega após o incidente:**
    - Alterar status para "EM_MOVIMENTO" novamente
    - Completar a entrega conforme passos 6-7 do Caso de Teste 1
    - Verificar: Apesar do incidente, a entrega é concluída com sucesso
   
## Caso de Teste 7: Acesso às Estatísticas do Motorista

### Pré-condições:
- Usuário motorista já cadastrado e logado no aplicativo
- O motorista deve ter realizado pelo menos uma entrega para gerar estatísticas
- Recomenda-se executar o Caso de Teste 1 (Entrega Completa de um Pedido) antes deste teste

### Passos:

1. **Acessar a tela de configurações:**
    - No menu inferior, clicar na opção "Configurações"
    - Verificar: Tela de configurações é exibida

2. **Acessar estatísticas:**
    - Na seção "Desempenho", clicar em "Minhas Estatísticas"
    - Verificar: Tela de estatísticas do motorista é carregada com as seguintes informações:
        - Período selecionado (data inicial e data final)
        - Resumo com distância total percorrida
        - Tempo total em movimento
        - Velocidade média
        - Número de pedidos atendidos

3. **Alterar o período de visualização:**
    - Clicar em "Data Inicial" e selecionar uma data no calendário (por exemplo, primeiro dia do mês atual)
    - Clicar em "Data Final" e selecionar uma data no calendário (por exemplo, dia atual)
    - Verificar: As estatísticas são atualizadas automaticamente para refletir o novo período selecionado

4. **Verificar a distribuição de status:**
    - Visualizar o gráfico de "Distribuição de Status"
    - Verificar: O gráfico mostra a proporção de tempo em que o motorista esteve em cada status:
        - Em Movimento (azul)
        - Disponível (verde)
        - Parado (laranja)

5. **Verificar a lista de pedidos atendidos:**
    - Rolar até a seção "Pedidos Atendidos"
    - Verificar: Lista de pedidos atendidos no período selecionado é exibida com o número do pedido

6. **Voltar para a tela principal:**
    - Clicar no botão de voltar no canto superior esquerdo da tela
    - Verificar: Usuário retorna para a tela de configurações