---
name: prd-spike
description: Estágio 2 do harness — pesquisa trade-offs das decisões estruturantes e registra ADRs antes da PRD
argument-hint: "Opcional: as 2–3 decisões estruturantes, se você já as conhece"
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

## Fase 1 — Levantar e validar as decisões estruturantes (aconselha)
As **2–3 decisões estruturantes** são as que mudam a PRD inteira, não dúvidas menores. Detecte a
origem pelo que o usuário trouxe no argumento e aplique a cada candidata — dada ou proposta — o
filtro "isso muda a PRD inteira?"; candidata que não passa, descarte ou consolide.

- **Caminho A — 2–3 decisões dadas:** não proponha; valide cada uma pelo filtro. Lista longa de
  dúvidas pequenas → sugira consolidar nas 2–3 realmente estruturantes.
- **Caminho C — 1–2 decisões dadas (híbrido):** trate as dadas como fixas e proponha **só as
  faltantes** até fechar 2–3, cada complemento ancorado num trecho de `docs/discovery.md`.
- **Caminho B — 0 decisões dadas:** proponha as 2–3, cada uma ancorada num trecho do discovery.

**Guarda de suficiência (só em B/C, antes de propor).** O discovery tem três peças: visão em 1
frase, persona nomeada, quadro Faz/Não faz. Se uma peça necessária faltar ou for vaga (ex.: sem o
quadro Faz/Não faz não há como isolar uma fronteira de integração), **não fabrique** candidatas para
preencher a cota: aponte qual peça falta e por quê ela trava a inferência, proponha só o que o texto
sustenta, e peça a peça faltante ou sugira rodar `/prd-discovery`. Não bloqueie.

**Apresentação (B/C).** Entregue as 2–3 (ou só o complemento faltante) como recomendação direta e
enxuta, cada uma com uma linha de justificativa ancorada no discovery. Sem shortlist longa.

**Convergência (todos os caminhos, aconselha).** Peça ao usuário para **confirmar**, **editar**
(trocar uma) ou **substituir** (rejeitar todas e ditar as suas). Lista fraca — nenhuma passa no
filtro, virou 4 dúvidas menores, ou ficou com 1 decisão só → aponte e sugira, mas a lista confirmada
pelo usuário é a que vale. Não bloqueie.

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
