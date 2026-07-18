# PRD — Painel de Tarefas

## 1. Visão
Para a gerente de projetos, que perde tempo consolidando status, o Painel reúne o andamento das tarefas numa tela só.

## 4. Escopo (in / out)
- **Faz (in):** ver e atualizar o status das tarefas.
- **Não faz (out):** controle de horas e faturamento.

## 6. Requisitos funcionais por épico (RF-xx)
- **Épico E1 — Acompanhamento:** RF-01 a gerente vê o status agregado do time; RF-02 a gerente filtra por responsável.

### Critério de aceite do RF-01
Dado um projeto com 500 tarefas, quando a gerente abre o Painel, então vê uma barra de progresso verde
no topo da tela com o texto "X de Y concluídas" alinhado à direita, e logo abaixo a lista de tarefas
em duas colunas: título à esquerda, responsável à direita com o avatar circular.

## 7. NFRs (com números)
- A tela carrega em até 2 segundos com 500 tarefas.
- Disponibilidade de 99,9% ao mês.
