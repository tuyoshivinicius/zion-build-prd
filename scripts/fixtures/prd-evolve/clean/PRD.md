# PRD — Painel de Tarefas

## 1. Visão
Para a gerente de projetos, que perde tempo consolidando status, o Painel reúne o andamento numa tela só.

## 2. Objetivos & métricas
- Reduzir o tempo de consolidação de 60 para 10 minutos por semana.

## 3. Personas
1. Gerente de projetos — acompanha o time.

## 4. Escopo (in / out)
- **Faz (in):** ver e atualizar o status das tarefas; exportar o quadro.
- **Não faz (out):** controle de horas e faturamento.

## 5. Regras de negócio (RN-xx)
- RN-01 Uma tarefa pertence a exatamente um responsável.

## 6. Requisitos funcionais por épico (RF-xx)
- **Épico E1 — Acompanhamento:** RF-01 a gerente vê o status agregado; RF-02 a gerente filtra por responsável.
- **Épico E2 — Atualização:** RF-03 o responsável marca uma tarefa como concluída; RF-04 o responsável exporta o quadro em vetor.

## 7. NFRs (com números)
- A tela carrega em até 2 segundos com 500 tarefas.
- Disponibilidade de 99,9% ao mês.

## 8. Restrições (das ADRs)
- Ver docs/adr/ADR-005 para a decisão de exportação.

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

## 13. Histórico de mudanças
| Data | Cenário | Mudança | Motivo | Artefatos afetados |
|------|---------|---------|--------|--------------------|
| 2026-08-02 | C3 | exportação passa a ser vetor | motor antigo não gerava vetor | ADR-002 → ADR-005 · restrição §8 atualizada |
| 2026-08-05 | C1 | RF-04 novo: exportar o quadro em vetor | pedido recorrente | RF-04 no épico E2 · spec nova |
