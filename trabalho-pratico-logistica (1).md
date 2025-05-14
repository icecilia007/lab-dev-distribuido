# Especificação do Trabalho de Laboratório de Desenvolvimento de Aplicações Móveis e Distribuídas

## Definições gerais

- O trabalho deve ser desenvolvido em grupos de até 5 alunos.

- O trabalho deve ser entregue no Github Classroom.

- A avaliação será individual e levara em conta a contribuição do aluno para o projeto. A contribuição será avaliada como:
  - Criação obrigatório de _Issues_ e asstribuição da _issue_ ao aluno responsável (assignee).
  - Criação de commits para cada tarefa realizada (_atomic commit_) utilizando o padrão _Conventional Commits_ e referenciando obrigatoriamente a _Issue_ correspondente.
  - Documentação de todo o código criado.
  - Alunos que fizerem apenas um commit no final do prazo de entrega serão penalizados.

- Todos os alunos devem se envolver com atividades de desenvolvimento. A disciplina é de Desenvolvimento e não existe o cargo de "Documentador" ou "Tester" (QA).

- Atividades de desenvolvimento em nuvem devem ser documentadas de forma detalhada no repositório e os scripts de configuração devem ser exportados e submetidos ao Github, de forma que o projeto seja reprodutível.

## Situação-problema

Uma empresa de logística enfrenta desafios na gestão eficiente de suas entregas e no rastreamento em tempo real de seus veículos. Eles buscam uma solução tecnológica que permita aos clientes acompanhar suas encomendas, aos motoristas gerenciar suas rotas e à empresa otimizar suas operações logísticas.

**Necessidades técnicas específicas por usuário:**

| **Clientes** | **Motoristas** | **Operadores logísticos** |
| :-- | :-- | :-- |
| Visualizar geolocalização de encomendas (com atualização a cada 2 minutos) | Receber alertas sobre restrições de rota (ex: obras ou bloqueios) | Gerar relatórios de produtividade por veículo (km rodado × entregas concluídas) |
| Configurar preferências de notificação (e-mail ou push) | Acessar histórico de entregas com métricas de desempenho | Simular cenários de distribuição com variáveis climáticas e de demanda |
| Visualizar histórico de pedidos | Reportar incidentes em tempo real (avarias, acidentes) | Monitorar consumo de combustível em tempo real por rota |

---

## Partes do trabalho

O trabalho é dividido em 3 partes:

1. [Desenvolvimento Móvel (20 pontos)](./trabalho-pratico-1-mobile.md)
2. [Desenvolvimento de Microsserviços (30 pontos)](./trabalho-pratico-2-microsservicos.md)
3. [Desenvolvimento em Nuvem (40 pontos)](./trabalho-pratico-3-nuvem.md)
