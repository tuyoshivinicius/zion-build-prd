# PRD — Painel de Tarefas

## 1. Visão
Para a gerente de projetos, que perde tempo consolidando status, o Painel reúne o andamento numa tela só.

## 4. Escopo (in / out)
- **Faz (in):** ver e atualizar o status das tarefas.
- **Não faz (out):** controle de horas.

## 6. Requisitos funcionais por épico (RF-xx)
- **Épico E1 — Acompanhamento:** RF-01 a gerente vê o status agregado; RF-02 a gerente filtra por responsável.
- **Épico E2 — Atualização:** RF-03 o responsável marca uma tarefa como concluída.

## 7. NFRs (com números)
- A tela carrega em até 2 segundos com 500 tarefas.

## 8. Restrições (das ADRs)
- Ver docs/adr/ADR-002 para a decisão de exportação.

## 12. Rastreabilidade
| RF | Épico | Fatia |
|----|-------|-------|
| RF-01 | E1 | R0 |

## 13. Histórico de mudanças
| Data | Cenário | Mudança | Motivo | Artefatos afetados |
|------|---------|---------|--------|--------------------|
| 2026-08-02 | C2 | RF-99 alterado: exportar em vetor | feedback | ADR-404 novo |
| 2026-08-05 | X | RF-03 alterado | ajuste | fatia S2 |
