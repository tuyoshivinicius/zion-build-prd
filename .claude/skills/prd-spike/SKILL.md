---
name: prd-spike
description: Estágio 2 do harness — pesquisa trade-offs das decisões estruturantes e registra ADRs antes da PRD
argument-hint: "As 2–3 decisões estruturantes que mudam a PRD inteira"
metadata:
  author: zion-mermaid-editor
user-invocable: true
disable-model-invocation: false
---

# prd-spike — Estágio 2 do harness (Spikes técnicos + ADRs)

Orquestra o Passo 2 do guia `docs/guia-prd-para-spec-kit.md`. Contrato de 5 fases; gates aconselham.
Regras em `.specify/prd/quality-rules.md`.

## Fase 0 — Pré-requisito (aconselha)
`docs/discovery.md` deve existir. Se não existir, avise: "recomendo rodar `/prd-discovery` antes" e
pergunte se segue mesmo assim. Não bloqueie.

## Fase 1 — Validar entrada bruta (aconselha)
O usuário deve nomear **2–3 decisões estruturantes** — as que mudam a PRD inteira, não dúvidas
menores. Para cada candidata, aplique o filtro: "isso muda a PRD inteira?". Se surgir uma lista longa
de dúvidas pequenas, sugira consolidar nas 2–3 realmente estruturantes.

## Fase 2/3 — Formatar e auto-delegar
Para cada decisão, no mesmo turno:
1. Invoque `deep-research` para levantar os trade-offs das opções (custo de manutenção, limites).
2. Invoque `adr-new` com o título da decisão para registrar o ADR em `docs/adr/`.

## Fase 4 — Validar saída (aconselha)
Confira contra o critério **spike** de `quality-rules.md` `#criterios-de-conclusao`: cada decisão tem
um `docs/adr/ADR-00x-*.md` com Contexto/Decisão/Consequências, e o ADR referencia um spike real. Se
um ADR não menciona um spike de fato rodado, avise: "sem spike, a spec nasce ambígua — sugiro rodar o
spike antes de aceitar a ADR". Não bloqueie.

## Saída
`docs/adr/ADR-00x-*.md` por decisão. Cada ADR aceito vira **restrição** na PRD (seção 8) e alimenta a
`constitution` do Spec Kit.
