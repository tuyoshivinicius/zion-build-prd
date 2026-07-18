# PRD — Painel de Tarefas

## 1. Visão
Para a gerente de projetos, que perde tempo consolidando status, o Painel reúne o andamento das tarefas numa tela só.

## 2. Objetivos & métricas
- Reduzir o tempo de consolidação de status de 60 para 10 minutos por semana.

## 3. Personas
1. Gerente de projetos — acompanha o time.

## 4. Escopo (in / out)
- **Faz (in):** ver e atualizar o status das tarefas.
- **Não faz (out):** controle de horas e faturamento.

## 5. Regras de negócio (RN-xx)
- RN-01 Uma tarefa pertence a exatamente um responsável.

## 6. Requisitos funcionais por épico (RF-xx)
- **Épico E1 — Acompanhamento:** RF-01 a gerente vê o status agregado do time; RF-02 a gerente filtra por responsável.
- **Épico E2 — Atualização:** RF-03 o responsável marca uma tarefa como concluída.

## 7. NFRs (com números)
- A tela carrega em até 2 segundos com 500 tarefas.
- Disponibilidade de 99,9% ao mês.

## 8. Restrições (das ADRs)
- Ver docs/adr/ADR-001 para a decisão de arquitetura.

## 9. Glossário
- Tarefa: unidade de trabalho atribuída a um responsável.

## 10. Riscos
- Adoção baixa se a atualização for trabalhosa; mitigar com fluxo de um clique.

## 11. Questões abertas
- [NEEDS CLARIFICATION] limite de tarefas por projeto.

## 12. Rastreabilidade
| RF | Épico | Spec |
|----|-------|-------|
| RF-01 | E1 | R0 |
